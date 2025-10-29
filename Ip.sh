#!/bin/bash

TAILSCALE_IP=$(tailscale ip -4)

if [[ -n "$TAILSCALE_IP" ]]; then
    echo "🌐 WEB SERVER READY!"
    echo "========================"
    echo "Main Site: http://$TAILSCALE_IP/"
    echo "PHP Info: http://$TAILSCALE_IP/info.php"
    echo "Server Status: http://$TAILSCALE_IP/status.php"
    echo ""
    echo "SSH Access:"
    echo "ssh $(jq -r '.inputs.username' $GITHUB_EVENT_PATH)@$TAILSCALE_IP"
    echo "========================"
else
    echo "❌ Tailscale not connected"
    exit 1
fi
