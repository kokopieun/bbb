#!/bin/bash

# Setup variables
USERNAME=$(jq -r '.inputs.username' $GITHUB_EVENT_PATH)
PASSWORD=$(jq -r '.inputs.password' $GITHUB_EVENT_PATH)
COMPUTERNAME=$(jq -r '.inputs.computername' $GITHUB_EVENT_PATH)
AUTHKEY=$(jq -r '.inputs.tailscale_authkey' $GITHUB_EVENT_PATH)

echo "🚀 Setting up PHP Web Server..."

# Create user
sudo useradd -m -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | sudo chpasswd
sudo usermod -aG sudo $USERNAME

# Set hostname
sudo hostname $COMPUTERNAME

# Install LAMP Stack
sudo apt-get update
sudo apt-get install -y apache2 php libapache2-mod-php php-mysql curl

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to Tailscale
sudo tailscale up --authkey $AUTHKEY --hostname $COMPUTERNAME

# Create sample PHP page
sudo tee /var/www/html/index.php > /dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>GitHub + Tailscale PHP Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 10px; }
    </style>
</head>
<body>
    <h1>🎉 PHP Server is Running!</h1>
    <div class="info">
        <h3>Server Information:</h3>
        <p><strong>Hostname:</strong> <?php echo gethostname(); ?></p>
        <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
        <p><strong>Server IP:</strong> <?php echo $_SERVER['SERVER_ADDR']; ?></p>
        <p><strong>Client IP:</strong> <?php echo $_SERVER['REMOTE_ADDR']; ?></p>
        <p><strong>Time:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
    </div>
    
    <h3>Try these examples:</h3>
    <ul>
        <li><a href="info.php">PHP Info</a></li>
        <li><a href="status.php">Server Status</a></li>
    </ul>
</body>
</html>
EOF

# PHP Info page
sudo tee /var/www/html/info.php > /dev/null <<'EOF'
<?php phpinfo(); ?>
EOF

# Status page
sudo tee /var/www/html/status.php > /dev/null <<'EOF'
<?php
echo "<h1>Server Status</h1>";
echo "<pre>";
echo "Uptime: " . shell_exec('uptime') . "\n";
echo "Memory: " . shell_exec('free -h') . "\n";
echo "Disk: " . shell_exec('df -h') . "\n";
echo "</pre>";
?>
EOF

# Set proper permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Start Apache
sudo systemctl enable apache2
sudo systemctl start apache2

# Get Tailscale IP
sleep 5
TAILSCALE_IP=$(tailscale ip -4)

echo "✅ PHP Web Server Ready!"
echo "🌐 Access via: http://$TAILSCALE_IP/"
echo "📁 PHP Info: http://$TAILSCALE_IP/info.php"
echo "📊 Status: http://$TAILSCALE_IP/status.php"
