#!/bin/sh
#############################################
#  This tool help user to unlock there device bootloader without pc
#  
#############################################
# Exit on any error
set -e

# Install figlet if not present
if ! command -v figlet >/dev/null 2>&1; then
    echo "- Installing figlet"
    if ! pkg install figlet -y >/dev/null 2>&1; then
        echo "! ERROR : Failed to install figlet. Please check your package manager or internet connection."
        exit 1
    fi
fi

######## MENU OPTIONS  ##############
# Main menu loop
while true; do
    clear
    echo -e "- $(date)\e[96m"
    figlet "Termux"
    echo -e "\033[0m- \e[93mTermux Bootloader Unlock\033[0m"
    echo -e "- TOOL VERSION : 1.0 \e[93mbeta\033[0m"
    echo -e "- BUILD DATE   : $(date)"
    echo -e "- DEVELOPER    : \e[92m@Jonjeexe\033[0m "
    echo ""
    echo -e "-  \e[96mChoose Tools options\033[0m"
    echo -e "1. \e[93mUnlock bootloader MediaTek (Xiaomi)\033[0m"
    echo -e "2. \e[93mUnlock bootloader Snapdragon (Xiaomi)\033[0m"
    echo -e "3. \e[93mExit\033[0m"
    echo ""

    # Read and validate user input
    echo -n "[?] ENTER NUMBER : "
    read num
    if ! echo "$num" | grep -q '^[1-3]$'; then
        echo -e "\e[91mError: Invalid input. Please enter 1, 2, or 3.\033[0m"
        sleep 2
        continue
    fi
    # DATABASE
    case $num in
    1)
        echo -e "- \e[96mStart Unlocking bootloader of MediaTek\033[0m"
        echo ""
        
        # Check for connected devices
        id=$(termux-fastboot devices | awk '{print $1}')
        if [ -z "$id" ]; then
                echo -e "\e[91m- No device is connected in Fastboot mode.\033[0m"
                echo "- Try again"
                sleep 2
                continue
        fi
        echo "- \e[93mTarget device is connected\033[0m : $id"
        echo ""
        
       # Host device information
       echo -e "? \e[93mHost information\033[0m"
       echo -e "- Phone: $(getprop ro.product.brand) Android $(getprop ro.build.version.release)"
       echo -e "- Model: $(getprop ro.product.model)"
       
       # Get target devices information
       echo -e "? \e[93mTarget information\033[0m"
       echo ""
       termux-fastboot getvar product
       echo ""
       termux-fastboot oem get_token
       echo ""
       echo -n "- Enter Target product code : "
       read -r codename
       echo -n "- Enter Target token code : "
       read -r token
       echo -n "- Enter Mi account app data : "
       read -r data
       chmod +x get_token.sh
       echo ""
       ./get_token.sh --product=$codename --token=$token $data
       echo ""
       echo "- Copy the unlock token "
       echo -n "- Enter Unlock token : "
       read -r UNLOCK_TOKEN
       echo "$UNLOCK_TOKEN" | xxd -r -p > token.bin
       echo "- \e[96mUnlocking bootloader \033[0m"
       mi-fastboot stage token.bin && mi-fastboot oem unlock
       sleep 5
       ;;
       
      2)
        echo -e "- \e[96mStart Unlocking bootloader of Snapdragon\033[0m"
        echo ""
        
        # Check for connected devices
        id=$(termux-fastboot devices | awk '{print $1}')
        if [ -z "$id" ]; then
                echo -e "\e[91m- No device is connected in Fastboot mode.\033[0m"
                echo "- Try again"
                sleep 2
                continue
        fi
        echo "- \e[93mTarget device is connected\033[0m : $id"
        echo ""
        
       # Host device information
       echo -e "? \e[93mHost information\033[0m"
       echo -e "- Phone: $(getprop ro.product.brand) Android $(adb shell getprop ro.build.version.release)"
       echo -e "- Model: $(getprop ro.product.model)"
       
       # Get target devices information
       echo -e "? \e[93mTarget information\033[0m"
       echo ""
       termux-fastboot getvar product
       echo ""
       termux-fastboot getvar token
       echo ""
       echo -n "- Enter Target product code : "
       read -r codename
       echo -n "- Enter Target token code : "
       read -r token
       echo -n "- Enter Mi account app data : "
       read -r data
       chmod +x get_token.sh
       echo ""
       ./get_token.sh --product=$codename --token=$token $data
       echo ""
       echo "- Copy the unlock token "
       echo -n "- Enter Unlock token : "
       read -r UNLOCK_TOKEN
       echo "$UNLOCK_TOKEN" | xxd -r -p > token.bin
       echo "- \e[96mUnlocking bootloader \033[0m"
       termux-fastboot stage token.bin && termux-fastboot oem unlock
       sleep 10m
       continue
       ;;
       
       3)
            echo -e "- Exiting..."
            exit 0
            ;;
    esac
done