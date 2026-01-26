# Changelog

All notable changes to this project will be documented in this file.

## [1.5.0] - 2026-01-23

### Added
- **DMR Network Switching**: One-click buttons to switch between configured DMR networks
- **Auto Network Detection**: Reads network configs from `/var/lib/dvswitch/dvs/var.txt`
- **Dynamic Network Buttons**: Only shows buttons for networks you have configured
- **Network Display**: Shows current DMR network in header (Callsign / Node / Network)
- **BrandMeister Static TG Support**: Automatically adds `Options` field to keep TG connections alive
- **Network Configuration Check**: Installer displays which networks are properly configured
- Network switcher script (`/usr/local/bin/dvswitch-network-switcher.sh`)
- Network configuration guide (NETWORK_SWITCHING.md)
- Automatic sudoers configuration (no manual setup needed)

### Changed
- CGI script now returns `available_networks` array with configured networks
- CGI script detects current network from MMDVM_Bridge.ini
- Network section only displayed if multiple networks are configured
- Header displays current network alongside callsign and node

### Technical Details
- Network switching stops/starts MMDVM_Bridge service (takes 5-10 seconds)
- Reads BrandMeister, TGIF, DMRPlus, Other1, Other2 from var.txt
- Only displays networks that have both address and password configured
- Supports custom network names via other1_name and other2_name
- **BrandMeister**: Adds `Options=StartRef=TG;RelinkTime=15;` to maintain static TG connection
- **TGIF/Others**: Removes Options field as they don't use dynamic TGs

### Security
- Network switcher requires sudo access for www-data user
- Reads credentials from /var/lib/dvswitch/dvs/var.txt (root-only)
- No hardcoded passwords in scripts

### Compatibility
- Works with existing DVSwitch var.txt configuration
- No changes needed if user only has one network
- Backwards compatible with v1.4 installations

## [1.4.0] - 2026-01-23

### Added
- **Mode Switching**: One-click buttons to switch between DMR, YSF, P25, NXDN, and D-STAR modes
- **Auto Mode Detection**: Current mode automatically highlighted on page load
- Active mode indicator with highlighting
- Mode switching integrated into activity log

### Changed
- Reorganized interface with Mode Selection section between Quick Tune and Favorites
- Improved responsive layout for mode buttons on mobile
- CGI script now returns current mode in status

## [1.3.0] - 2026-01-18

### Added
- **Quick Tune**: Input field to instantly tune to any talkgroup without adding to favorites
- **Add to Favorites**: Web interface with modal dialog to add new talkgroups
- **Delete Favorites**: Hover over any favorite button to see delete (X) button
- Activity log shows all add/delete/tune operations in real-time

### Fixed
- Added automatic permission fix for favorites file during installation
- Favorites file now writable by Apache (www-data) user

### Changed
- Enhanced user interface with modal dialogs
- Improved user experience with hover effects on favorites
- Updated README with new feature documentation

## [1.2.0] - 2026-01-18

### Fixed
- CGI script now correctly parses favorites file with proper handling of `|||` delimiter
- Fixed callsign detection to properly parse DVSwitch status output
- Added node number detection and display in header
- Fixed carriage return handling in favorites file (Windows line endings)
- Fixed JSON output formatting issues in CGI script
- Improved error handling in CGI script

### Changed
- Rewrote favorites parsing to use sed instead of awk for better compatibility
- Callsign detection now uses DVSwitch show command as primary source
- Node number automatically detected from rpt.conf

## [1.1.0] - 2026-01-17

### Added
- Installation method using `sudo bash` to avoid noexec /tmp issues
- QUICKSTART.md for easy reference
- Clearer messaging about /tmp noexec issues

### Changed
- Updated installation instructions to use `sudo bash` as primary method
- Updated README.md with better installation instructions
- Simplified to one-liner installation only

## [1.0.0] - 2026-01-17

### Added
- Initial release
- Web-based control panel for DVSwitch
- Mode switching (DMR, YSF, P25, NXDN, D-STAR)
- Favorite talkgroups interface
- Real-time status updates every 3 seconds
- Activity logging
- Auto-configuration from DVSwitch favorites
- Responsive design for mobile and desktop
- Retro ham radio aesthetic with animated background
- One-click installer script
- Uninstaller script

### Security
- Command validation in CGI script
- Input sanitization
- Restricted command execution to dvswitch.sh only
