# Space Invaders - Raspberry Pi Zero W 2 Portrait Mode

This is a complete adaptation of the Space Invaders game optimized for Raspberry Pi Zero W 2 running on a 1920x1080 portrait display with PWM audio output. Supports both Raspberry Pi OS Desktop and Raspberry Pi OS Lite (headless) configurations.

## Quick Start

### For Raspberry Pi OS Lite (Headless) - Recommended
1. **Copy all game files** to your Raspberry Pi Zero W 2
2. **Run the headless installation script**: `./install_pi_spaceinvaders_headless.sh`
3. **Build the PWM audio circuit** (see hardware section below)
4. **Reboot** and enjoy kiosk mode gaming!

### For Raspberry Pi OS Desktop
1. **Copy all game files** to your Raspberry Pi Zero W 2
2. **Run the standard installation script**: `./install_pi_spaceinvaders.sh`
3. **Build the PWM audio circuit** (see hardware section below)
4. **Reboot** and enjoy!

## What's Included

### Game Files
- `spaceinvaders_pi_portrait.py` - Main game optimized for portrait mode
- `install_pi_spaceinvaders_headless.sh` - **NEW** Headless/kiosk mode installer
- `install_pi_spaceinvaders.sh` - Standard desktop installer
- `pi_setup_instructions.md` - Detailed setup guide

### Required Assets (copy from original game)
- `fonts/` - Game fonts directory
- `images/` - All game sprites and backgrounds
- `sounds/` - Game audio files
- `controller-keys.json` - Controller configuration
- `leaderboard.json` - High scores

## Key Adaptations for Pi Zero W 2

### Display Optimizations
- **Resolution**: Adapted from landscape to 1080x1920 portrait
- **Coordinate System**: Complete remapping of all game elements
- **UI Layout**: Repositioned for vertical gameplay
- **Sprite Scaling**: Optimized sizes for portrait display

### Performance Optimizations
- **Audio**: Lower sample rate (22050Hz) optimized for PWM
- **Graphics**: Reduced sprite scaling operations
- **Memory**: Smaller buffer sizes for Pi Zero W 2
- **CPU**: Performance governor and memory optimizations

### Hardware Integration
- **PWM Audio**: Simple 2-component circuit for basic audio
- **Portrait Display**: Automatic rotation configuration
- **Controller Support**: USB gamepad compatibility maintained

### Headless/Kiosk Mode Features
- **Auto-boot to game**: Starts game automatically on power-up
- **Crash recovery**: Automatically restarts game if it crashes
- **Clean exit**: ESC key exits game and reboots system
- **Minimal X11**: Only installs necessary components for gaming
- **Performance optimized**: CPU governor and memory tuning

## Hardware Requirements

### Essential
- Raspberry Pi Zero W 2
- 1920x1080 display (rotated to portrait)
- MicroSD card (16GB+)

### PWM Audio Circuit (~$3)
```
GPIO 18 (Pin 12) → 1kΩ Resistor → Audio Output (+)
                                 ↓
                            33nF Capacitor
                                 ↓
Ground (Pin 6) ←──────────── Audio Ground (-)
```

### Optional
- USB gamepad/controller
- Small speaker (8Ω, 0.5W)
- 3.5mm audio jack

## Installation Options

### Option 1: Headless Kiosk Mode (Recommended for dedicated gaming)
**Best for**: Dedicated arcade machine, kiosk setup, minimal resource usage

```bash
# Copy all files to Pi, then run:
./install_pi_spaceinvaders_headless.sh
```

**Features:**
- Boots directly to game (no desktop)
- Auto-restart on crash
- Minimal system overhead
- Perfect for arcade cabinet setup
- ESC key reboots system

### Option 2: Desktop Mode
**Best for**: Development, testing, multi-purpose Pi

```bash
# Copy all files to Pi, then run:
./install_pi_spaceinvaders.sh
```

**Features:**
- Works with existing desktop environment
- Manual game launching
- Access to other applications
- Standard desktop experience

### Option 3: Manual Installation
Follow the detailed instructions in `pi_setup_instructions.md`

## Game Features

### Portrait Mode Adaptations
- **Ship Position**: Centered at bottom of screen
- **Enemy Grid**: 8x5 formation (reduced from 10x5)
- **UI Elements**: Score and lives repositioned for portrait
- **Blockers**: Centered and scaled for portrait layout

### Performance Features
- **60 FPS Target**: Optimized for smooth gameplay
- **Auto-scaling**: Background and sprites adapted to portrait
- **Memory Efficient**: Reduced resource usage for Pi Zero W 2

### Controls
- **Keyboard**: Arrow keys (move), Space (shoot), Escape (exit/reboot in kiosk mode)
- **Controller**: D-pad (move), X button (shoot), Circle (reset)

## Audio Quality

The PWM audio provides basic but functional game audio:
- **Quality**: Adequate for retro gaming
- **Limitations**: Some background noise, limited dynamic range
- **Volume**: Adjustable in game code
- **Upgrade Path**: Can be replaced with I2S DAC for better quality

## Performance Expectations

### Raspberry Pi Zero W 2
- **Target FPS**: 60 (may vary based on system load)
- **Audio Latency**: Minimal with PWM
- **Boot Time**: ~30 seconds to game start (headless mode)
- **Memory Usage**: ~50-80MB during gameplay
- **Storage**: ~100MB additional for headless X11 components

## Troubleshooting

### Headless Mode Issues
1. **Game won't start on boot**: 
   ```bash
   sudo systemctl status spaceinvaders-kiosk.service
   journalctl -u spaceinvaders-kiosk.service -f
   ```

2. **XDG_RUNTIME_DIR errors**: Fixed in headless installer with proper environment setup

3. **Display not detected**: Check HDMI cable and `/boot/config.txt` settings

### Common Issues
1. **No Display**: Check HDMI configuration in `/boot/config.txt`
2. **No Audio**: Verify PWM circuit and configuration
3. **Low Performance**: Increase GPU memory split to 128MB
4. **Wrong Orientation**: Ensure `display_rotate=1` in config

### Test Commands

**Headless Mode:**
```bash
# Test headless installation
cd ~/spaceinvaders && ./test_headless.sh

# Check kiosk service
sudo systemctl status spaceinvaders-kiosk.service

# View live logs
journalctl -u spaceinvaders-kiosk.service -f

# Manual game start
cd ~/spaceinvaders && ./start_game.sh
```

**Desktop Mode:**
```bash
# Test installation
cd ~/spaceinvaders && ./test_game.sh

# Test audio
speaker-test -t sine -f 1000 -c 1 -s 1

# Check display
xrandr
```

## File Structure

### Headless Mode
```
~/spaceinvaders/
├── spaceinvaders_pi_portrait.py       # Main game file
├── install_pi_spaceinvaders_headless.sh # Headless installer
├── start_game.sh                      # Manual game launcher (created by installer)
├── test_headless.sh                   # Test script (created by installer)
├── uninstall_headless.sh              # Uninstall script (created by installer)
├── fonts/
├── images/
└── sounds/
```

### Desktop Mode
```
~/spaceinvaders/
├── spaceinvaders_pi_portrait.py    # Main game file
├── install_pi_spaceinvaders.sh     # Desktop installer
├── test_game.sh                    # Test script (created by installer)
├── uninstall.sh                    # Uninstall script (created by installer)
├── fonts/
├── images/
└── sounds/
```

## Kiosk Mode Management

### Service Control
```bash
# Enable/disable auto-start
sudo systemctl enable spaceinvaders-kiosk.service
sudo systemctl disable spaceinvaders-kiosk.service

# Start/stop manually
sudo systemctl start spaceinvaders-kiosk.service
sudo systemctl stop spaceinvaders-kiosk.service

# Check status
sudo systemctl status spaceinvaders-kiosk.service
```

### Logs and Debugging
```bash
# View live logs
journalctl -u spaceinvaders-kiosk.service -f

# View recent logs
journalctl -u spaceinvaders-kiosk.service --since "1 hour ago"

# Check performance service
sudo systemctl status game-performance.service
```

## Customization

### Audio Settings
Modify mixer settings in `spaceinvaders_pi_portrait.py`:
```python
mixer.pre_init(22050, -16, 1, 2048)  # Sample rate, bit depth, channels, buffer
```

### Display Settings
Adjust resolution in `/boot/config.txt`:
```
hdmi_cvt=1080 1920 60 6 0 0 0  # Width, height, refresh rate
```

### Performance Tuning
- GPU memory: `gpu_mem=128` (or higher)
- CPU governor: Set to "performance" (automatic in headless mode)
- Swap: Reduce swappiness for better performance

### Kiosk Behavior
Edit `~/spaceinvaders/start_game.sh` to modify:
- Restart delay after crash
- Reboot behavior on normal exit
- Startup sequence timing

## Uninstalling

### Headless Mode
```bash
cd ~/spaceinvaders && ./uninstall_headless.sh
sudo reboot
```

### Desktop Mode
```bash
cd ~/spaceinvaders && ./uninstall.sh
sudo reboot
```

## Comparison: Headless vs Desktop

| Feature | Headless Mode | Desktop Mode |
|---------|---------------|--------------|
| Boot Time | ~30 seconds to game | ~60+ seconds |
| Memory Usage | ~100MB total | ~300+ MB total |
| Auto-start | Yes (kiosk mode) | Optional |
| Crash Recovery | Automatic | Manual restart |
| System Access | Game only | Full desktop |
| Performance | Optimized | Standard |
| Setup Complexity | Automated | Standard |
| Best For | Arcade cabinet | Development |

## Credits

- **Original Game**: Lee Robinson
- **Pi Portrait Adaptation**: Assistant
- **Headless/Kiosk Mode**: Assistant
- **Hardware**: Raspberry Pi Foundation
- **Graphics Library**: pygame

## License

Same as original Space Invaders project.

## Support

For issues specific to the Pi Zero W 2 portrait adaptation:

### Headless Mode
1. Check service status: `sudo systemctl status spaceinvaders-kiosk.service`
2. View logs: `journalctl -u spaceinvaders-kiosk.service -f`
3. Test manually: `cd ~/spaceinvaders && ./start_game.sh`
4. Run diagnostics: `cd ~/spaceinvaders && ./test_headless.sh`

### Desktop Mode
1. Check the troubleshooting section
2. Verify hardware connections
3. Test with: `cd ~/spaceinvaders && ./test_game.sh`
4. Review system logs: `journalctl -u spaceinvaders.service`

## Recommended Setup

For the best arcade experience, we recommend:
1. **Raspberry Pi OS Lite** with headless installer
2. **Kiosk mode enabled** for auto-boot gaming
3. **USB gamepad** for authentic arcade feel
4. **Dedicated display** in portrait orientation
5. **Simple PWM audio circuit** for cost-effective sound

Enjoy your retro gaming experience on the Raspberry Pi Zero W 2!
