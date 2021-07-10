# Templates
The templates folder contains a few different configurations relating to the installer section. If you have an application that has an accessible SHA, please look at the [FileZilla Installer](/Software_Installers/FTP%20Software/filezilla_latest.sh) for an example of how to implement the check.

## Available Templates
* PKG: For applications that come from their developers as a package.
* DMG: For applications that come from their developers as a disk image.
* TAR: For applications that come from their developers as an archive.
* ZIP: For applications that come from their developers as a ZIP file.

## Template Instructions

1. Fill out the header:
```
###################################
## Author: <Your Name>
## GitHub: <GitHub ID>
## Date: <When script was written>
## Updated: <When script was updated>
## Application: <App being installed>
## Script License: GNU GPLv3
###################################
```
2. Add the application name in two places:
    * Line 14
    * Line 20
```
###################################
## Installation Variable(s)
###################################
appName="<APP NAME>" <--- Line 14

###################################
## Logging Setup
###################################
logDir="/Library/Logs/Install/"
logFile="/Library/Logs/Install/<APP NAME>.log" <--- Line 20
```
3. Add the download url with necessary modifications:
    * Line 105
    * Modifications may include:
        * App Name variable (appName)
        * App Version variable (appVers)
```
###################################
## Installation Setup
###################################

# Starting installation.
writeToLog "[INFO] Installation process starting..."

# Create the download directory.
/bin/mkdir -p "/tmp/${appName}/"
writeToLog "[INFO] Created application directory..."

# Download the required DMG for the application.
writeToLog "[INFO] Downloading ${appName}..."
/usr/bin/curl -sL -o "/tmp/${appName}/${appName}.dmg" "<DOWNLOAD URL>" <--- Line 105
```