# Quick Start Guide

## Installation (One Command)

Run this command on your AllStarLink 3 node:

```bash
curl -sSL https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/install-dvswitch-control.sh | sudo bash
```

## Access Your Control Panel

After installation, open your browser:

```
http://YOUR_NODE_IP/dvswitch-control.html
```

Example:
```
http://192.168.1.100/dvswitch-control.html
http://604010.ki9ng.com/dvswitch-control.html
```

## Using the Features

### Mode Switching
Click any mode button (DMR, YSF, P25, NXDN, D-STAR) to change modes. Active mode is highlighted.

### Quick Tune
1. Type a talkgroup number in the "Quick Tune" field
2. Press Enter or click TUNE
3. DVSwitch tunes to that TG immediately

### Add to Favorites
1. Click "ADD TO FAVORITES" button
2. Enter talkgroup number and name
3. Click "ADD FAVORITE"
4. New button appears in your grid

### Delete Favorites
1. Hover over any favorite button
2. Click the X that appears in the corner
3. Favorite is removed

### Switch Modes
Click DMR, YSF, P25, NXDN, or D-STAR buttons to change modes

## Customize Your Favorites (Manual)

Edit your favorite talkgroups:

```bash
sudo nano /var/lib/dvswitch/dvs/tgdb/DMR_fvrt_list.txt
```

Format (use three pipes):
```
31164|||NI9CA
3100|||USA Nationwide
31|||Worldwide
```

Refresh your browser to see changes.

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/uninstall-dvswitch-control.sh | sudo bash
```

## Troubleshooting

**Control panel not loading:**
```bash
sudo systemctl status apache2
sudo tail -f /var/log/apache2/error.log
```

**Commands not working:**
```bash
sudo chmod +x /var/www/cgi-bin/dvswitch-control.sh
sudo systemctl restart apache2
```

**DVSwitch services not running:**
```bash
sudo systemctl restart analog_bridge mmdvm_bridge md380-emu
```

## Need Help?

Open an issue on GitHub: https://github.com/ki9ng/dvswitch-control-panel/issues

73!
