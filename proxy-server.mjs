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

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);

  try {
    switch (provider) {
      case 'openai': {
        const res = await fetch('https://api.openai.com/v1/chat/completions', {
          method: 'POST',
          signal: controller.signal,
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
        if (!data.choices?.[0]?.message?.content) {
          throw new Error('Unexpected response shape from OpenAI');
        }
        return data.choices[0].message.content;
      }
      case 'moonshot': {
        const res = await fetch('https://api.moonshot.cn/v1/chat/completions', {
          method: 'POST',
          signal: controller.signal,
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
        if (!data.choices?.[0]?.message?.content) {
          throw new Error('Unexpected response shape from Moonshot');
        }
        return data.choices[0].message.content;
      }
      case 'gemini': {
        const model = body.model || 'gemini-2.5-flash';
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

        // Transform OpenAI format to Gemini format
        // Preserve ALL system and user messages, strip unknown roles
        const systemMessages = body.messages?.filter(m => m.role === 'system') || [];
        const userMessages = body.messages?.filter(m => m.role === 'user') || [];
        const systemPrompt = systemMessages.map(m => m.content).join('\n');

        const geminiBody = {
          contents: userMessages.map(m => ({
            role: 'user',
            parts: [{ text: m.content }]
          })),
          ...(systemPrompt ? { systemInstruction: { parts: [{ text: systemPrompt }] } } : {}),
          generationConfig: {
            temperature: body.temperature ?? 0.8,
            maxOutputTokens: body.max_tokens ?? 300,
          }
        };

        const res = await fetch(url, {
          method: 'POST',
          signal: controller.signal,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: JSON.stringify(geminiBody),
        });
        if (!res.ok) {
          const err = await res.text();
          throw new Error(`Gemini error ${res.status}: ${err}`);
        }
        const data = await res.json();
        if (!data.candidates?.[0]?.content?.parts?.[0]?.text) {
          throw new Error('Unexpected response shape from Gemini');
        }
        return data.candidates[0].content.parts[0].text;
      }
      default:
        throw new Error(`Unknown provider: ${provider}`);
    }
  } finally {
    clearTimeout(timeout);
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
  let bodySize = 0;
  const MAX_BODY = 64 * 1024; // 64 KB
  req.on('data', chunk => {
    bodySize += chunk.length;
    if (bodySize > MAX_BODY) {
      sendJSON(res, 413, { error: 'Request body too large' });
      req.destroy();
      return;
    }
    rawBody += chunk;
  });
  req.on('end', async () => {
    if (res.writableEnded) return;
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
