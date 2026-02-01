#!/bin/bash
###############################################################################
# DVSwitch Control Panel Installer v1.5.1
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
echo "║                   Version 1.5.1                           ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}New in v1.5.1:${NC}"
echo "  • Enhanced error checking and validation"
echo "  • CGI script testing before completion"
echo "  • Automatic recovery from common issues"
echo ""

TOTAL_STEPS=10

echo -e "${YELLOW}[1/$TOTAL_STEPS] Checking prerequisites...${NC}"

if ! command -v apache2 &> /dev/null; then
    echo -e "${RED}Apache2 is not installed. Installing...${NC}"
    apt-get update
    apt-get install -y apache2
fi

if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}curl not found, installing...${NC}"
    apt-get install -y curl
fi

if [ ! -f "/opt/MMDVM_Bridge/dvswitch.sh" ]; then
    echo -e "${RED}DVSwitch does not appear to be installed.${NC}"
    echo -e "${YELLOW}This control panel requires DVSwitch to be installed first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"

echo -e "${YELLOW}[2/$TOTAL_STEPS] Creating directories...${NC}"
mkdir -p /var/www/html
mkdir -p /var/www/cgi-bin
echo -e "${GREEN}✓ Directories created${NC}"

echo -e "${YELLOW}[3/$TOTAL_STEPS] Downloading HTML control panel...${NC}"
wget -q -O /var/www/html/dvswitch-control.html \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/dvswitch-control.html || {
    echo -e "${RED}Failed to download HTML. Check your internet connection.${NC}"
    exit 1
}
echo -e "${GREEN}✓ HTML control panel installed${NC}"

echo -e "${YELLOW}[4/$TOTAL_STEPS] Downloading CGI control script...${NC}"
wget -q -O /var/www/cgi-bin/dvswitch-control.sh \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/dvswitch-control.sh || {
    echo -e "${RED}Failed to download CGI script. Check your internet connection.${NC}"
    exit 1
}
chmod +x /var/www/cgi-bin/dvswitch-control.sh

# Validate CGI script
echo -e "${YELLOW}  Validating CGI script...${NC}"
if bash -n /var/www/cgi-bin/dvswitch-control.sh 2>/dev/null; then
    echo -e "${GREEN}  ✓ CGI script syntax valid${NC}"
else
    echo -e "${RED}  ✗ CGI script has syntax errors:${NC}"
    bash -n /var/www/cgi-bin/dvswitch-control.sh
    exit 1
fi

# Verify executable
if [ -x "/var/www/cgi-bin/dvswitch-control.sh" ]; then
    echo -e "${GREEN}  ✓ CGI script is executable${NC}"
else
    echo -e "${YELLOW}  ⚠ Fixing executable permissions...${NC}"
    chmod +x /var/www/cgi-bin/dvswitch-control.sh
fi

echo -e "${GREEN}✓ CGI control script installed and validated${NC}"

echo -e "${YELLOW}[5/$TOTAL_STEPS] Installing network switcher...${NC}"
wget -q -O /usr/local/bin/dvswitch-network-switcher.sh \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/network-switcher.sh || {
    echo -e "${YELLOW}⚠ Network switcher download failed - network switching will not work${NC}"
}
if [ -f "/usr/local/bin/dvswitch-network-switcher.sh" ]; then
    chmod +x /usr/local/bin/dvswitch-network-switcher.sh
    
    # Validate network switcher
    if bash -n /usr/local/bin/dvswitch-network-switcher.sh 2>/dev/null; then
        echo -e "${GREEN}✓ Network switcher installed${NC}"
    else
        echo -e "${RED}  ✗ Network switcher has syntax errors${NC}"
        rm /usr/local/bin/dvswitch-network-switcher.sh
    fi
    
    # Configure sudo access for www-data
    SUDOERS_LINE="www-data ALL=(ALL) NOPASSWD: /usr/local/bin/dvswitch-network-switcher.sh"
    if ! sudo grep -q "dvswitch-network-switcher.sh" /etc/sudoers.d/dvswitch-control 2>/dev/null; then
        echo "$SUDOERS_LINE" | sudo tee /etc/sudoers.d/dvswitch-control > /dev/null
        sudo chmod 440 /etc/sudoers.d/dvswitch-control
        echo -e "${GREEN}✓ Sudo access configured${NC}"
    fi
    
    # Check network configurations
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Checking DMR Network Configurations...${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    
    if [ -f "/var/lib/dvswitch/dvs/var.txt" ]; then
        source /var/lib/dvswitch/dvs/var.txt
        
        NETWORKS_FOUND=0
        
        # Check BrandMeister
        if [ -n "$bm_address" ] && [ -n "$bm_password" ] && [ "$bm_password" != "passw0rd" ]; then
            echo -e "${GREEN}✓ BrandMeister: CONFIGURED${NC}"
            echo -e "  Server: $bm_address"
            NETWORKS_FOUND=$((NETWORKS_FOUND + 1))
        else
            echo -e "${YELLOW}○ BrandMeister: NOT CONFIGURED${NC}"
            echo -e "  To enable: Edit /var/lib/dvswitch/dvs/var.txt"
            echo -e "  Get password: https://brandmeister.network/"
        fi
        
        # Check TGIF
        if [ -n "$tgif_address" ] && [ -n "$tgif_password" ]; then
            echo -e "${GREEN}✓ TGIF: CONFIGURED${NC}"
            echo -e "  Server: $tgif_address"
            NETWORKS_FOUND=$((NETWORKS_FOUND + 1))
        else
            echo -e "${YELLOW}○ TGIF: NOT CONFIGURED${NC}"
            echo -e "  To enable: Edit /var/lib/dvswitch/dvs/var.txt"
            echo -e "  Get password: https://tgif.network/"
        fi
        
        # Check DMR+
        if [ -n "$dmrplus_address" ] && [ -n "$dmrplus_password" ]; then
            echo -e "${GREEN}✓ DMR+: CONFIGURED${NC}"
            echo -e "  Server: $dmrplus_address"
            NETWORKS_FOUND=$((NETWORKS_FOUND + 1))
        fi
        
        # Check Others
        if [ -n "$other1_address" ] && [ -n "$other1_password" ]; then
            echo -e "${GREEN}✓ ${other1_name:-Other1}: CONFIGURED${NC}"
            echo -e "  Server: $other1_address"
            NETWORKS_FOUND=$((NETWORKS_FOUND + 1))
        fi
        
        if [ -n "$other2_address" ] && [ -n "$other2_password" ]; then
            echo -e "${GREEN}✓ ${other2_name:-Other2}: CONFIGURED${NC}"
            echo -e "  Server: $other2_address"
            NETWORKS_FOUND=$((NETWORKS_FOUND + 1))
        fi
        
        echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
        if [ $NETWORKS_FOUND -gt 1 ]; then
            echo -e "${GREEN}$NETWORKS_FOUND networks configured - switching buttons will appear${NC}"
        elif [ $NETWORKS_FOUND -eq 1 ]; then
            echo -e "${YELLOW}Only 1 network configured - no switching buttons${NC}"
        else
            echo -e "${YELLOW}No networks configured - network switching will not work${NC}"
        fi
        echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠ DVSwitch var.txt not found${NC}"
    fi
fi

echo -e "${YELLOW}[6/$TOTAL_STEPS] Fixing favorites file permissions...${NC}"
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

echo -e "${YELLOW}[7/$TOTAL_STEPS] Configuring Apache CGI...${NC}"

# Enable CGI module
a2enmod cgi 2>/dev/null || true

# Check if CGI is actually enabled
if apache2ctl -M 2>/dev/null | grep -q "cgi_module"; then
    echo -e "${GREEN}  ✓ CGI module enabled${NC}"
else
    echo -e "${RED}  ✗ CGI module failed to enable${NC}"
    echo -e "${YELLOW}  Attempting to enable manually...${NC}"
    a2enmod cgi
    systemctl restart apache2
fi

# Configure Apache for CGI
if ! grep -q "ScriptAlias /cgi-bin/" /etc/apache2/sites-enabled/000-default.conf 2>/dev/null; then
    cp /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.backup-$(date +%Y%m%d-%H%M%S)
    
    sed -i '/<\/VirtualHost>/i \    # DVSwitch Control Panel CGI\n    ScriptAlias /cgi-bin/ /var/www/cgi-bin/\n    <Directory "/var/www/cgi-bin">\n        AllowOverride None\n        Options +ExecCGI\n        Require all granted\n    </Directory>\n' /etc/apache2/sites-enabled/000-default.conf
    
    echo -e "${GREEN}✓ Apache CGI configured${NC}"
else
    echo -e "${GREEN}✓ Apache already configured${NC}"
fi

echo -e "${YELLOW}[8/$TOTAL_STEPS] Restarting Apache...${NC}"
if systemctl restart apache2; then
    echo -e "${GREEN}✓ Apache restarted successfully${NC}"
else
    echo -e "${RED}✗ Apache restart failed${NC}"
    echo -e "${YELLOW}Checking Apache configuration...${NC}"
    apache2ctl configtest
    exit 1
fi

echo -e "${YELLOW}[9/$TOTAL_STEPS] Testing CGI endpoint...${NC}"
sleep 2

# Test if CGI responds
if curl -f -s "http://localhost/cgi-bin/dvswitch-control.sh?action=get_favorites" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ CGI script responding${NC}"
else
    echo -e "${RED}✗ CGI script not responding${NC}"
    echo -e "${YELLOW}Checking Apache error log:${NC}"
    tail -10 /var/log/apache2/error.log
    echo ""
    echo -e "${YELLOW}Attempting to diagnose issue...${NC}"
    
    # Check if CGI can run manually
    if /var/www/cgi-bin/dvswitch-control.sh action=get_favorites > /dev/null 2>&1; then
        echo -e "${YELLOW}  Script runs manually but not via Apache${NC}"
        echo -e "${YELLOW}  This is likely a permission or Apache config issue${NC}"
    else
        echo -e "${RED}  Script has errors when running${NC}"
        /var/www/cgi-bin/dvswitch-control.sh action=get_favorites
    fi
    
    echo -e "${YELLOW}Installation completed with warnings - CGI may not work${NC}"
fi

echo -e "${YELLOW}[10/$TOTAL_STEPS] Final verification...${NC}"
if [ -f "/var/www/html/dvswitch-control.html" ] && [ -x "/var/www/cgi-bin/dvswitch-control.sh" ]; then
    echo -e "${GREEN}✓ Installation files present${NC}"
else
    echo -e "${RED}✗ Installation incomplete${NC}"
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
echo -e "${GREEN}Features in v1.5.1:${NC}"
echo "  • Enhanced error checking and diagnostics"
echo "  • DMR Network Switching with configuration check"
echo "  • Mode Switching: DMR, YSF, P25, NXDN, D-STAR"
echo "  • Quick Tune, Add/Delete Favorites"
echo ""
echo -e "${YELLOW}If you see errors in the web interface:${NC}"
echo "  1. Check: sudo tail -50 /var/log/apache2/error.log"
echo "  2. Test CGI: curl http://localhost/cgi-bin/dvswitch-control.sh?action=get_favorites"
echo "  3. Report issues: https://github.com/ki9ng/dvswitch-control-panel/issues"
echo ""
echo "73!"
