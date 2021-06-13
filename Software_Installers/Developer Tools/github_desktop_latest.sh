#!/bin/zsh
###################################
## Author: Kieran S.
## GitHub: ktschimm-mtu
## Date: June 13, 2021
## Application: GitHub Desktop
## Script License: GNU GPLv3
###################################

###################################
## Installation Variable(s)
###################################
appName="GitHub Desktop"

###################################
## Logging Setup
###################################
logDir="/Library/Logs/Install/"
logFile="/Library/Logs/Install/GitHub Desktop.log"

# Set coloring for logging.
red=$(/usr/bin/tput setaf 1)
green=$(/usr/bin/tput setaf 2)
yellow=$(/usr/bin/tput setaf 3)
blue=$(/usr/bin/tput setaf 6)
reset=$(/usr/bin/tput sgr0)

# If the logging directory doesn't exist, create it and set permissions.
if [ ! -d "${logDir}" ]; then
    /bin/mkdir ${logDir}
    /usr/sbin/chown -R root:wheel "${logDir}"
    /bin/chmod 755 "${logDir}"

    # If the logging file doesn't exist, then create it and set permissions.
    if [ ! -f "${logFile}" ]; then
        /usr/bin/touch ${logFile}
        /bin/chmod 644 "${logFile}"
    fi

fi

# Initialize the log.
echo "\n###########################################
## Installing: ${appName} 
## Date: $(/bin/date)
###########################################" | /usr/bin/tee -a "${logFile}"

writeToLog() {
    # Color code the messages based on their type.
    if [[ ${1} = *"[INFO]"* ]]; then
        # Write info to application install log file.
        echo "${blue}"$(/bin/date): "${1}" | /usr/bin/tee -a "${logFile}"
    elif [[ ${1} = *"[ALERT]"* ]]; then
        # Write to application install log file.
        echo "${yellow}"$(/bin/date): "${1}" | /usr/bin/tee -a "${logFile}"
    elif [[ ${1} = *"[SUCCESS]"* ]]; then   
        # Write to application install log file.
        echo "${green}"$(/bin/date): "${1}" | /usr/bin/tee -a "${logFile}"
    elif [[ ${1} = *"[FAILURE]"* ]]; then
        # Write to application install log file.
        echo "${red}"$(/bin/date): "${1}" | /usr/bin/tee -a "${logFile}"
    fi
}

###################################
## Installation Setup
###################################

# Starting installation.
writeToLog "[INFO] Installation process starting..."

# Create the download directory.
/bin/mkdir -p "/tmp/${appName}/"
writeToLog "[INFO] Created application directory..."

# Download the required ZIP for the application.
if [[ $(/usr/sbin/sysctl -n machdep.cpu.brand_string | /usr/bin/grep "Apple") ]]; then
    # M1 version of the application.
    writeToLog "[INFO] Computer has Apple Silicon (M1) processor, downloading ${appName}..."
    /usr/bin/curl -sL -o "/tmp/${appName}/${appName}.zip" "https://central.github.com/deployments/desktop/desktop/latest/darwin-arm64"
else
    # Intel version of the application.
    writeToLog "[INFO] Computer has Intel processor, downloading ${appName}..."
    /usr/bin/curl -sL -o "/tmp/${appName}/${appName}.zip" "https://central.github.com/deployments/desktop/desktop/latest/darwin"
fi

###################################
## Installation
###################################

# Close and delete the old application version.
if [ -d "/Applications/${appName}.app" ]; then
/bin/ps aux | /usr/bin/grep -v grep | /usr/bin/grep "${appName}".app
    if [ "$?" -eq 0 ]; then
        writeToLog "[ALERT] Application is running, attempting to close..."
        /usr/bin/killall ${appName}
        writeToLog "[INFO] Application closed, continuing with installation..."
    fi
    /bin/rm -rf "/Applications/${appName}.app"
    writeToLog "[INFO] Application deleted..."
fi

# Unzip the application to the applications directory.
writeToLog "[INFO] Installing application..."
/usr/bin/unzip "/tmp/${appName}/${appName}.zip" -d "/Applications/"

# Set the permissions on the application.
writeToLog "[INFO] Setting application permissions..."
/usr/sbin/chown -R root:wheel "/Applications/${appName}.app"
/bin/chmod -R 755 "/Applications/${appName}.app"

# Set the quarantine flags on the applications.
writeToLog "[INFO] Updating quarantine status..."
/usr/bin/xattr -d -r com.apple.quarantine "/Applications/${appName}.app"

###################################
## Cleanup
###################################

# Delete the install directory and DMG.
writeToLog "[INFO] Removing installation media..."
/bin/rm -rf "/tmp/${appName}"

# Check installation status.
if [ -d "/Applications/${appName}.app" ]; then
    # Application installation successful.
    writeToLog "[SUCCESS] Successfully installed application!"
    # Reset terminal coloring.
    echo "${reset}"
    exit 0
else
    # Application installation failed.
    writeToLog "[FAILURE] Failed to install application!"
    # Reset terminal coloring.
    echo "${reset}"
    exit 1
fi
