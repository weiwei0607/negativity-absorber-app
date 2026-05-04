import http from 'http';

const PORT = process.env.PORT || 3000;

// Read API keys from environment variables
const API_KEYS = {
  openai: process.env.OPENAI_API_KEY,
  moonshot: process.env.MOONSHOT_API_KEY,
  gemini: process.env.GEMINI_API_KEY,
};

function setCORS(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

function sendJSON(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

async function proxyToProvider(provider, body) {
  const apiKey = API_KEYS[provider];
  if (!apiKey) throw new Error(`No API key configured for ${provider}. Set ${provider.toUpperCase()}_API_KEY environment variable.`);

  switch (provider) {
    case 'openai': {
      const res = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const err = await res.text();
        throw new Error(`OpenAI error ${res.status}: ${err}`);
      }
      const data = await res.json();
      return data.choices[0].message.content;
    }
    case 'moonshot': {
      const res = await fetch('https://api.moonshot.cn/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const err = await res.text();
        throw new Error(`Moonshot error ${res.status}: ${err}`);
      }
      const data = await res.json();
      return data.choices[0].message.content;
    }
    case 'gemini': {
      const model = body.model || 'gemini-2.5-flash';
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

      // Transform OpenAI format to Gemini format
      const systemPrompt = body.messages?.find(m => m.role === 'system')?.content || '';
      const userPrompt = body.messages?.find(m => m.role === 'user')?.content || '';

      const geminiBody = {
        contents: [{
          role: 'user',
          parts: [{ text: userPrompt }]
        }],
        systemInstruction: {
          parts: [{ text: systemPrompt }]
        },
        generationConfig: {
          temperature: body.temperature ?? 0.8,
          maxOutputTokens: body.max_tokens ?? 300,
        }
      };

      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(geminiBody),
      });
      if (!res.ok) {
        const err = await res.text();
        throw new Error(`Gemini error ${res.status}: ${err}`);
      }
      const data = await res.json();
      return data.candidates[0].content.parts[0].text;
    }
    default:
      throw new Error(`Unknown provider: ${provider}`);
  }
}

const server = http.createServer(async (req, res) => {
  setCORS(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method !== 'POST') {
    sendJSON(res, 405, { error: 'Method not allowed' });
    return;
  }

  let rawBody = '';
  req.on('data', chunk => rawBody += chunk);
  req.on('end', async () => {
    try {
      const body = JSON.parse(rawBody);
      const provider = body.provider;

      if (!provider) {
        sendJSON(res, 400, { error: 'Missing provider' });
        return;
      }

      const content = await proxyToProvider(provider, body);
      sendJSON(res, 200, { content });

    } catch (e) {
      console.error('Proxy error:', e);
      sendJSON(res, 500, { error: e.message });
    }
  });
});

server.listen(PORT, () => {
  console.log(`🚀 AI Proxy running on http://localhost:${PORT}`);
  const configured = Object.keys(API_KEYS).filter(k => API_KEYS[k]);
  console.log(`📡 Configured providers: ${configured.join(', ') || 'NONE — please set API keys in .env file'}`);
  console.log(`📖 POST /api/chat  ←  your Flutter app`);
  console.log(`   Body: { provider: "gemini", messages: [...], model: "...", temperature: 0.8, max_tokens: 300 }`);
});
