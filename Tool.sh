#!/bin/sh

# Exit on any error
set -e

# Check for required tools
for cmd in termux-fastboot xxd java timeout; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is not installed. Please install it (e.g., 'pkg install $cmd') and try again."
        exit 1
    fi
done

# Install figlet if not present
if ! command -v figlet >/dev/null 2>&1; then
    echo "- Installing figlet"
    if ! pkg install figlet -y >/dev/null 2>&1; then
        echo "Error: Failed to install figlet. Please check your package manager or internet connection."
        exit 1
    fi
fi

# Resolve script directory
PRG="$0"
while [ -h "$PRG" ]; do
    ls=$(ls -ld "$PRG")
    link=$(expr "$ls" : '.*-> \(.*\)$')
    if expr "$link" : '/.*' >/dev/null; then
        PRG="$link"
    else
        PRG=$(dirname "$PRG")/"$link"
    fi
done
PRGDIR=$(dirname "$PRG")

# Check for get_token.jar
if [ ! -f "$PRGDIR/get_token.jar" ]; then
    echo "Error: get_token.jar not found in $PRGDIR"
    exit 1
fi

# Function to get JAVA command
get_javacmd() {
    if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        JAVACMD="$JAVA_HOME/bin/java"
    else
        JAVACMD=$(which java)
    fi
    if [ ! -x "$JAVACMD" ]; then
        echo "Error: Java is not executable at $JAVACMD"
        exit 1
    fi
}

# Main menu loop
while true; do
    clear
    echo "- $(date)"
    figlet "Termux"
    echo -e "\033[0m- \e[93mTermux Bootloader Unlock\033[0m"
    echo -e "- Tool version : 1.0 \e[93mbeta\033[0m"
    echo -e "- Build date   : $(date)"
    echo -e "- Developer    : \e[92m@Jonjeexe\033[0m | Telegram \e[92m@OnionXProject\033[0m"
    echo ""
    echo -e "- \e[96mChoose Tools options\033[0m"
    echo -e "1. \e[93mUnlock bootloader MediaTek (Xiaomi)\033[0m"
    echo -e "2. \e[93mUnlock bootloader Snapdragon (Xiaomi)\033[0m"
    echo -e "3. \e[93mExit\033[0m"
    echo ""

    # Read and validate user input
    echo -n "[?] ENTER MODE NUMBER (1-3): "
    read num
    if ! echo "$num" | grep -q '^[1-3]$'; then
        echo -e "\e[91mError: Invalid input. Please enter 1, 2, or 3.\033[0m"
        sleep 2
        continue
    fi

    case $num in
        1)
            echo -e "- \e[96mStart Unlocking bootloader of MediaTek\033[0m"
            echo ""

            # Check for connected devices
            id=$(termux-fastboot devices | awk '{print $1}')
            if [ -z "$id" ]; then
                echo -e "\e[91m- No device connected in termux-fastboot mode.\033[0m"
                echo "- Please ensure device is in fastboot mode (e.g., 'adb reboot bootloader')."
                sleep 2
                continue
            fi
            echo "- Target device is connected: $id"
            echo ""

            # Try to get device info via ADB (if available)
            if command -v adb >/dev/null 2>&1 && adb devices | grep -q device; then
                echo -e "? Host information"
                echo -e "- Phone: $(adb shell getprop ro.product.brand) Android $(adb shell getprop ro.build.version.release)"
                echo -e "- Model: $(adb shell getprop ro.product.model)"
                echo ""
            else
                echo "- Note: ADB not available or device not in ADB mode. Skipping host info."
            fi

            # Get target information with timeout and debug
            echo -e "? Get Target information"
            echo "- Running termux-fastboot getvar product..."
            codename=$(timeout 10 termux-fastboot getvar product 2>&1 | grep -E "product:|ro.product.device" | awk '{print $2}' || echo "")
            echo "- Raw codename output: $codename"
            token=$(timeout 10 termux-fastboot oem get_token 2>&1 | grep "token:" | awk '{print $2}' || echo "")
            echo "- Raw token output: $token"

            if [ -z "$codename" ]; then
                echo -e "\e[91mError: Could not retrieve product codename. Ensure device is in fastboot mode and supports 'getvar product'.\033[0m"
                sleep 2
                continue
            fi
            if [ -z "$token" ]; then
                echo -e "\e[91mError: Could not retrieve unlock token. Ensure device supports 'oem get_token'.\033[0m"
                sleep 2
                continue
            fi
            echo "- Device codename: $codename"
            echo "- Device Token: $token"

            # Get Mi account data
            echo -n "Enter Mi account data: "
            read -r mi_account
            if [ -z "$mi_account" ]; then
                echo -e "\e[91mError: No Mi Account data provided.\033[0m"
                sleep 2
                continue
            fi

            # Perform unlock
            echo ""
            echo -e "- Unlocking Bootloader of $codename"
            get_javacmd
            jar_output=$("$JAVACMD" -jar "$PRGDIR/get_token.jar" "$codename" "$token" "$mi_account" 2>&1)
            if [ $? -ne 0 ]; then
                echo -e "\e[91mError: get_token.jar failed to execute. Output: $jar_output\033[0m"
                sleep 2
                continue
            fi

            if [ -z "$jar_output" ]; then
                echo -e "\e[93mWarning: get_token.jar produced no output. It may have written to a file or performed a silent operation.\033[0m"
            fi

            # Write token to file
            echo "$jar_output" | xxd -r -p > token.bin
            if [ ! -s token.bin ]; then
                echo -e "\e[91mError: Failed to create token.bin or file is empty.\033[0m"
                rm -f token.bin
                sleep 2
                continue
            fi

            # Unlock bootloader
            if timeout 10 termux-fastboot stage token.bin && timeout 10 termux-fastboot oem unlock; then
                echo -e "\e[92m- Bootloader unlocked successfully!\033[0m"
                rm -f token.bin
                exit 0
            else
                echo -e "\e[91mError: Failed to unlock bootloader.\033[0m"
                rm -f token.bin
                sleep 2
                continue
            fi
            ;;
        2)
            echo -e "- \e[96mStart Unlocking bootloader of Snapdragon\033[0m"
            echo ""

            # Check for connected devices
            id=$(termux-fastboot devices | awk '{print $1}')
            if [ -z "$id" ]; then
                echo -e "\e[91m- No device connected in termux-fastboot mode.\033[0m"
                echo "- Please ensure device is in fastboot mode (e.g., 'adb reboot bootloader')."
                sleep 2
                continue
            fi
            echo "- Target device is connected: $id"
            echo ""

            # Try to get device info via ADB (if available)
            
                echo -e "? Host information"
                echo -e "- Phone: $(getprop ro.product.brand) Android $(adb shell getprop ro.build.version.release)"
                echo -e "- Model: $(getprop ro.product.model)"
                echo ""
            

            # Get target information with timeout and debug
            echo -e "? Get Target information"
            echo "- Running termux-fastboot getvar product..."
            codename=$(timeout 10 termux-fastboot getvar product 2>&1 | grep -E "product:|ro.product.device" | awk '{print $2}' || echo "")
            echo "- Raw codename output: $codename"
            token=$(timeout 10 termux-fastboot getvar token 2>&1 | grep "token:" | awk '{print $2}' || echo "")
            echo "- Raw token output: $token"

            if [ -z "$codename" ]; then
                echo -e "\e[91mError: Could not retrieve product codename. Ensure device is in fastboot mode and supports 'getvar product'.\033[0m"
                sleep 2
                continue
            fi
            if [ -z "$token" ]; then
                echo -e "\e[91mError: Could not retrieve unlock token. Ensure device supports 'getvar token'.\033[0m"
                sleep 2
                continue
            fi
            echo "- Device codename: $codename"
            echo "- Device Token: $token"

            # Get Mi account data
            echo -n "Enter Mi account data: "
            read -r mi_account
            if [ -z "$mi_account" ]; then
                echo -e "\e[91mError: No Mi Account data provided.\033[0m"
                sleep 2
                continue
            fi

            # Perform unlock
            echo ""
            echo -e "- Unlocking Bootloader of $codename"
            get_javacmd
            jar_output=$("$JAVACMD" -jar "$PRGDIR/get_token.jar" "$codename" "$token" "$mi_account" 2>&1)
            if [ $? -ne 0 ]; then
                echo -e "\e[91mError: get_token.jar failed to execute. Output: $jar_output\033[0m"
                sleep 2
                continue
            fi

            if [ -z "$jar_output" ]; then
                echo -e "\e[93mWarning: get_token.jar produced no output. It may have written to a file or performed a silent operation.\033[0m"
            fi

            # Write token to file
            echo "$jar_output" | xxd -r -p > token.bin
            if [ ! -s token.bin ]; then
                echo -e "\e[91mError: Failed to create token.bin or file is empty.\033[0m"
                rm -f token.bin
                sleep 2
                continue
            fi

            # Unlock bootloader
            if timeout 10 termux-fastboot stage token.bin && timeout 10 termux-fastboot oem unlock; then
                echo -e "\e[92m- Bootloader unlocked successfully!\033[0m"
                rm -f token.bin
                exit 0
            else
                echo -e "\e[91mError: Failed to unlock bootloader.\033[0m"
                rm -f token.bin
                sleep 2
                continue
            fi
            ;;
        3)
            echo -e "- Exiting..."
            exit 0
            ;;
    esac
done