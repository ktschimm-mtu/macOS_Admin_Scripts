#!/bin/zsh
###################################
## Author: Kieran S.
## GitHub: ktschimm-mtu
## Date: July 10, 2021
## Application: FileZilla
## Script License: GNU GPLv3
###################################

###################################
## Installation Variable(s)
###################################
appName="FileZilla"
executionName="filezilla"
appVers=$(/usr/bin/curl -s https://filezilla-project.org/download.php\?show_all\=1 | /usr/bin/grep "<p>" | /usr/bin/head -3 | /usr/bin/grep -Eo '[0-9,.]{1,}')
appSHA=$(/usr/bin/curl -s -L https://download.filezilla-project.org/client/${appName}_${appVers}.sha512 | grep "${appName}_${appVers}_macosx-x86.app.tar.bz2" | sed 's/*.*//')

###################################
## Logging Setup
###################################
logDir="/Library/Logs/Install/"
logFile="/Library/Logs/Install/FileZilla.log"

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
## Cleaning and Validation Setup
###################################

cleanAndValidate() {
    # Delete the installation resources.
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
}

###################################
## Installation Setup
###################################

# Starting installation.
writeToLog "[INFO] Installation process starting..."

# Create the download directory.
/bin/mkdir -p "/tmp/${appName}/"
writeToLog "[INFO] Created application directory..."

# Download the required tar file for the application.
writeToLog "[INFO] Downloading ${appName}..."
/usr/bin/curl -sL -o "/tmp/${appName}/${appName}_${appVers}_macosx-x86.app.tar.bz2" "https://download.filezilla-project.org/client/${appName}_${appVers}_macosx-x86.app.tar.bz2"

# Calculate the SHA512 for the tar file.
writeToLog "[INFO] Calculating SHA512 for ${appName}..."
fileSHA=$(openssl sha512 /tmp/${appName}/${appName}_${appVers}_macosx-x86.app.tar.bz2 | awk '{print $2}')

# Compare the SHA from the developer and the SHA of the downloaded file.
if [ "${appSHA}"=="${fileSHA}" ]; then
    writeToLog "[INFO] The developer SHA and the download SHA match, continuing installation..."
else
    writeToLog "[ALERT] The developer SHA and the download SHA do not match, cancelling installation..."
    cleanAndValidate
fi

###################################
## Installation
###################################

# Close and delete the old application version.
if [ -d "/Applications/${appName}.app" ]; then
    /bin/ps aux | /usr/bin/grep -v grep | /usr/bin/grep "${appName}".app
    if [ "$?" -eq 0 ]; then
        writeToLog "[ALERT] Application is running, attempting to close..."
        /usr/bin/killall ${executionName}
        writeToLog "[INFO] Application closed, continuing with installation..."
    fi
    /bin/rm -rf "/Applications/${appName}.app"
    writeToLog "[INFO] Application deleted..."
fi

# Copy the application to /Applications/.
writeToLog "[INFO] Installing application..."
/usr/bin/tar -xf "/tmp/${appName}/${appName}_${appVers}_macosx-x86.app.tar.bz2" -C "/Applications/"

# Set the permissions on the application.
writeToLog "[INFO] Setting application permissions..."
/usr/sbin/chown -R root:wheel "/Applications/${appName}.app"
/bin/chmod -R 755 "/Applications/${appName}.app"

# Set the quarantine flags on the applications.
writeToLog "[INFO] Updating quarantine status..."
/usr/bin/xattr -d -r com.apple.quarantine "/Applications/${appName}.app"

# Clean up install files, reset the shell, and validate the install.
cleanAndValidate
