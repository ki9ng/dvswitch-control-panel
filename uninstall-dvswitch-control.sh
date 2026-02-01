#!/bin/bash
###############################################################################
# DVSwitch Control Panel Uninstaller v1.6
# Removes DVSwitch Control Panel from ASL3
# Author: KI9NG
# License: MIT
# Supports: Debian 12 (Bookworm) and Debian 13 (Trixie)
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║        DVSwitch Control Panel Uninstaller                 ║"
echo "║                    Version 1.6                            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Detect system
if [ -f /etc/debian_version ]; then
    DEBIAN_VERSION=$(cat /etc/debian_version)
    DEBIAN_CODENAME=$(lsb_release -cs 2>/dev/null || grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
    echo -e "${BLUE}System: Debian ${DEBIAN_VERSION} (${DEBIAN_CODENAME})${NC}"
    echo ""
fi

echo -e "${YELLOW}This will remove the DVSwitch Control Panel from your system.${NC}"
echo -e "${YELLOW}Files and configurations will be removed.${NC}"
echo ""
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Uninstall cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}[1/6] Removing HTML control panel...${NC}"
if [ -f "/var/www/html/dvswitch-control.html" ]; then
    rm -f /var/www/html/dvswitch-control.html
    echo -e "${GREEN}✓ HTML control panel removed${NC}"
else
    echo -e "${BLUE}ℹ HTML control panel not found (already removed)${NC}"
fi

echo -e "${YELLOW}[2/6] Removing CGI control script...${NC}"
if [ -f "/var/www/cgi-bin/dvswitch-control.sh" ]; then
    rm -f /var/www/cgi-bin/dvswitch-control.sh
    echo -e "${GREEN}✓ CGI control script removed${NC}"
else
    echo -e "${BLUE}ℹ CGI control script not found (already removed)${NC}"
fi

echo -e "${YELLOW}[3/6] Removing network switcher...${NC}"
if [ -f "/usr/local/bin/dvswitch-network-switcher.sh" ]; then
    rm -f /usr/local/bin/dvswitch-network-switcher.sh
    echo -e "${GREEN}✓ Network switcher removed${NC}"
else
    echo -e "${BLUE}ℹ Network switcher not found (already removed)${NC}"
fi

echo -e "${YELLOW}[4/6] Removing sudo configuration...${NC}"
if [ -f "/etc/sudoers.d/dvswitch-control" ]; then
    rm -f /etc/sudoers.d/dvswitch-control
    echo -e "${GREEN}✓ Sudo configuration removed${NC}"
else
    echo -e "${BLUE}ℹ Sudo configuration not found (already removed)${NC}"
fi

echo -e "${YELLOW}[5/6] Cleaning up Apache configuration...${NC}"

# Detect Apache configuration file
APACHE_CONF=""
if [ -f "/etc/apache2/sites-enabled/000-default.conf" ]; then
    APACHE_CONF="/etc/apache2/sites-enabled/000-default.conf"
elif [ -f "/etc/apache2/sites-available/000-default.conf" ]; then
    APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
fi

if [ -n "$APACHE_CONF" ] && grep -q "DVSwitch Control Panel CGI" "$APACHE_CONF" 2>/dev/null; then
    # Backup before modifying
    cp "$APACHE_CONF" "${APACHE_CONF}.backup-before-uninstall-$(date +%Y%m%d-%H%M%S)"

    # Remove the CGI configuration block
    sed -i '/# DVSwitch Control Panel CGI/,/<\/Directory>/d' "$APACHE_CONF"

    # Verify Apache configuration
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        echo -e "${GREEN}✓ Apache configuration cleaned up${NC}"

        # Restart Apache
        if systemctl restart apache2 2>/dev/null; then
            echo -e "${GREEN}✓ Apache restarted${NC}"
        else
            echo -e "${YELLOW}⚠ Apache restart had issues, but configuration is valid${NC}"
        fi
    else
        echo -e "${RED}⚠ Apache configuration error - restoring backup${NC}"
        cp "${APACHE_CONF}.backup-before-uninstall-$(date +%Y%m%d-%H%M%S)" "$APACHE_CONF"
    fi
else
    echo -e "${BLUE}ℹ No Apache configuration changes needed${NC}"
fi

echo -e "${YELLOW}[6/6] Verifying removal...${NC}"

ERRORS=0

if [ -f "/var/www/html/dvswitch-control.html" ]; then
    echo -e "${RED}✗ HTML file still exists${NC}"
    ((ERRORS++))
fi

if [ -f "/var/www/cgi-bin/dvswitch-control.sh" ]; then
    echo -e "${RED}✗ CGI script still exists${NC}"
    ((ERRORS++))
fi

if [ -f "/usr/local/bin/dvswitch-network-switcher.sh" ]; then
    echo -e "${RED}✗ Network switcher still exists${NC}"
    ((ERRORS++))
fi

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All components successfully removed${NC}"
else
    echo -e "${YELLOW}⚠ Some components may still exist${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Uninstall Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Note: Favorites and DVSwitch configuration were preserved.${NC}"
echo -e "${BLUE}Apache backup files were created in /etc/apache2/sites-*${NC}"
echo ""
echo "73!"
