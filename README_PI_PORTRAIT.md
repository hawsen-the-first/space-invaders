# Space Invaders - Raspberry Pi Zero W 2 Portrait Mode

This is a complete adaptation of the Space Invaders game optimized for Raspberry Pi Zero W 2 running on a 1920x1080 portrait display with PWM audio output.

## Quick Start

1. **Copy all game files** to your Raspberry Pi Zero W 2
2. **Run the installation script**: `./install_pi_spaceinvaders.sh`
3. **Build the PWM audio circuit** (see hardware section below)
4. **Reboot** and enjoy!

## What's Included

### Game Files
- `spaceinvaders_pi_portrait.py` - Main game optimized for portrait mode
- `pi_setup_instructions.md` - Detailed setup guide
- `install_pi_spaceinvaders.sh` - Automated installation script

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

### Option 1: Automated (Recommended)
```bash
# Copy all files to Pi, then run:
./install_pi_spaceinvaders.sh
```

### Option 2: Manual
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
- **Keyboard**: Arrow keys (move), Space (shoot), Escape (exit)
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
- **Boot Time**: ~30 seconds to game start (with auto-start)
- **Memory Usage**: ~50-80MB during gameplay

## Troubleshooting

### Common Issues
1. **No Display**: Check HDMI configuration in `/boot/config.txt`
2. **No Audio**: Verify PWM circuit and configuration
3. **Low Performance**: Increase GPU memory split to 128MB
4. **Wrong Orientation**: Ensure `display_rotate=1` in config

### Test Commands
```bash
# Test installation
cd ~/spaceinvaders && ./test_game.sh

# Test audio
speaker-test -t sine -f 1000 -c 1 -s 1

# Check display
xrandr
```

## File Structure
```
~/spaceinvaders/
├── spaceinvaders_pi_portrait.py    # Main game file
├── install_pi_spaceinvaders.sh     # Installation script
├── test_game.sh                    # Test script (created by installer)
├── uninstall.sh                    # Uninstall script (created by installer)
├── fonts/
│   └── space_invaders.ttf
├── images/
│   ├── background.jpg
│   ├── ship.png
│   ├── enemy*.png
│   ├── laser.png
│   └── explosion*.png
└── sounds/
    ├── *.wav
    └── ...
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
- CPU governor: Set to "performance"
- Swap: Reduce swappiness for better performance

## Auto-Start Configuration

The installer can configure the game to start automatically on boot:
- **Enable**: Choose 'y' during installation
- **Disable**: `sudo systemctl disable spaceinvaders.service`
- **Status**: `sudo systemctl status spaceinvaders.service`

## Uninstalling

To remove the game and restore original settings:
```bash
cd ~/spaceinvaders && ./uninstall.sh
sudo reboot
```

## Credits

- **Original Game**: Lee Robinson
- **Pi Portrait Adaptation**: Assistant
- **Hardware**: Raspberry Pi Foundation
- **Graphics Library**: pygame

## License

Same as original Space Invaders project.

## Support

For issues specific to the Pi Zero W 2 portrait adaptation:
1. Check the troubleshooting section
2. Verify hardware connections
3. Test with the provided test script
4. Review system logs: `journalctl -u spaceinvaders.service`

Enjoy your retro gaming experience on the Raspberry Pi Zero W 2!
