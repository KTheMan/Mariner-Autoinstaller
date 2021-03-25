# Mariner Autoinstaller

This script is intended for a fresh Rasbian Lite installation on a Raspberry Pi Zero

It will expand the filesystem to the full size of your SD card, install Mariner, set up a folder on the Pi as a USB drive, and create a sambashare.

### Download
Either from this Github or using
`wget https://raw.githubusercontent.com/KTheMan/Mariner-Autoinstaller/main/mariner.sh`

### Prepare for execution
`sudo chmod +x ./mariner.sh`

At the top of the script you can see
`version="0.1.1-1"`
Make sure that reflects the release from [luizribeiro/mariner](https://github.com/luizribeiro/mariner/releases) that you want to have downloaded and installed

### Execute
`sudo bash ./mariner.sh`

Follow the prompts in the script, reboot, and run once more.
You should see a different set of prompts on the second run
