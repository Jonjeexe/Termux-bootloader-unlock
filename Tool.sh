#!/bin/sh

# Log file for debugging
LOGFILE="$HOME/bootloader_unlock.log"
echo "Starting bootloader unlock script at $(date)" > "$LOGFILE"

# Function to log messages
log() {
    echo "$1" | tee -a "$LOGFILE"
}

# Check for required tools
for cmd in termux-fastboot xxd java timeout adb; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "\e[91mError: $cmd is not installed. Please install it with 'pkg install $cmd' and try again.\033[0m"
        echo "Press Enter to return to the menu..."
        read -r
        exit 1  # Exit only for missing tools, as they’re critical
    fi
done

# Install figlet if not present
if ! command -v figlet >/dev/null 2>&1; then
    log "- Installing figlet"
    if ! pkg install figlet -y >> "$LOGFILE" 2>&1; then
        log "\e[91mError: Failed to install figlet. Please check your package manager or internet connection.\033[0m"
        echo "Press Enter to return to the menu..."
        read -r
        return 1
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
    log "\e[91mError: get_token.jar not found in $PRGDIR\033[0m"
    echo "Press Enter to return to the menu..."
    read -r
    return 1
fi

# Function to get JAVA command
get_javacmd() {
    if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        JAVACMD="$JAVA_HOME/bin/java"
    else
        JAVACMD=$(which java)
    fi
    if [ ! -x "$JAVACMD" ]; then
        log "\e[91mError: Java is not executable at $JAVACMD\033[0m"
        echo "Press Enter to return to the menu..."
        read -r
        return 1
    fi
    # Verify Java version compatibility
    java_version=$("$JAVACMD" -version 2>&1 | head -n 1 | awk '{print $3}' | tr -d '"')
    if [ -z "$java_version" ]; then
        log "\e[91mError: Failed to detect Java version.\033[0m"
        echo "Press Enter to return to the menu..."
        read -r
        return 1
    fi
    log "- Using Java version: $java_version"
    echo "- Using Java version: $java_version"
    return 0
}

# Function to check device connection with retries
check_device() {
    local retries=3
    local count=0
    local id=""
    while [ $count -lt $retries ]; do
        id=$(timeout 5 termux-fastboot devices 2>> "$LOGFILE" | awk '{print $1}')
        if [ -n "$id" ]; then
            log "- Target device connected: $id"
            echo "- Target device connected: $id"
            echo "$id"
            return 0
        fi
        log "- No device detected, retrying ($((count+1))/$retries)..."
        echo "- No device detected, retrying ($((count+1))/$retries)..."
        sleep 2
        count=$((count+1))
    done
    log "\e[91mError: No device connected in fastboot mode after $retries retries.\033[0m"
    log "Please ensure device is in fastboot mode (e.g., 'adb reboot bootloader' or hold Volume Down + Power)."
    echo "\e[91mError: No device connected in fastboot mode after $retries retries.\033[0m"
    echo "Please ensure device is in fastboot mode (e.g., 'adb reboot bootloader' or hold Volume Down + Power)."
    echo "Press Enter to return to the menu..."
    read -r
    return 1
}

# Function to get codename with fallback
get_codename() {
    local output raw_output
    # Capture full output for debugging
    raw_output=$(timeout 10 termux-fastboot getvar product 2>&1 || echo "")
    log "- Full raw output (getvar product): $raw_output"
    echo "- Full raw output (getvar product):"
    echo "$raw_output"
    output=$(echo "$raw_output" | grep -E "product:|ro.product.device|device:" | awk '{print $2}' || echo "")
    log "- Parsed codename: $output"
    echo "- Parsed codename: $output"
    if [ -n "$output" ]; then
        echo "$output"
        return 0
    fi
    # Fallback: try getvar all
    log "- Fallback: trying 'getvar all' for codename..."
    echo "- Fallback: trying 'getvar all' for codename..."
    raw_output=$(timeout 10 termux-fastboot getvar all 2>&1 || echo "")
    log "- Full raw output (getvar all): $raw_output"
    echo "- Full raw output (getvar all):"
    echo "$raw_output"
    output=$(echo "$raw_output" | grep -E "product:|ro.product.device|device:" | awk '{print $2}' || echo "")
    log "- Parsed codename (fallback): $output"
    echo "- Parsed codename (fallback): $output"
    if [ -z "$output" ]; then
        log "\e[91mError: Could not retrieve product codename. Ensure device is in fastboot mode and supports 'getvar product' or 'getvar all'.\033[0m"
        log "Try rebooting to fastboot mode with 'adb reboot bootloader' or manually (Volume Down + Power)."
        echo "\e[91mError: Could not retrieve product codename. Ensure device is in fastboot mode and supports 'getvar product' or 'getvar all'.\033[0m"
        echo "Try rebooting to fastboot mode with 'adb reboot bootloader' or manually (Volume Down + Power)."
        echo "Press Enter to return to the menu..."
        read -r
        return 1
    fi
    echo "$output"
    return 0
}

# Function to get token with fallback
get_token() {
    local chipset=$1
    local output raw_output
    if [ "$chipset" = "mediatek" ]; then
        raw_output=$(timeout 10 termux-fastboot oem get_token 2>&1 || echo "")
        log "- Full raw output (oem get_token): $raw_output"
        echo "- Full raw output (oem get_token):"
        echo "$raw_output"
        output=$(echo "$raw_output" | grep -E "token:|oem token:" | awk '{print $2}' || echo "")
        log "- Parsed token: $output"
        echo "- Parsed token: $output"
        if [ -n "$output" ]; then
            echo "$output"
            return 0
        fi
        # Fallback: try getvar token
        log "- Fallback: trying 'getvar token' for MediaTek..."
        echo "- Fallback: trying 'getvar token' for MediaTek..."
        raw_output=$(timeout 10 termux-fastboot getvar token 2>&1 || echo "")
        log "- Full raw output (getvar token): $raw_output"
        echo "- Full raw output (getvar token):"
        echo "$raw_output"
        output=$(echo "$raw_output" | grep -E "token:|oem token:" | awk '{print $2}' || echo "")
        log "- Parsed token (fallback): $output"
        echo "- Parsed token (fallback): $output"
    else
        raw_output=$(timeout 10 termux-fastboot getvar token 2>&1 || echo "")
        log "- Full raw output (getvar token): $raw_output"
        echo "- Full raw output (getvar token):"
        echo "$raw_output"
        output=$(echo "$raw_output" | grep -E "token:|oem token:" | awk '{print $2}' || echo "")
        log "- Parsed token: $output"
        echo "- Parsed token: $output"
        if [ -n "$output" ]; then
            echo "$output"
            return 0
        fi
        # Fallback: try oem get_token
        log "- Fallback: trying 'oem get_token' for Snapdragon..."
        echo "- Fallback: trying 'oem get_token' for Snapdragon..."
        raw_output=$(timeout 10 termux-fastboot oem get_token 2>&1 || echo "")
        log "- Full raw output (oem get_token): $raw_output"
        echo "- Full raw output (oem get_token):"
        echo "$raw_output"
        output=$(echo "$raw_output" | grep -E "token:|oem token:" | awk '{print $2}' || echo "")
        log "- Parsed token (fallback): $output"
        echo "- Parsed token (fallback): $output"
    fi
    if [ -z "$output" ]; then
        log "\e[91mError: Could not retrieve unlock token. Ensure device supports '${chipset}' token retrieval commands.\033[0m"
        log "Check Xiaomi's Mi Unlock documentation for your device model."
        echo "\e[91mError: Could not retrieve unlock token. Ensure device supports '${chipset}' token retrieval commands.\033[0m"
        echo "Check Xiaomi's Mi Unlock documentation for your device model."
        echo "Press Enter to return to the menu..."
        read -r
        return 1
    fi
    echo "$output"
    return 0
}

# Main menu loop
while true; do
    clear
    echo "- $(date)"
    figlet "Termux" 2>> "$LOGFILE"
    echo -e "\033[0m- \e[93mTermux Bootloader Unlock\033[0m"
    echo -e "- Tool version : 1.0 \e[93mbeta\033[0m"
    echo -e "- Build date   : $(date)"
    echo -e "- Developer    : \e[92m@Jonjeexe\033[0m | Telegram \e[92m@OnionXProject\033[0m"
    echo -e "- Log file     : $LOGFILE"
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
        log "\e[91mError: Invalid input. Please enter 1, 2, or 3.\033[0m"
        echo "\e[91mError: Invalid input. Please enter 1, 2, or 3.\033[0m"
        echo "Press Enter to continue..."
        read -r
        continue
    fi

    case $num in
        1|2)
            chipset="mediatek"
            [ "$num" = "2" ] && chipset="snapdragon"
            log "- \e[96mStart Unlocking bootloader of $chipset\033[0m"
            echo "- \e[96mStart Unlocking bootloader of $chipset\033[0m"
            echo ""

            # Check for connected devices
            id=$(check_device)
            if [ $? -ne 0 ]; then
                continue
            fi

            # Try to get device info via ADB (if available)
            
                log "? Host information"
                echo "? Host information"
                brand=$(getprop ro.product.brand 2>> "$LOGFILE" || echo "Unknown")
                version=$(getprop ro.build.version.release 2>> "$LOGFILE" || echo "Unknown")
                model=$(getprop ro.product.model 2>> "$LOGFILE" || echo "Unknown")
                log "- Phone: $brand Android $version"
                log "- Model: $model"
                echo "- Phone: $brand Android $version"
                echo "- Model: $model"
                echo ""
            
            # Get target information
            log "? Get Target information"
            echo "? Get Target information"
            codename=$(get_codename)
            if [ $? -ne 0 ]; then
                continue
            fi
            log "- Device codename: $codename"
            echo "- Device codename: $codename"
            sleep 10
            
            token=$(get_token "$chipset")
            if [ $? -ne 0 ]; then
                continue
            fi
            log "- Device Token: $token"
            echo "- Device Token: $token"

            # Get Mi account data
            echo -n "Enter Mi account data: "
            read -r mi_account
            if [ -z "$mi_account" ]; then
                log "\e[91mError: No Mi Account data provided.\033[0m"
                echo "\e[91mError: No Mi Account data provided.\033[0m"
                echo "Press Enter to return to the menu..."
                read -r
                continue
            fi

            # Perform unlock
            log ""
            log "- Unlocking Bootloader of $codename"
            echo "- Unlocking Bootloader of $codename"
            if ! get_javacmd; then
                continue
            fi
            # Capture get_token.jar output
            jar_output=$("$JAVACMD" -jar "$PRGDIR/get_token.jar" "$codename" "$token" "$mi_account" 2>> "$LOGFILE")
            if [ $? -ne 0 ]; then
                log "\e[91mError: get_token.jar failed to execute. Output: $jar_output\033[0m"
                log "Ensure get_token.jar is compatible with Java $java_version and Mi Account data is correct."
                echo "\e[91mError: get_token.jar failed to execute. Output: $jar_output\033[0m"
                echo "Ensure get_token.jar is compatible with Java $java_version and Mi Account data is correct."
                echo "Press Enter to return to the menu..."
                read -r
                continue
            fi

            if [ -z "$jar_output" ]; then
                log "\e[93mWarning: get_token.jar produced no output.\033[0m"
                log "It may have performed a silent operation or written to a file."
                echo "\e[93mWarning: get_token.jar produced no output.\033[0m"
                echo "It may have performed a silent operation or written to a file."
                echo -n "Enter unlock token manually (or press Enter to skip): "
                read -r unlock_token
                if [ -z "$unlock_token" ]; then
                    log "\e[91mError: No unlock token provided and get_token.jar produced no output.\033[0m"
                    echo "\e[91mError: No unlock token provided and get_token.jar produced no output.\033[0m"
                    echo "Press Enter to return to the menu..."
                    read -r
                    continue
                fi
                jar_output="$unlock_token"
            else
                log "- Unlock token from get_token.jar: $jar_output"
                echo "- Unlock token from get_token.jar: $jar_output"
                echo "Copy this token for your records. Press Enter to continue..."
                read -r
            fi

            # Write token to file
            if ! echo "$jar_output" | xxd -r -p > token.bin 2>> "$LOGFILE"; then
                log "\e[91mError: Failed to process unlock token with xxd.\033[0m"
                log "Ensure the token is valid hex data."
                echo "\e[91mError: Failed to process unlock token with xxd.\033[0m"
                echo "Ensure the token is valid hex data."
                rm -f token.bin
                echo "Press Enter to return to the menu..."
                read -r
                continue
            fi
            if [ ! -s token.bin ]; then
                log "\e[91mError: Failed to create token.bin or file is empty.\033[0m"
                log "Check if the unlock token is valid hex data."
                echo "\e[91mError: Failed to create token.bin or file is empty.\033[0m"
                echo "Check if the unlock token is valid hex data."
                rm -f token.bin
                echo "Press Enter to return to the menu..."
                read -r
                continue
            fi

            # Unlock bootloader
            if timeout 10 termux-fastboot stage token.bin 2>> "$LOGFILE"; then
                if timeout 10 termux-fastboot oem unlock 2>> "$LOGFILE"; then
                    log "\e[92m- Bootloader unlocked successfully!\033[0m"
                    echo "\e[92m- Bootloader unlocked successfully!\033[0m"
                    rm -f token.bin
                    log "- Log file saved at $LOGFILE for reference."
                    echo "- Log file saved at $LOGFILE for reference."
                    echo "Press Enter to exit..."
                    read -r
                    exit 0
                else
                    log "\e[91mError: Failed to execute 'oem unlock'. Check device compatibility or Mi Account binding.\033[0m"
                    log "See log file ($LOGFILE) for details."
                    echo "\e[91mError: Failed to execute 'oem unlock'. Check device compatibility or Mi Account binding.\033[0m"
                    echo "See log file ($LOGFILE) for details."
                    rm -f token.bin
                    echo "Press Enter to return to the menu..."
                    read -r
                    continue
                fi
            else
                log "\e[91mError: Failed to stage token.bin.\033[0m"
                log "See log file ($LOGFILE) for details."
                echo "\e[91mError: Failed to stage token.bin.\033[0m"
                echo "See log file ($LOGFILE) for details."
                rm -f token.bin
                echo "Press Enter to return to the menu..."
                read -r
                continue
            fi
            ;;
        3)
            log "- Exiting..."
            echo "- Exiting..."
            log "- Log file saved at $LOGFILE for reference."
            echo "- Log file saved at $LOGFILE for reference."
            exit 0
            ;;
    esac
done