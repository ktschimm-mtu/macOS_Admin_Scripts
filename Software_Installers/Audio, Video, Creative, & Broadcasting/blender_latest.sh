#!/bin/zsh
###################################
## Author: Kieran S.
## GitHub: ktschimm-mtu
## Date: July 12, 2021
## Updated: August 16, 2021
## Application: Blender
## Script License: GNU GPLv3
###################################

###################################
## Installation Variable(s)
###################################
appName="Blender"
appVers=$(/usr/bin/curl -s -L https://www.blender.org/download/ | /usr/bin/grep "Download Blender" | /usr/bin/head -2 | /usr/bin/tail -1 | /usr/bin/awk '{print $NF}')
dirVers=$(/usr/bin/curl -s -L https://www.blender.org/download/ | /usr/bin/grep "Download Blender" | /usr/bin/head -2 | /usr/bin/tail -1 | /usr/bin/awk '{print $NF}' | /usr/bin/cut -f1,2 -d'.')

# Initialize appInstalled and abortFlag variables.
appInstalled=false
abortFlag=false

###################################
## Logging Setup
###################################
logDir="/Library/Logs/Install/"
logFile="/Library/Logs/Install/<APP NAME>.log"

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

###################################
## Logging Functions
###################################

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

# Set file tag for quick viewing of if an install succeeded, failed, or didn't finish.
addTag() {
    # Tag the log file with the correct status color.
    # Color is passed as a string with the first letter of the color capitalized, such as: Red, Yellow, Green, etc.
    /usr/bin/xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>'${1}'</string></array></plist>' "$logFile"
}

# Remove the file tag (for initial status).
removeTag() {
    # Delete the tagging information from the log file.
    /usr/bin/xattr -cr "$logFile"
}

###################################
## Cleaning and Validation Setup
###################################

cleanAndValidate() {
    # Delete the installation resources.
    writeToLog "[INFO] Removing installation media..."
    /bin/rm -rf "/tmp/${appName}"
    /usr/bin/hdiutil detach ${diskImage} >/dev/null 2>&1

    # Determine and set installation status.
    if [ -d "/Applications/${appName}.app" ]; then
        appInstalled=true
    fi

    # Check installation status.
    if [ "$appInstalled" = true ] && [ "$abortFlag" = false ]; then
        # Application installation successful.
        writeToLog "[SUCCESS] Successfully installed application!"
        writeToLog "[INFO] Status Flags: App Installed Flag: ${appInstalled}, Abort Flag: ${abortFlag}"
        # Remove running status tag, add success tag.
        removeTag
        addTag "Green"
        # Reset terminal coloring.
        echo "${reset}"
        exit 0
    else
        # Application installation failed.
        writeToLog "[FAILURE] Failed to install application!"
        writeToLog "[INFO] Status Flags: App Installed Flag: ${appInstalled}, Abort Flag: ${abortFlag}"
        # Remove running status tag, add failure tag.
        removeTag
        addTag "Red"
        # Reset terminal coloring.
        echo "${reset}"
        exit 1
    fi
}

###################################
## Installation Setup
###################################

# Starting installation.
addTag "Yellow"
writeToLog "[INFO] Installation process starting..."

# Create the download directory.
/bin/mkdir -p "/tmp/${appName}/"
writeToLog "[INFO] Created application directory..."

# Download the required DMG for the application.
if [[ $(/usr/sbin/sysctl -n machdep.cpu.brand_string | /usr/bin/grep "Apple") ]]; then
    # M1 version of the application.
    writeToLog "[INFO] Computer has Apple Silicon (M1) processor, downloading ${appName}..."
    /usr/bin/curl -sL -o "/tmp/${appName}/${appName}.dmg" "https://download.blender.org/release/Blender${dirVers}/blender-${appVers}-macos-arm64.dmg"
    writeToLog "[INFO] Downloading developer hash file..."
    appSHA=$(/usr/bin/curl -s -L https://download.blender.org/release/Blender${dirVers}/blender-${appVers}.sha256 | /usr/bin/grep "blender-${appVers}-macos-arm64.dmg" | /usr/bin/awk '{print $1}')
else
    # Intel version of the application.
    writeToLog "[INFO] Computer has Intel processor, downloading ${appName}..."
    /usr/bin/curl -sL -o "/tmp/${appName}/${appName}.dmg" "https://download.blender.org/release/Blender${dirVers}/blender-${appVers}-macos-x64.dmg"
    writeToLog "[INFO] Downloading developer hash file..."
    appSHA=$(/usr/bin/curl -s -L https://download.blender.org/release/Blender${dirVers}/blender-${appVers}.sha256 | /usr/bin/grep "blender-${appVers}-macos-x64.dmg" | /usr/bin/awk '{print $1}')
fi

# Calculate the SHA256 for the file.
writeToLog "[INFO] Calculating SHA256 for ${appName}..."
fileSHA=$(openssl sha256 /tmp/${appName}/${appName}.dmg | awk '{print $2}')

# Compare the SHA from the developer and the SHA of the downloaded file.
if [ "${appSHA}" = "${fileSHA}" ]; then
    writeToLog "[INFO] The developer SHA and the download SHA match, continuing installation..."
else
    writeToLog "[ALERT] The developer SHA and the download SHA do not match, cancelling installation..."
    abortFlag=true
    cleanAndValidate
fi

###################################
## Installation
###################################

# Close and delete the old application version.
if [ -d "/Applications/${appName}.app" ]; then
    /bin/ps aux | /usr/bin/grep -v grep | /usr/bin/grep "${appName}".app >/dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        writeToLog "[ALERT] Application is running, attempting to close..."
        /usr/bin/killall ${appName}
        writeToLog "[INFO] Application closed, continuing with installation..."
    fi
    /bin/rm -rf "/Applications/${appName}.app"
    writeToLog "[INFO] Application deleted..."
fi

# Detach any previously mounted disk images for the application.
/usr/bin/find "/Volumes/" -maxdepth 1 -name "${appName}*" -exec /usr/bin/hdiutil detach {} \; >/dev/null 2>&1

# Mount the application.
diskImage=$(/usr/bin/hdiutil attach "/tmp/${appName}/${appName}.dmg" -readonly -nobrowse -noautoopen -noverify | /usr/bin/grep "${appName}" | /usr/bin/cut -f 3-)

# Copy the application to /Applications/.
writeToLog "[INFO] Installing application..."
/usr/bin/ditto "${diskImage}/${appName}.app" "/Applications/${appName}.app"

# Set the permissions on the application.
writeToLog "[INFO] Setting application permissions..."
/usr/sbin/chown -R root:wheel "/Applications/${appName}.app"
/bin/chmod -R 755 "/Applications/${appName}.app"

# Set the quarantine flags on the applications.
writeToLog "[INFO] Updating quarantine status..."
/usr/bin/xattr -d -r com.apple.quarantine "/Applications/${appName}.app"

# Clean up install files, reset the shell, and validate the install.
cleanAndValidate
