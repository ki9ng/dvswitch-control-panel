#!/bin/bash
###############################################################################
# DVSwitch Control Panel Uninstaller
# Removes the web-based control interface for DVSwitch Server
# Author: KI9NG
# License: MIT
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║        DVSwitch Control Panel Uninstaller                ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}This will remove the DVSwitch Control Panel from your system.${NC}"
echo -e "${YELLOW}Your DVSwitch configuration and favorites will NOT be removed.${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}[1/6] Stopping Apache...${NC}"
systemctl stop apache2
echo -e "${GREEN}✓ Apache stopped${NC}"

echo -e "${YELLOW}[2/6] Removing HTML file...${NC}"
if [ -f "/var/www/html/dvswitch-control.html" ]; then
    rm /var/www/html/dvswitch-control.html
    echo -e "${GREEN}✓ Removed /var/www/html/dvswitch-control.html${NC}"
else
    echo -e "${YELLOW}HTML file not found (already removed)${NC}"
fi

# Remove backups
rm -f /var/www/html/dvswitch-control.html.backup-* 2>/dev/null

echo -e "${YELLOW}[3/6] Removing CGI script...${NC}"
if [ -f "/var/www/cgi-bin/dvswitch-control.sh" ]; then
    rm /var/www/cgi-bin/dvswitch-control.sh
    echo -e "${GREEN}✓ Removed /var/www/cgi-bin/dvswitch-control.sh${NC}"
else
    echo -e "${YELLOW}CGI script not found (already removed)${NC}"
fi

# Remove network switcher
if [ -f "/usr/local/bin/dvswitch-network-switcher.sh" ]; then
    rm /usr/local/bin/dvswitch-network-switcher.sh
    echo -e "${GREEN}✓ Removed network switcher${NC}"
fi

# Remove sudoers configuration
if [ -f "/etc/sudoers.d/dvswitch-control" ]; then
    sudo rm /etc/sudoers.d/dvswitch-control
    echo -e "${GREEN}✓ Removed sudoers configuration${NC}"
fi

# Remove backups
rm -f /var/www/cgi-bin/dvswitch-control.sh.backup-* 2>/dev/null

# Remove CGI directory if empty
if [ -d "/var/www/cgi-bin" ] && [ -z "$(ls -A /var/www/cgi-bin)" ]; then
    rmdir /var/www/cgi-bin
    echo -e "${GREEN}✓ Removed empty CGI directory${NC}"
fi

echo -e "${YELLOW}[4/6] Removing Apache CGI configuration...${NC}"
if [ -f "/etc/apache2/sites-enabled/000-default.conf" ]; then
    if grep -q "DVSwitch Control Panel CGI" /etc/apache2/sites-enabled/000-default.conf; then
        # Try to restore from backup first
        LATEST_BACKUP=$(ls -t /etc/apache2/sites-enabled/000-default.conf.backup-* 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            cp "$LATEST_BACKUP" /etc/apache2/sites-enabled/000-default.conf
            echo -e "${GREEN}✓ Restored Apache config from backup${NC}"
        else
            # Remove our configuration manually
            # Create a backup first
            cp /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.pre-uninstall-$(date +%Y%m%d-%H%M%S)
            
            # Remove the DVSwitch CGI section
            sed -i '/# DVSwitch Control Panel CGI/,/<\/Directory>/d' /etc/apache2/sites-enabled/000-default.conf
            echo -e "${GREEN}✓ Removed CGI configuration from Apache${NC}"
        fi
    else
        echo -e "${YELLOW}Apache CGI configuration not found (already removed)${NC}"
    fi
fi

echo -e "${YELLOW}[5/6] Starting Apache...${NC}"
systemctl start apache2
echo -e "${GREEN}✓ Apache started${NC}"

echo -e "${YELLOW}[6/6] Cleaning up...${NC}"
# Remove any temporary files
rm -f /tmp/dvswitch-control*.sh 2>/dev/null
rm -f /tmp/install-dvswitch-control.sh 2>/dev/null
echo -e "${GREEN}✓ Cleanup complete${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Uninstall Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "The following were ${RED}REMOVED${NC}:"
echo -e "  - /var/www/html/dvswitch-control.html"
echo -e "  - /var/www/cgi-bin/dvswitch-control.sh"
echo -e "  - Apache CGI configuration"
echo ""
echo -e "The following were ${GREEN}PRESERVED${NC}:"
echo -e "  - /var/lib/dvswitch/dvs/tgdb/DMR_fvrt_list.txt (your favorites)"
echo -e "  - DVSwitch Server installation"
echo -e "  - All DVSwitch configurations"
echo -e "  - Apache backup files"
echo ""
echo -e "${YELLOW}Note: Backup files are in /etc/apache2/sites-enabled/ and /var/www/${NC}"
echo ""
