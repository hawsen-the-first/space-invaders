#!/bin/bash

# Raspberry Pi Zero W 2 Space Invaders Installation Script - Headless Edition
# Optimized for Raspberry Pi OS Lite with kiosk mode gaming
# Updated for user 'reuben'

set -e  # Exit on any error

echo "=================================================="
echo "Raspberry Pi Space Invaders Headless Setup Script"
echo "=================================================="

# Get current username
CURRENT_USER=$(whoami)
USER_ID=$(id -u)

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root. Run as the reuben user."
    exit 1
fi

echo "Running as user: $CURRENT_USER (UID: $USER_ID)"

# Detect if running on Raspberry Pi OS Lite
echo "Detecting system configuration..."
if ! command -v startx &> /dev/null; then
    echo "✓ Detected Raspberry Pi OS Lite (headless)"
    HEADLESS_MODE=true
else
    echo "✓ Detected Raspberry Pi OS with desktop"
    HEADLESS_MODE=false
fi

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies for headless gaming
echo "Installing dependencies for headless gaming..."
if [ "$HEADLESS_MODE" = true ]; then
    echo "Installing minimal X11 server for headless gaming..."
    sudo apt install -y \
        xserver-xorg-core \
        xinit \
        xserver-xorg-video-fbdev \
        xserver-xorg-input-evdev \
        xserver-xorg-input-libinput \
        openbox \
        python3 \
        python3-pip \
        python3-pygame \
        python3-dev \
        python3-numpy \
        alsa-utils
else
    echo "Installing standard dependencies..."
    sudo apt install -y python3 python3-pip python3-pygame python3-dev python3-numpy alsa-utils
fi

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
if ! grep -q "# Space Invaders Headless Configuration" /boot/config.txt; then
    echo "Adding display and PWM audio configuration to /boot/config.txt..."
    sudo tee -a /boot/config.txt > /dev/null << 'EOF'

# Space Invaders Headless Configuration
# Portrait mode display configuration
display_rotate=1
hdmi_group=2
hdmi_mode=82
hdmi_cvt=1080 1920 60 6 0 0 0

# PWM Audio configuration
dtoverlay=pwm,pin=18,func=2

# GPU memory split for better performance
gpu_mem=128

# Disable overscan for exact resolution
disable_overscan=1

# Force HDMI output
hdmi_force_hotplug=1
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

# Configure auto-login for headless kiosk mode
echo "Setting up auto-login for kiosk mode..."
sudo systemctl set-default multi-user.target

# Enable auto-login to console for current user
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
EOF

# Create X11 configuration for headless mode
if [ "$HEADLESS_MODE" = true ]; then
    echo "Creating X11 configuration for headless mode..."
    sudo tee /etc/X11/xorg.conf > /dev/null << 'EOF'
Section "Device"
    Identifier "Card0"
    Driver "fbdev"
    Option "fbdev" "/dev/fb0"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Card0"
    Monitor "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1080x1920"
    EndSubSection
EndSection

Section "Monitor"
    Identifier "Monitor0"
    Option "DPMS" "false"
EndSection

Section "ServerLayout"
    Identifier "Layout0"
    Screen "Screen0"
EndSection

Section "ServerFlags"
    Option "DontVTSwitch" "true"
    Option "DontZap" "true"
EndSection
EOF
fi

# Create game startup script
echo "Creating game startup script..."
tee ~/spaceinvaders/start_game.sh > /dev/null << EOF
#!/bin/bash

# Space Invaders Kiosk Mode Startup Script
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$USER_ID

# Function to start X11 and game
start_game() {
    echo "Starting X11 server..."
    
    # Kill any existing X server
    sudo pkill -f "X :0" 2>/dev/null || true
    sleep 2
    
    # Start X server in background
    sudo X :0 -config /etc/X11/xorg.conf &
    X_PID=\$!
    
    # Wait for X server to start
    sleep 5
    
    # Set display permissions
    xhost +local: 2>/dev/null || true
    
    # Start window manager
    openbox &
    WM_PID=\$!
    
    # Wait a moment for window manager
    sleep 2
    
    echo "Starting Space Invaders..."
    cd /home/$CURRENT_USER/spaceinvaders
    
    # Start the game with error handling
    while true; do
        python3 spaceinvaders_pi_portrait.py
        GAME_EXIT_CODE=\$?
        
        echo "Game exited with code: \$GAME_EXIT_CODE"
        
        # If game exits normally (ESC key), reboot
        if [ \$GAME_EXIT_CODE -eq 0 ]; then
            echo "Normal exit detected. Rebooting in 3 seconds..."
            sleep 3
            sudo reboot
        else
            echo "Game crashed. Restarting in 5 seconds..."
            sleep 5
        fi
    done
}

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    sudo pkill -f "python3 spaceinvaders_pi_portrait.py" 2>/dev/null || true
    sudo pkill -f "openbox" 2>/dev/null || true
    sudo pkill -f "X :0" 2>/dev/null || true
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Start the game
start_game
EOF

chmod +x ~/spaceinvaders/start_game.sh

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
ExecStart=/bin/bash -c 'echo 1 > /proc/sys/vm/drop_caches'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable game-performance.service

# Create kiosk mode service
echo "Setting up kiosk mode service..."
sudo tee /etc/systemd/system/spaceinvaders-kiosk.service > /dev/null << EOF
[Unit]
Description=Space Invaders Kiosk Mode
After=multi-user.target game-performance.service
Wants=game-performance.service

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=/home/$CURRENT_USER/spaceinvaders
ExecStart=/home/$CURRENT_USER/spaceinvaders/start_game.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables
Environment=HOME=/home/$CURRENT_USER
Environment=XDG_RUNTIME_DIR=/run/user/$USER_ID

[Install]
WantedBy=multi-user.target
EOF

# Ask about kiosk mode
echo ""
read -p "Enable kiosk mode (game starts automatically on boot)? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo systemctl enable spaceinvaders-kiosk.service
    echo "✓ Kiosk mode enabled. Game will start automatically on boot."
    KIOSK_ENABLED=true
else
    echo "Kiosk mode disabled. Use './start_game.sh' to run manually."
    KIOSK_ENABLED=false
fi

# Create test script
echo "Creating test script..."
tee ~/spaceinvaders/test_headless.sh > /dev/null << 'EOF'
#!/bin/bash
echo "Testing Space Invaders headless setup..."

echo "1. Testing Python and pygame..."
python3 -c "import pygame; print('Pygame version:', pygame.version.ver)"

echo "2. Testing X11 installation..."
if command -v X &> /dev/null; then
    echo "✓ X11 server installed"
else
    echo "✗ X11 server missing"
fi

if command -v openbox &> /dev/null; then
    echo "✓ Window manager installed"
else
    echo "✗ Window manager missing"
fi

echo "3. Testing audio configuration..."
if command -v speaker-test &> /dev/null; then
    echo "Audio test available. Run 'speaker-test -t sine -f 1000 -c 1 -s 1' to test audio."
else
    echo "speaker-test not available"
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

echo "5. Testing services..."
if systemctl is-enabled spaceinvaders-kiosk.service &>/dev/null; then
    echo "✓ Kiosk service enabled"
else
    echo "○ Kiosk service disabled"
fi

if systemctl is-enabled game-performance.service &>/dev/null; then
    echo "✓ Performance service enabled"
else
    echo "✗ Performance service disabled"
fi

echo ""
echo "Manual commands:"
echo "  Start game: ./start_game.sh"
echo "  Test audio: speaker-test -t sine -f 1000 -c 1 -s 1"
echo "  Check service: sudo systemctl status spaceinvaders-kiosk.service"
echo "  View logs: journalctl -u spaceinvaders-kiosk.service -f"
EOF

chmod +x ~/spaceinvaders/test_headless.sh

# Create uninstall script
echo "Creating uninstall script..."
tee ~/spaceinvaders/uninstall_headless.sh > /dev/null << 'EOF'
#!/bin/bash
echo "Uninstalling Space Invaders headless setup..."

# Stop and disable services
sudo systemctl stop spaceinvaders-kiosk.service 2>/dev/null || true
sudo systemctl disable spaceinvaders-kiosk.service 2>/dev/null || true
sudo systemctl stop game-performance.service 2>/dev/null || true
sudo systemctl disable game-performance.service 2>/dev/null || true

# Remove service files
sudo rm -f /etc/systemd/system/spaceinvaders-kiosk.service
sudo rm -f /etc/systemd/system/game-performance.service

# Remove auto-login
sudo rm -rf /etc/systemd/system/getty@tty1.service.d

# Restore original boot config
if [ -f /boot/config.txt.backup ]; then
    sudo cp /boot/config.txt.backup /boot/config.txt
    echo "Boot configuration restored"
fi

# Remove configurations
sudo rm -f /etc/asound.conf
sudo rm -f /etc/X11/xorg.conf

# Restore default target
sudo systemctl set-default graphical.target

# Reload systemd
sudo systemctl daemon-reload

echo "Uninstall complete. Reboot to restore original settings."
echo "Game files in ~/spaceinvaders remain - delete manually if desired."
EOF

chmod +x ~/spaceinvaders/uninstall_headless.sh

echo ""
echo "=================================================="
echo "Headless Installation Complete!"
echo "=================================================="
echo ""
echo "Configuration Summary:"
echo "  User: $CURRENT_USER"
echo "  User ID: $USER_ID"
echo "  Game Directory: /home/$CURRENT_USER/spaceinvaders"
echo "  XDG_RUNTIME_DIR: /run/user/$USER_ID"
echo ""
echo "Hardware setup:"
echo "1. Connect your PWM audio circuit:"
echo "   GPIO 18 (Pin 12) → 1kΩ resistor → Audio out"
echo "   Audio ground ← 33nF capacitor ← Audio out"
echo "   Ground (Pin 6) ← Audio ground"
echo ""
echo "2. Connect your 1920x1080 display via HDMI"
echo ""
echo "Next steps:"
echo "1. Reboot to apply all settings:"
echo "   sudo reboot"
echo ""

if [ "$KIOSK_ENABLED" = true ]; then
    echo "2. After reboot, the game will start automatically in kiosk mode"
    echo "   - Game will restart automatically if it crashes"
    echo "   - Press ESC in game to exit and reboot the system"
    echo ""
    echo "Management commands:"
    echo "   Disable kiosk: sudo systemctl disable spaceinvaders-kiosk.service"
    echo "   Check status:  sudo systemctl status spaceinvaders-kiosk.service"
    echo "   View logs:     journalctl -u spaceinvaders-kiosk.service -f"
else
    echo "2. After reboot, start the game manually:"
    echo "   cd ~/spaceinvaders && ./start_game.sh"
    echo ""
    echo "3. To enable kiosk mode later:"
    echo "   sudo systemctl enable spaceinvaders-kiosk.service"
fi

echo ""
echo "Testing:"
echo "  cd ~/spaceinvaders && ./test_headless.sh"
echo ""
echo "Files created:"
echo "  ~/spaceinvaders/start_game.sh - Manual game launcher"
echo "  ~/spaceinvaders/test_headless.sh - Test installation"
echo "  ~/spaceinvaders/uninstall_headless.sh - Remove installation"
echo ""
echo "Controls:"
echo "  Arrow keys or D-pad: Move ship"
echo "  Space or X button: Shoot"
echo "  Escape: Exit game and reboot (in kiosk mode)"
echo ""
echo "The system is configured for headless kiosk gaming!"
echo "Enjoy your Space Invaders arcade machine!"
