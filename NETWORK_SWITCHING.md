# DMR Network Switching Configuration Guide

The DVSwitch Control Panel v1.5 includes **automatic** network switching that reads your existing DVSwitch configuration!

## How It Works

The control panel:
1. **Reads** `/var/lib/dvswitch/dvs/var.txt` for network configurations
2. **Shows buttons** only for networks you have configured
3. **Switches automatically** - no manual setup needed!

## Quick Start

The installer handles everything automatically! Just install and use.

### Check Your Configuration

Your networks are configured in `/var/lib/dvswitch/dvs/var.txt`:

```bash
cat /var/lib/dvswitch/dvs/var.txt | grep -A 4 "bm_\|tgif_\|dmrplus_\|other"
```

You'll see sections like:

```bash
# BrandMeister
bm_name=Brandmeister
bm_address=3102.master.brandmeister.network
bm_password=YOUR_PASSWORD_HERE
bm_port=62031

# TGIF
tgif_name=TGIF
tgif_address=tgif.network
tgif_password=YOUR_PASSWORD_HERE
tgif_port=62031

# DMR+
dmrplus_name=DMRPlus
dmrplus_address=dmr-marc.net
dmrplus_password=YOUR_PASSWORD_HERE
dmrplus_port=8880

# Custom networks
other1_name=FreeDMR
other1_address=freedmr.network
other1_password=YOUR_PASSWORD_HERE
other1_port=62031
```

**Important**: Only networks with BOTH address AND password configured will appear in the web interface!

### Add Network Passwords

Get passwords from each network:
- **BrandMeister**: https://brandmeister.network/ (Hotspot Security Password)
- **TGIF**: https://tgif.network/ (from registration email)
- **DMR+**: https://dmrplus.org/
- **FreeDMR**: https://freedmr.network/

### Ready to Use!

Open the control panel - you'll see buttons for each configured network!

## Adding a New Network

To add a new network (like FreeDMR):

1. Edit var.txt:
```bash
sudo nano /var/lib/dvswitch/dvs/var.txt
```

2. Add to `other1` or `other2` section:
```bash
other1_name=FreeDMR
other1_address=freedmr.network
other1_password=YOUR_FREEDMR_PASSWORD
other1_port=62031
```

3. Save and refresh the control panel - the button appears automatically!

## Your Current Configuration

Based on your var.txt:
- ✅ **TGIF** - Configured and active
- ✅ **BrandMeister** - Configured (address set, check password)
- ❌ **DMR+** - Not configured (no address)
- ❌ **Other networks** - Not configured

## Usage

### From Web Interface
Click any network button - switching takes 5-10 seconds as MMDVM_Bridge restarts.

### From Command Line
```bash
sudo /usr/local/bin/dvswitch-network-switcher.sh BrandMeister
sudo /usr/local/bin/dvswitch-network-switcher.sh TGIF
sudo /usr/local/bin/dvswitch-network-switcher.sh DMRplus
```

## Troubleshooting

### Button doesn't appear
- Check `/var/lib/dvswitch/dvs/var.txt` has both address AND password for that network
- Refresh the page

### Network switch fails
```bash
# Check if script is executable
ls -la /usr/local/bin/dvswitch-network-switcher.sh

# Check MMDVM_Bridge status
systemctl status mmdvm_bridge

# Test manually
sudo /usr/local/bin/dvswitch-network-switcher.sh TGIF
```

### Wrong password
Edit var.txt:
```bash
sudo nano /var/lib/dvswitch/dvs/var.txt
```

## Network-Specific Notes

### BrandMeister
- Server: 3102.master.brandmeister.network (or closest to you)
- Get password from: https://brandmeister.network/
- TG numbers are native (e.g., 3100 is just 3100)

### TGIF  
- Server: tgif.network
- Some TGs need 7-digit format (e.g., TG 3117 → 5003117)
- You're currently on this network!

### DMR+
- Server: dmr-marc.net
- Port: 8880 (different from others!)
- Check https://dmrplus.org/ for setup

### FreeDMR
- Server: freedmr.network
- Use other1 or other2 sections in var.txt
- Check their site for current servers

## Security

- Passwords stored in `/var/lib/dvswitch/dvs/var.txt`
- Only root can read this file
- Switcher script runs as root via sudo

73!

The DVSwitch Control Panel v1.5 includes network switching capabilities. However, this requires manual configuration of your network credentials.

## Prerequisites

You need accounts and passwords for each DMR network you want to use:

### BrandMeister
1. Go to https://brandmeister.network/
2. Create an account with your DMR ID
3. Get your "Hotspot Security Password" from your profile
4. Note the server closest to you (default: bm.sytes.net)

### TGIF
1. Go to https://tgif.network/
2. Register your hotspot
3. Get your password from the registration email
4. Server: tgif.network

### DMR+
1. Go to https://dmrplus.org/
2. Register your repeater/hotspot
3. Get credentials
4. Server: dmr-marc.net

### FreeDMR
1. Go to https://freedmr.network/
2. Register and get credentials
3. Server: freedmr.network

## Configuration Steps

### Step 1: Get Your Current TGIF Password

Your current configuration shows you're on TGIF. Get your password:

```bash
sudo grep "Password" /opt/MMDVM_Bridge/MMDVM_Bridge.ini | grep -A 1 "DMR Network"
```

Save this password - you'll need it!

### Step 2: Edit the Network Switcher Script

```bash
sudo nano /usr/local/bin/dvswitch-network-switcher.sh
```

Find these lines and replace with YOUR passwords:

```bash
BrandMeister)
    update_network "bm.sytes.net" "62031" "YOUR_BM_PASSWORD_HERE"
    
TGIF)
    update_network "tgif.network" "62031" "YOUR_TGIF_PASSWORD_HERE"
    
DMRplus)
    update_network "dmr-marc.net" "8880" "YOUR_DMRPLUS_PASSWORD_HERE"
    
FreeDMR)
    update_network "freedmr.network" "62031" "YOUR_FREEDMR_PASSWORD_HERE"
```

**Important**: Replace the placeholder passwords with your actual passwords for each network.

### Step 3: Set Correct Permissions

```bash
sudo chmod +x /usr/local/bin/dvswitch-network-switcher.sh
```

### Step 4: Test Network Switching

```bash
# Switch to TGIF (your current network)
sudo /usr/local/bin/dvswitch-network-switcher.sh TGIF

# Check if it worked
systemctl status mmdvm_bridge
```

### Step 5: Configure Sudo Access for Web Interface

The web interface needs to run the network switcher without a password prompt:

```bash
sudo visudo
```

Add this line at the end:

```
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/dvswitch-network-switcher.sh
```

Save and exit (Ctrl+X, Y, Enter)

## Usage

Once configured, you can:

### From Command Line
```bash
sudo /usr/local/bin/dvswitch-network-switcher.sh BrandMeister
sudo /usr/local/bin/dvswitch-network-switcher.sh TGIF
sudo /usr/local/bin/dvswitch-network-switcher.sh DMRplus
sudo /usr/local/bin/dvswitch-network-switcher.sh FreeDMR
```

### From Web Interface
Click the network buttons in the "DMR Network" section.

## Important Notes

1. **Network switching takes 5-10 seconds** as it restarts MMDVM_Bridge
2. **You'll be disconnected** from the current network when switching
3. **Only configure networks you actually have credentials for** - leave others as placeholders
4. **TGIF is your current network** - make sure to set that password first
5. **Test each network** from command line before relying on web buttons

## Troubleshooting

### Network switch doesn't work
```bash
# Check if script is executable
ls -la /usr/local/bin/dvswitch-network-switcher.sh

# Check MMDVM_Bridge status
systemctl status mmdvm_bridge

# Check logs
journalctl -u mmdvm_bridge -f
```

### Wrong password
Edit the script and update the password for that network:
```bash
sudo nano /usr/local/bin/dvswitch-network-switcher.sh
```

### Permissions error
Make sure you added the sudoers entry:
```bash
sudo visudo
```

## Security Considerations

- Passwords are stored in plain text in the switcher script
- Only root and the script owner can read it (if permissions are set correctly)
- Consider the security implications for your use case
- Alternative: Use environment variables or a separate config file

## Network-Specific Notes

### BrandMeister
- Largest network with most talkgroups
- TG numbers are native (e.g., TG 3100 is just 3100)
- Most repeaters and hotspots

### TGIF
- Smaller network
- Some TGs need 7-digit format (e.g., TG 3117 becomes 5003117)
- Good for specific regions

### DMR+
- Uses different port (8880 vs 62031)
- Different authentication method
- Check their documentation for setup

### FreeDMR
- Community-run network
- Similar to TGIF/BM in operation
- Check their site for current servers

## Getting Help

If you have issues:
1. Check your credentials at each network's website
2. Verify the server addresses are current
3. Test from command line first
4. Check MMDVM_Bridge logs
5. Ask on DVSwitch forums or Discord

73!
