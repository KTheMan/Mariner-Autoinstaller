#!/usr/bin/env bash

# filename: mariner.sh

function info { echo -e "\e[32m[info] $*\e[39m"; }
function warn  { echo -e "\e[33m[warn] $*\e[39m"; }
function error { echo -e "\e[31m[error] $*\e[39m"; exit 1; }

if ! [ "$(id -u)" = 0 ]; then
    warn "This script needs to be run as root." >&2
    exit 1
fi

# check if the reboot flag file exists. 
# We created this file before rebooting.
if [ ! -f ./resume-mariner ]; then
    warn "running script for the first time.."
    
    # run your scripts here
    info
    info "Welcome to Kenzillla's Mariner+Samba Auto-Installer!"
    sleep .1
    info "..."

    sleep 1

    while true
    do
        read -r -p "Would you like to expand the filesystem to the full size of the SD card? [Y/n] " input
    
        case $input in
            [yY][eE][sS]|[yY])
        info
        info "Expanding the filesystem"
        sleep 1
        sudo raspi-config nonint do_expand_rootfs >/dev/null
        break
        ;;
            [nN][oO]|[nN])
        break
                ;;
            *)
        warn "Invalid input..."
        esac
    done


    warn "It is a good idea to change your password from the default"
    while true
    do
        read -r -p "Change now? [Y/n] " input
    
        case $input in
            [yY][eE][sS]|[yY])
        info
        echo "$(passwd pi)"
        break
        ;;
            [nN][oO]|[nN])
        break
                ;;
            *)
        warn "Invalid input..."
        esac
    done

    info ""
    while true
    do
        read -r -p "Change hostname? [Y/n] " input

        case $input in
            [yY][eE][sS]|[yY])
        read -r -p "Enter a new hostname (Default 'raspberrypi'): " -e -i "mariner"  hostname
        sudo raspi-config nonint do_hostname "$hostname"
        info "You can now access this Pi from $hostname.local"
        break
        ;;
            [nN][oO]|[nN])
        break
                ;;
            *)
        warn "Invalid input..."
        esac
    done

    # create a flag file to check if we are resuming from reboot.
    sudo touch ./resume-mariner

    info "rebooting.."
    # reboot here
    sudo reboot
    sleep 5

else 
    warn "resuming script after reboot.."
    
    # remove the temporary file that we created to check for reboot
    sudo rm -f ./resume-mariner
    # continue with rest of the script
    
    info "Adding Mariner's PPA repository"
    curl -sL gpg.l9o.dev | sudo apt-key add -
    echo "deb https://ppa.l9o.dev/raspbian ./" | sudo tee /etc/apt/sources.list.d/l9o.list

    info "Updating repositories and upgrade software; this could take a long time"
    sudo apt-get -qq update >/dev/null && sudo apt-get -qq -y upgrade >/dev/null

    info
    info "Setting up Mariner prerequisites"
    echo "dtoverlay=dwc2,dr_mode=peripheral" >> /boot/config.txt
    echo "enable_uart=1" >> /boot/config.txt
    sudo sed -i 's/console=serial0,115200 //g' /boot/cmdline.txt
    echo -n " modules-load=dwc2" >> /boot/cmdline.txt

    info
    info "Setting up Pi-USB; this could take several minutes"
    sudo dd bs=1M if=/dev/zero of=/piusb.bin count=4096
    sudo mkdosfs /piusb.bin -F 32 -I
    sudo mkdir /mnt/usb_share
    echo "/piusb.bin            /mnt/usb_share  vfat    users,umask=000   0       2 " >> /etc/fstab

    sudo mount -a

    sudo sed -i 's/exit 0//g' /etc/rc.local

    echo '/bin/sleep 5
    modprobe g_mass_storage file=/piusb.bin removable=1 ro=0 stall=0
    /sbin/iwconfig wlan0 power off
    exit 0' >> /etc/rc.local

    sudo systemctl stop serial-getty@ttyS0
    sudo systemctl disable serial-getty@ttyS0

    info ""
    info "Setting up Sambashare; this could take a long time"
    sudo apt-get -y install samba winbind -y

    read -pr "Enter a short description of your printer, like the model: "  model
    echo "[USB_Share]
    comment = $model
    path = /mnt/usb_share/
    browseable = Yes
    writeable = Yes
    only guest = no
    create mask = 0777
    directory mask = 0777
    public = yes
    read only = no
    force user = root
    force group = root" >> /etc/samba/smb.conf

    info ""
    info "Installing Mariner"
    sudo apt-get install mariner3d

    while true
    do
        read -r -p "Reboot now? [Y/n] " input
    
        case $input in
            [yY][eE][sS]|[yY])
        warn "Rebooting in 5 seconds"
        sleep 5
        echo "$(sudo reboot)"
        break
        ;;
            [nN][oO]|[nN])
        break
                ;;
            *)
        warn "Invalid input..."
        esac
    done
fi
