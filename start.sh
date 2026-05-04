#!/bin/bash

cd "$(dirname "$0")"

# Load API keys from .env
set -a
source <(grep -v '^#' .env | sed -e 's/="/=/g' -e 's/"$//g')
set +a

echo "🚀 Starting AI Proxy Server..."
node proxy-server.mjs &
PROXY_PID=$!
sleep 2

# Verify proxy is running
if ! lsof -ti:3000 > /dev/null 2>&1; then
    echo "❌ Proxy failed to start. Check /tmp/proxy.log"
    exit 1
fi

echo "✅ Proxy running on http://localhost:3000"
echo ""
echo "🚀 Starting Flutter Dev Server..."
flutter run -d web-server --web-port 53421 &
FLUTTER_PID=$!
sleep 15

# Verify Flutter is running
if ! lsof -ti:53421 > /dev/null 2>&1; then
    echo "❌ Flutter failed to start. Check /tmp/flutter.log"
    exit 1
fi

echo "✅ Flutter running on http://localhost:53421"
echo ""
echo "=========================================="
echo "🎉 全部就緒！打開瀏覽器："
echo ""
echo "   http://localhost:53421"
echo ""
echo "📋 已預設設定："
echo "   • 代理：http://localhost:3000"
echo "   • AI：Gemini (gemini-2.5-flash)"
echo "   • 朋友名字：阿樹"
echo ""
echo "💬 直接點「聊天」頁籤開始對話，不用設定！"
echo "=========================================="
echo ""
echo "🛑 Press Ctrl+C to stop both servers"
echo ""

# Trap Ctrl+C
trap "echo ''; echo '🛑 Stopping servers...'; kill $PROXY_PID $FLUTTER_PID 2>/dev/null; exit" INT

wait
