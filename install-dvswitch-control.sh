#!/bin/bash
###############################################################################
# DVSwitch Control Panel Installer v1.6
# Installs web-based control interface for DVSwitch Server on ASL3
# Author: KI9NG
# License: MIT
# Supports: Debian 12 (Bookworm) and Debian 13 (Trixie)
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║          DVSwitch Control Panel Installer                 ║"
echo "║                    Version 1.6                            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Detect Debian version
echo -e "${BLUE}[0/9] Detecting system...${NC}"
if [ -f /etc/debian_version ]; then
    DEBIAN_VERSION=$(cat /etc/debian_version)
    DEBIAN_CODENAME=$(lsb_release -cs 2>/dev/null || grep VERSION_CODENAME /etc/os-release | cut -d= -f2)

    echo -e "${GREEN}Detected: Debian ${DEBIAN_VERSION} (${DEBIAN_CODENAME})${NC}"

    # Validate supported versions
    if [[ "$DEBIAN_CODENAME" != "bookworm" ]] && [[ "$DEBIAN_CODENAME" != "trixie" ]]; then
        echo -e "${YELLOW}⚠ Warning: This installer is tested on Bookworm and Trixie${NC}"
        echo -e "${YELLOW}  Your system (${DEBIAN_CODENAME}) may work but is untested${NC}"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo -e "${RED}Could not detect Debian version${NC}"
    exit 1
fi

echo -e "${GREEN}New in v1.6:
  • Debian Trixie (13) Support
  • Debian Bookworm (12) Support
  • Improved error handling
  • Better Apache configuration detection${NC}"
echo "  • DMR Network Switching"
echo "  • Mode Switching (DMR/YSF/P25/NXDN/DSTAR)"
echo "  • Quick Tune & Favorites Management"
echo ""

echo -e "${YELLOW}[1/9] Checking prerequisites...${NC}"

# Check for Apache2
if ! command -v apache2 &> /dev/null; then
    echo -e "${RED}Apache2 is not installed.${NC}"
    echo -e "${YELLOW}Installing Apache2...${NC}"
    apt update
    apt install -y apache2 || {
        echo -e "${RED}Failed to install Apache2${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Apache2 installed${NC}"
else
    echo -e "${GREEN}✓ Apache2 found${NC}"
fi

# Check for DVSwitch
if [ ! -f "/opt/MMDVM_Bridge/dvswitch.sh" ]; then
    echo -e "${RED}DVSwitch does not appear to be installed.${NC}"
    echo -e "${YELLOW}Please install DVSwitch Server first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ DVSwitch found${NC}"

# Check for required tools
if ! command -v wget &> /dev/null; then
    echo -e "${YELLOW}Installing wget...${NC}"
    apt install -y wget || {
        echo -e "${RED}Failed to install wget${NC}"
        exit 1
    }
fi

if ! command -v lsb_release &> /dev/null; then
    apt install -y lsb-release 2>/dev/null || true
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"

echo -e "${YELLOW}[2/9] Creating directories...${NC}"
mkdir -p /var/www/html
mkdir -p /var/www/cgi-bin
echo -e "${GREEN}✓ Directories created${NC}"

echo -e "${YELLOW}[3/9] Downloading HTML control panel...${NC}"
if wget -q -O /var/www/html/dvswitch-control.html \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/dvswitch-control.html; then
    echo -e "${GREEN}✓ HTML control panel installed${NC}"
else
    echo -e "${RED}Failed to download HTML. Check your internet connection.${NC}"
    exit 1
fi

echo -e "${YELLOW}[4/9] Downloading CGI control script...${NC}"
if wget -q -O /var/www/cgi-bin/dvswitch-control.sh \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/dvswitch-control.sh; then
    chmod +x /var/www/cgi-bin/dvswitch-control.sh
    echo -e "${GREEN}✓ CGI control script installed${NC}"
else
    echo -e "${RED}Failed to download CGI script. Check your internet connection.${NC}"
    exit 1
fi

echo -e "${YELLOW}[5/9] Installing network switcher (optional)...${NC}"
if wget -q -O /usr/local/bin/dvswitch-network-switcher.sh \
    https://raw.githubusercontent.com/ki9ng/dvswitch-control-panel/main/network-switcher.sh; then
    chmod +x /usr/local/bin/dvswitch-network-switcher.sh
    echo -e "${GREEN}✓ Network switcher installed${NC}"

    # Configure sudo access for www-data
    SUDOERS_LINE="www-data ALL=(ALL) NOPASSWD: /usr/local/bin/dvswitch-network-switcher.sh"
    if ! grep -q "dvswitch-network-switcher.sh" /etc/sudoers.d/dvswitch-control 2>/dev/null; then
        echo "$SUDOERS_LINE" | tee /etc/sudoers.d/dvswitch-control > /dev/null
        chmod 440 /etc/sudoers.d/dvswitch-control
        echo -e "${GREEN}✓ Sudo access configured for network switching${NC}"
    else
        echo -e "${GREEN}✓ Sudo access already configured${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Network switcher download failed - you can add it later${NC}"
fi

echo -e "${YELLOW}[6/9] Fixing favorites file permissions...${NC}"
FAVORITES_FILE="/var/lib/dvswitch/dvs/tgdb/DMR_fvrt_list.txt"
FAVORITES_DIR="/var/lib/dvswitch/dvs/tgdb"

if [ -f "$FAVORITES_FILE" ]; then
    chmod 666 "$FAVORITES_FILE" 2>/dev/null || {
        echo -e "${YELLOW}⚠ Could not set permissions on favorites file${NC}"
    }
    chmod 777 "$FAVORITES_DIR" 2>/dev/null || true
    echo -e "${GREEN}✓ Favorites file and directory permissions updated${NC}"
else
    if [ -d "$FAVORITES_DIR" ]; then
        chmod 777 "$FAVORITES_DIR" 2>/dev/null || true
        echo -e "${YELLOW}Note: Favorites file will be created on first use${NC}"
    else
        echo -e "${YELLOW}Note: DVSwitch favorites directory will be created when needed${NC}"
    fi
fi

echo -e "${YELLOW}[7/9] Configuring Apache...${NC}"

# Enable CGI module - different approaches for different Apache versions
if a2enmod cgi 2>/dev/null; then
    echo -e "${GREEN}✓ CGI module enabled (mod_cgi)${NC}"
elif a2enmod cgid 2>/dev/null; then
    echo -e "${GREEN}✓ CGI module enabled (mod_cgid)${NC}"
else
    echo -e "${YELLOW}⚠ Could not enable CGI module - may already be enabled${NC}"
fi

# Detect Apache configuration file
APACHE_CONF=""
if [ -f "/etc/apache2/sites-enabled/000-default.conf" ]; then
    APACHE_CONF="/etc/apache2/sites-enabled/000-default.conf"
elif [ -f "/etc/apache2/sites-available/000-default.conf" ]; then
    APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
    a2ensite 000-default 2>/dev/null || true
fi

if [ -z "$APACHE_CONF" ]; then
    echo -e "${RED}Could not find Apache default site configuration${NC}"
    exit 1
fi

# Check if CGI is already configured
if ! grep -q "ScriptAlias /cgi-bin/" "$APACHE_CONF" 2>/dev/null; then
    # Backup configuration
    cp "$APACHE_CONF" "${APACHE_CONF}.backup-$(date +%Y%m%d-%H%M%S)"

    # Add CGI configuration before </VirtualHost>
    sed -i '/<\/VirtualHost>/i \    # DVSwitch Control Panel CGI\n    ScriptAlias /cgi-bin/ /var/www/cgi-bin/\n    <Directory "/var/www/cgi-bin">\n        AllowOverride None\n        Options +ExecCGI\n        Require all granted\n    </Directory>\n' "$APACHE_CONF"

    echo -e "${GREEN}✓ Apache configured${NC}"
else
    echo -e "${GREEN}✓ Apache already configured${NC}"
fi

# Verify Apache configuration
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    echo -e "${GREEN}✓ Apache configuration valid${NC}"
else
    echo -e "${RED}Apache configuration error detected${NC}"
    apache2ctl configtest
    exit 1
fi

echo -e "${YELLOW}[8/9] Restarting Apache...${NC}"
if systemctl restart apache2; then
    echo -e "${GREEN}✓ Apache restarted${NC}"
else
    echo -e "${RED}Failed to restart Apache${NC}"
    systemctl status apache2
    exit 1
fi

echo -e "${YELLOW}[9/9] Testing installation...${NC}"
if [ -f "/var/www/html/dvswitch-control.html" ] && [ -x "/var/www/cgi-bin/dvswitch-control.sh" ]; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
else
    echo -e "${RED}✗ Installation verification failed${NC}"
    [ ! -f "/var/www/html/dvswitch-control.html" ] && echo "  Missing: HTML file"
    [ ! -x "/var/www/cgi-bin/dvswitch-control.sh" ] && echo "  Missing or not executable: CGI script"
    exit 1
fi

# Get IP address for display
NODE_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "System: ${BLUE}Debian ${DEBIAN_VERSION} (${DEBIAN_CODENAME})${NC}"
echo ""
echo -e "Access your DVSwitch Control Panel at:"
echo -e "${YELLOW}http://${NODE_IP}/dvswitch-control.html${NC}"
echo ""
echo -e "${GREEN}Features:${NC}"
echo "  • Mode Switching: Click DMR, YSF, P25, NXDN, or D-STAR buttons"
echo "  • Auto Mode Detection: Current mode highlighted automatically"
echo "  • Quick Tune: Type any TG number and press TUNE"
echo "  • Add to Favorites: Click ADD TO FAVORITES button"
echo "  • Delete Favorites: Hover over any favorite and click X"
echo ""
echo "73!"
