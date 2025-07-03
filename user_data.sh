#!/bin/bash

# Update system packages
dnf update -y

# Install required packages
dnf install -y curl wget

# Add Tailscale repository
curl -fsSL https://pkgs.tailscale.com/stable/amazon-linux/2/tailscale.repo | tee /etc/yum.repos.d/tailscale.repo

# Install Tailscale
dnf install -y tailscale

# Enable IP forwarding for subnet routing
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
sysctl -p

# Start and enable Tailscale service
systemctl enable --now tailscaled

# Wait for tailscaled to be ready
sleep 10

# Authenticate with Tailscale using the provided auth key
tailscale up --authkey="${tailscale_auth_key}" --accept-routes --advertise-exit-node

# Create a status check script
cat > /usr/local/bin/tailscale-status.sh << 'EOF'
#!/bin/bash
echo "=== Tailscale Status ==="
tailscale status
echo ""
echo "=== Tailscale IP ==="
tailscale ip -4
echo ""
echo "=== System IP Configuration ==="
ip addr show tailscale0 2>/dev/null || echo "Tailscale interface not found"
EOF

chmod +x /usr/local/bin/tailscale-status.sh

# Log installation completion
echo "Tailscale installation and configuration completed at $(date)" >> /var/log/tailscale-setup.log