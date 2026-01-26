#!/bin/bash
###############################################################################
# DVSwitch Control Panel Installer v1.3
# Installs web-based control interface for DVSwitch Server on ASL3
# Author: KI9NG
# License: MIT
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║          DVSwitch Control Panel Installer                ║"
echo "║                    Version 1.5                            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}New in v1.5:
  • DMR Network Switching - Reads your var.txt, shows configured networks
  • Dynamic Buttons - Only displays networks you have set up
  • Mode Switching - One-click DMR/YSF/P25/NXDN/DSTAR buttons${NC}"
echo "  • Quick Tune - Type any TG and tune instantly"
echo "  • Add to Favorites - Web interface to add favorites"
echo "  • Delete Favorites - Hover and click X to remove"
echo ""

echo -e "${YELLOW}[1/8] Checking prerequisites...${NC}"

if ! command -v apache2 &> /dev/null; then
    echo -e "${RED}Apache2 is not installed. Please install it first.${NC}"
    exit 1
fi

if [ ! -f "/opt/MMDVM_Bridge/dvswitch.sh" ]; then
    echo -e "${RED}DVSwitch does not appear to be installed.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"

echo -e "${YELLOW}[2/8] Creating directories...${NC}"
mkdir -p /var/www/html
mkdir -p /var/www/cgi-bin
echo -e "${GREEN}✓ Directories created${NC}"

echo -e "${YELLOW}[3/8] Downloading HTML control panel...${NC}"
wget -q -O /var/www/html/dvswitch-control.html \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/dvswitch-control.html || {
    echo -e "${RED}Failed to download HTML. Check your internet connection.${NC}"
    exit 1
}
echo -e "${GREEN}✓ HTML control panel installed${NC}"

echo -e "${YELLOW}[4/8] Downloading CGI control script...${NC}"
wget -q -O /var/www/cgi-bin/dvswitch-control.sh \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/dvswitch-control.sh || {
    echo -e "${RED}Failed to download CGI script. Check your internet connection.${NC}"
    exit 1
}
chmod +x /var/www/cgi-bin/dvswitch-control.sh
echo -e "${GREEN}✓ CGI control script installed${NC}"

echo -e "${YELLOW}[5/9] Installing network switcher (optional)...${NC}"
wget -q -O /usr/local/bin/dvswitch-network-switcher.sh \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/network-switcher.sh || {
    echo -e "${YELLOW}⚠ Network switcher download failed - you can add it later${NC}"
}
if [ -f "/usr/local/bin/dvswitch-network-switcher.sh" ]; then
    chmod +x /usr/local/bin/dvswitch-network-switcher.sh
    echo -e "${GREEN}✓ Network switcher installed${NC}"
    
    # Configure sudo access for www-data
    SUDOERS_LINE="www-data ALL=(ALL) NOPASSWD: /usr/local/bin/dvswitch-network-switcher.sh"
    if ! sudo grep -q "dvswitch-network-switcher.sh" /etc/sudoers.d/dvswitch-control 2>/dev/null; then
        echo "$SUDOERS_LINE" | sudo tee /etc/sudoers.d/dvswitch-control > /dev/null
        sudo chmod 440 /etc/sudoers.d/dvswitch-control
        echo -e "${GREEN}✓ Sudo access configured for network switching${NC}"
    else
        echo -e "${GREEN}✓ Sudo access already configured${NC}"
    fi
    
    # Check network configurations
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Checking DMR Network Configurations...${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    
    if [ -f "/var/lib/dvswitch/dvs/var.txt" ]; then
        source /var/lib/dvswitch/dvs/var.txt
        
        # Check BrandMeister
        if [ -n "$bm_address" ] && [ -n "$bm_password" ] && [ "$bm_password" != "passw0rd" ]; then
            echo -e "${GREEN}✓ BrandMeister: CONFIGURED${NC}"
            echo -e "  Server: $bm_address"
        else
            echo -e "${RED}✗ BrandMeister: NOT CONFIGURED${NC}"
            echo -e "  ${YELLOW}To enable: Edit /var/lib/dvswitch/dvs/var.txt${NC}"
            echo -e "  ${YELLOW}Get password: https://brandmeister.network/${NC}"
        fi
        
        # Check TGIF
        if [ -n "$tgif_address" ] && [ -n "$tgif_password" ]; then
            echo -e "${GREEN}✓ TGIF: CONFIGURED${NC}"
            echo -e "  Server: $tgif_address"
        else
            echo -e "${RED}✗ TGIF: NOT CONFIGURED${NC}"
            echo -e "  ${YELLOW}To enable: Edit /var/lib/dvswitch/dvs/var.txt${NC}"
            echo -e "  ${YELLOW}Get password: https://tgif.network/${NC}"
        fi
        
        # Check DMR+
        if [ -n "$dmrplus_address" ] && [ -n "$dmrplus_password" ]; then
            echo -e "${GREEN}✓ DMR+: CONFIGURED${NC}"
            echo -e "  Server: $dmrplus_address"
        else
            echo -e "${YELLOW}○ DMR+: NOT CONFIGURED (optional)${NC}"
        fi
        
        # Check FreeDMR (could be in other1 or other2)
        if [ -n "$other1_address" ] && [ -n "$other1_password" ]; then
            echo -e "${GREEN}✓ ${other1_name:-Other1}: CONFIGURED${NC}"
            echo -e "  Server: $other1_address"
        fi
        
        if [ -n "$other2_address" ] && [ -n "$other2_password" ]; then
            echo -e "${GREEN}✓ ${other2_name:-Other2}: CONFIGURED${NC}"
            echo -e "  Server: $other2_address"
        fi
        
        echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}Only configured networks will appear in the control panel${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠ DVSwitch var.txt not found - network switching may not work${NC}"
    fi
fi

echo -e "${YELLOW}[6/9] Fixing favorites file permissions...${NC}"
FAVORITES_FILE="/var/lib/dvswitch/dvs/tgdb/DMR_fvrt_list.txt"
FAVORITES_DIR="/var/lib/dvswitch/dvs/tgdb"
if [ -f "$FAVORITES_FILE" ]; then
    chmod 666 "$FAVORITES_FILE"
    chmod 777 "$FAVORITES_DIR"
    echo -e "${GREEN}✓ Favorites file and directory permissions updated${NC}"
else
    if [ -d "$FAVORITES_DIR" ]; then
        chmod 777 "$FAVORITES_DIR"
        echo -e "${YELLOW}Note: Favorites file will be created on first use${NC}"
    else
        echo -e "${YELLOW}Note: DVSwitch favorites directory will be created when needed${NC}"
    fi
fi

echo -e "${YELLOW}[7/9] Configuring Apache...${NC}"
a2enmod cgi 2>/dev/null || true

if ! grep -q "ScriptAlias /cgi-bin/" /etc/apache2/sites-enabled/000-default.conf 2>/dev/null; then
    cp /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.backup-$(date +%Y%m%d-%H%M%S)
    
    sed -i '/<\/VirtualHost>/i \    # DVSwitch Control Panel CGI\n    ScriptAlias /cgi-bin/ /var/www/cgi-bin/\n    <Directory "/var/www/cgi-bin">\n        AllowOverride None\n        Options +ExecCGI\n        Require all granted\n    </Directory>\n' /etc/apache2/sites-enabled/000-default.conf
    
    echo -e "${GREEN}✓ Apache configured${NC}"
else
    echo -e "${GREEN}✓ Apache already configured${NC}"
fi

echo -e "${YELLOW}[8/9] Restarting Apache...${NC}"
systemctl restart apache2
echo -e "${GREEN}✓ Apache restarted${NC}"

echo -e "${YELLOW}[9/9] Testing installation...${NC}"
if [ -f "/var/www/html/dvswitch-control.html" ] && [ -x "/var/www/cgi-bin/dvswitch-control.sh" ]; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Access your DVSwitch Control Panel at:"
echo -e "${YELLOW}http://$(hostname -I | awk '{print $1}')/dvswitch-control.html${NC}"
echo ""
echo -e "${GREEN}Features in v1.5:${NC}"
echo "  • DMR Network Switching - Click configured network buttons"
echo "  • Mode Switching: Click DMR, YSF, P25, NXDN, or D-STAR buttons"
echo "  • Auto Mode Detection: Current mode highlighted automatically"
echo "  • Quick Tune: Type any TG number and press TUNE"
echo "  • Add to Favorites: Click ADD TO FAVORITES button"
echo "  • Delete Favorites: Hover over any favorite and click X"
echo ""
echo -e "${YELLOW}To configure additional networks:${NC}"
echo "  sudo nano /var/lib/dvswitch/dvs/var.txt"
echo ""
echo "73!"
