#!/bin/bash

# Raspberry Pi Zero W 2 Space Invaders Installation Script
# This script automates the setup process for the portrait mode Space Invaders game

set -e  # Exit on any error

echo "=========================================="
echo "Raspberry Pi Space Invaders Setup Script"
echo "=========================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root. Run as the pi user."
    exit 1
fi

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "Installing Python and pygame dependencies..."
sudo apt install -y python3 python3-pip python3-pygame python3-dev python3-numpy

# Create game directory
echo "Creating game directory..."
mkdir -p ~/spaceinvaders
cd ~/spaceinvaders

# Check if game files exist
if [ ! -f "spaceinvaders_pi_portrait.py" ]; then
    echo "WARNING: spaceinvaders_pi_portrait.py not found in current directory!"
    echo "Please copy the following files to ~/spaceinvaders/:"
    echo "  - spaceinvaders_pi_portrait.py"
    echo "  - fonts/ directory"
    echo "  - images/ directory" 
    echo "  - sounds/ directory"
    echo "  - controller-keys.json"
    echo "  - leaderboard.json"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Make game executable
chmod +x spaceinvaders_pi_portrait.py

# Configure boot settings
echo "Configuring display and audio settings..."

# Backup original config
sudo cp /boot/config.txt /boot/config.txt.backup

# Check if our settings already exist
if ! grep -q "# Space Invaders Configuration" /boot/config.txt; then
    echo "Adding display and PWM audio configuration to /boot/config.txt..."
    sudo tee -a /boot/config.txt > /dev/null << 'EOF'

# Space Invaders Configuration
# Portrait mode display configuration
display_rotate=1
hdmi_group=2
hdmi_mode=82
hdmi_cvt=1080 1920 60 6 0 0 0

# PWM Audio configuration
dtoverlay=pwm,pin=18,func=2

# GPU memory split for better performance
gpu_mem=128
EOF
else
    echo "Configuration already exists in /boot/config.txt"
fi

# Configure audio
echo "Configuring PWM audio..."
sudo tee /etc/asound.conf > /dev/null << 'EOF'
pcm.!default {
    type hw
    card 0
    device 0
}
ctl.!default {
    type hw
    card 0
}
EOF

# Create performance optimization service
echo "Setting up performance optimization..."
sudo tee /etc/systemd/system/game-performance.service > /dev/null << 'EOF'
[Unit]
Description=Game Performance Optimization
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
ExecStart=/bin/bash -c 'echo 1000 > /proc/sys/vm/swappiness'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable game-performance.service

# Ask about auto-start
echo ""
read -p "Do you want the game to start automatically on boot? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Setting up auto-start service..."
    sudo tee /etc/systemd/system/spaceinvaders.service > /dev/null << EOF
[Unit]
Description=Space Invaders Game
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
WorkingDirectory=/home/pi/spaceinvaders
ExecStart=/usr/bin/python3 /home/pi/spaceinvaders/spaceinvaders_pi_portrait.py
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
EOF
    
    sudo systemctl enable spaceinvaders.service
    echo "Auto-start enabled. Game will start on boot after reboot."
fi

# Create test script
echo "Creating test script..."
tee ~/spaceinvaders/test_game.sh > /dev/null << 'EOF'
#!/bin/bash
echo "Testing Space Invaders setup..."

echo "1. Testing Python and pygame..."
python3 -c "import pygame; print('Pygame version:', pygame.version.ver)"

echo "2. Testing audio configuration..."
if command -v speaker-test &> /dev/null; then
    echo "Audio test available. Run 'speaker-test -t sine -f 1000 -c 1 -s 1' to test audio."
else
    echo "speaker-test not available. Install with: sudo apt install alsa-utils"
fi

echo "3. Testing display configuration..."
if command -v xrandr &> /dev/null; then
    echo "Current display resolution:"
    xrandr | grep "current"
else
    echo "xrandr not available (normal for headless setup)"
fi

echo "4. Testing game files..."
if [ -f "spaceinvaders_pi_portrait.py" ]; then
    echo "✓ Main game file found"
else
    echo "✗ Main game file missing"
fi

if [ -d "fonts" ]; then
    echo "✓ Fonts directory found"
else
    echo "✗ Fonts directory missing"
fi

if [ -d "images" ]; then
    echo "✓ Images directory found"
else
    echo "✗ Images directory missing"
fi

if [ -d "sounds" ]; then
    echo "✓ Sounds directory found"
else
    echo "✗ Sounds directory missing"
fi

echo ""
echo "To run the game manually: python3 spaceinvaders_pi_portrait.py"
echo "To test audio: speaker-test -t sine -f 1000 -c 1 -s 1"
EOF

chmod +x ~/spaceinvaders/test_game.sh

# Create uninstall script
echo "Creating uninstall script..."
tee ~/spaceinvaders/uninstall.sh > /dev/null << 'EOF'
#!/bin/bash
echo "Uninstalling Space Invaders..."

# Stop and disable services
sudo systemctl stop spaceinvaders.service 2>/dev/null || true
sudo systemctl disable spaceinvaders.service 2>/dev/null || true
sudo systemctl stop game-performance.service 2>/dev/null || true
sudo systemctl disable game-performance.service 2>/dev/null || true

# Remove service files
sudo rm -f /etc/systemd/system/spaceinvaders.service
sudo rm -f /etc/systemd/system/game-performance.service

# Restore original boot config
if [ -f /boot/config.txt.backup ]; then
    sudo cp /boot/config.txt.backup /boot/config.txt
    echo "Boot configuration restored"
fi

# Remove audio config
sudo rm -f /etc/asound.conf

# Reload systemd
sudo systemctl daemon-reload

echo "Uninstall complete. Reboot to restore original settings."
echo "Game files in ~/spaceinvaders remain - delete manually if desired."
EOF

chmod +x ~/spaceinvaders/uninstall.sh

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Connect your PWM audio circuit:"
echo "   GPIO 18 (Pin 12) → 1kΩ resistor → Audio out"
echo "   Audio ground ← 33nF capacitor ← Audio out"
echo "   Ground (Pin 6) ← Audio ground"
echo ""
echo "2. Reboot to apply display and audio settings:"
echo "   sudo reboot"
echo ""
echo "3. After reboot, test the setup:"
echo "   cd ~/spaceinvaders && ./test_game.sh"
echo ""
echo "4. Run the game:"
echo "   cd ~/spaceinvaders && python3 spaceinvaders_pi_portrait.py"
echo ""
echo "Files created:"
echo "  ~/spaceinvaders/test_game.sh - Test installation"
echo "  ~/spaceinvaders/uninstall.sh - Remove installation"
echo ""
echo "Controls:"
echo "  Arrow keys or D-pad: Move ship"
echo "  Space or X button: Shoot"
echo "  Escape: Exit game"
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Auto-start is enabled - game will start on boot"
    echo "To disable: sudo systemctl disable spaceinvaders.service"
fi

echo ""
echo "Enjoy your Space Invaders game!"
