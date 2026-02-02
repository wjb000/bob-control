#!/bin/bash
# Find ESP32 on network

echo "🔍 Scanning for ESP32 devices..."
echo ""

# Check camera ESP
echo "Testing Camera ESP (192.168.1.222)..."
curl -s --connect-timeout 2 http://192.168.1.222/ > /dev/null && echo "✅ Camera ESP found!" || echo "❌ Not found"

echo ""
echo "Scanning common ESP32 IPs..."
for i in {1..254}; do
    IP="192.168.1.$i"
    # Quick check if responsive
    timeout 0.5 bash -c "echo > /dev/tcp/$IP/80" 2>/dev/null && echo "Found device at: $IP"
done

echo ""
echo "💡 TIP: Check your ESP32 serial monitor for its IP address"
echo "💡 Or access your router admin page to see connected devices"
