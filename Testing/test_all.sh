#!/bin/zsh
###################################
## Author: Kieran S.
## GitHub: ktschimm-mtu
## Date: August 19, 2021
## Updated:
## Script License: GNU GPLv3
###################################

# Require root or sudo.
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Please run with sudo."
    exit 1
fi

# Get the username of the logged in user.
currentUser=$(/usr/bin/stat -f %Su /dev/console)

# Declare Variables.
testingDir="/tmp/installer_testing/"

# Create the testing directory.
/bin/mkdir -p ${testingDir}

# Get the path to the script directory.
echo "Enter full path to Software_Installer directory (Ex. /Development/macOS_Admin_Scripts/Software_Installers/): "
read scriptDirectory

# Copy the contents of the script files to the testing directory.
/usr/bin/find ${scriptDirectory} -name 'Templates' -prune -o -name '*.sh' -exec /bin/cp {} ${testingDir} \;

# Change permissions on all scripts.
/bin/chmod +x ${testingDir}/*.sh

# Run all scripts.
for scripts in ${testingDir}/*.sh; do
    /bin/zsh "$scripts"
done

# Delete the testing directory.
/bin/rm -rf ${testingDir}

# Open the log directory after everything ran.
/usr/bin/open "/Users/${currentUser}/Logs/Install"

exit 0
