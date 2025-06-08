# Raspberry Pi Zero W 2 Portrait Mode Space Invaders Setup

This guide will help you set up the Space Invaders game on a Raspberry Pi Zero W 2 with a 1920x1080 portrait display and PWM audio.

## Hardware Requirements

- Raspberry Pi Zero W 2
- 1920x1080 display (rotated to portrait mode: 1080x1920)
- MicroSD card (16GB+ recommended)
- PWM audio circuit components:
  - 1x 1kΩ resistor
  - 1x 33nF (0.033µF) capacitor
  - Small speaker (8Ω, 0.5W) or 3.5mm audio jack
  - Breadboard or perfboard for circuit
- Optional: USB gamepad/controller

## PWM Audio Circuit

Connect the following circuit for basic audio output:

```
GPIO 18 (Pin 12) → 1kΩ Resistor → Audio Output (+)
                                 ↓
                            33nF Capacitor
                                 ↓
Ground (Pin 6 or 14) ←──────── Audio Ground (-)
```

## Software Setup

### 1. Raspberry Pi OS Installation

1. Flash Raspberry Pi OS Lite or Desktop to your SD card
2. Enable SSH and configure WiFi if needed
3. Boot the Pi and update the system:

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Display Configuration

Edit the boot configuration to enable portrait mode:

```bash
sudo nano /boot/config.txt
```

Add these lines to configure the display:

```
# Portrait mode display configuration
display_rotate=1
hdmi_group=2
hdmi_mode=82
hdmi_cvt=1080 1920 60 6 0 0 0

# PWM Audio configuration
dtoverlay=pwm,pin=18,func=2
```

### 3. Audio Configuration

Configure PWM as the default audio output:

```bash
# Set PWM audio as default
sudo raspi-config
```

Navigate to: Advanced Options → Audio → Force PWM

Or manually edit the audio configuration:

```bash
sudo nano /etc/asound.conf
```

Add:

```
pcm.!default {
    type hw
    card 0
    device 0
}
ctl.!default {
    type hw
    card 0
}
```

### 4. Install Dependencies

Install Python and pygame dependencies:

```bash
# Install Python and pip
sudo apt install python3 python3-pip -y

# Install pygame and dependencies
sudo apt install python3-pygame -y

# Alternative if above doesn't work:
pip3 install pygame

# Install additional dependencies
sudo apt install python3-dev python3-numpy -y
```

### 5. Game Installation

1. Copy the game files to your Pi:

```bash
# Create game directory
mkdir ~/spaceinvaders
cd ~/spaceinvaders

# Copy these files to the directory:
# - spaceinvaders_pi_portrait.py
# - fonts/ (directory with space_invaders.ttf)
# - images/ (directory with all game images)
# - sounds/ (directory with all game sounds)
# - controller-keys.json
# - leaderboard.json
```

2. Make the game executable:

```bash
chmod +x spaceinvaders_pi_portrait.py
```

### 6. Performance Optimization

Create a performance optimization script:

```bash
sudo nano /etc/systemd/system/game-performance.service
```

Add:

```ini
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
```

Enable the service:

```bash
sudo systemctl enable game-performance.service
```

### 7. Auto-Start Configuration (Optional)

To automatically start the game on boot:

```bash
sudo nano /etc/systemd/system/spaceinvaders.service
```

Add:

```ini
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
```

Enable auto-start:

```bash
sudo systemctl enable spaceinvaders.service
```

## Testing

### 1. Test Audio

Test PWM audio output:

```bash
# Test with speaker-test
speaker-test -t sine -f 1000 -c 1 -s 1
```

### 2. Test Display

Verify the display is in portrait mode:

```bash
# Check current resolution
xrandr
```

Should show 1080x1920 resolution.

### 3. Run the Game

Test the game manually:

```bash
cd ~/spaceinvaders
python3 spaceinvaders_pi_portrait.py
```

## Controls

- **Keyboard**: Arrow keys to move, Space to shoot, Escape to exit
- **Controller**: D-pad to move, X button to shoot, Circle to reset

## Troubleshooting

### Audio Issues

1. **No sound**: Check PWM configuration in `/boot/config.txt`
2. **Distorted audio**: Verify circuit connections and component values
3. **Low volume**: Adjust volume levels in the game code or add amplification

### Display Issues

1. **Wrong orientation**: Check `display_rotate` setting in `/boot/config.txt`
2. **Resolution problems**: Verify HDMI settings and display capabilities
3. **Performance issues**: Reduce game resolution or enable GPU memory split

### Performance Issues

1. **Low FPS**: 
   - Increase GPU memory split: `sudo raspi-config` → Advanced → Memory Split → 128
   - Reduce sprite scaling operations
   - Lower audio sample rate further

2. **Input lag**: 
   - Check USB polling rate
   - Reduce background processes

### Memory Issues

1. **Out of memory**: 
   - Increase swap file size
   - Close unnecessary services
   - Reduce image sizes

## File Structure

Your final directory should look like:

```
~/spaceinvaders/
├── spaceinvaders_pi_portrait.py
├── controller-keys.json
├── leaderboard.json
├── fonts/
│   └── space_invaders.ttf
├── images/
│   ├── background.jpg
│   ├── ship.png
│   ├── enemy1_1.png
│   ├── enemy1_2.png
│   ├── enemy2_1.png
│   ├── enemy2_2.png
│   ├── enemy3_1.png
│   ├── enemy3_2.png
│   ├── mystery.png
│   ├── laser.png
│   ├── enemylaser.png
│   ├── explosionblue.png
│   ├── explosiongreen.png
│   └── explosionpurple.png
└── sounds/
    ├── 0.wav
    ├── 1.wav
    ├── 2.wav
    ├── 3.wav
    ├── shoot.wav
    ├── shoot2.wav
    ├── invaderkilled.wav
    ├── mysterykilled.wav
    ├── mysteryentered.wav
    └── shipexplosion.wav
```

## Additional Notes

- The game is optimized for 60 FPS but may run at lower framerates on Pi Zero W 2
- PWM audio quality is basic but functional for game sounds
- Controller support is optional but recommended for better gameplay experience
- The portrait layout provides a classic arcade feel with vertical gameplay
