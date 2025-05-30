#!/bin/sh

# Clear the terminal screen (optional, can be removed if not needed)
clear

# Install figlet
echo "- Installing additional files"
# if ! pkg install figlet -y; then
  #  echo "Error: Failed to install figlet. Please check your package manager or internet connection."
  #  exit 1
# fi

# Clear the terminal screen again (optional)
clear
#######
get_unlock() {
    PRG="$0"
while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done
PRGDIR=`dirname "$PRG"`

cygwin=false;
darwin=false;
case "`uname`" in
  CYGWIN*) cygwin=true
    ;;
  Darwin*) darwin=true
    if [ -z "$JAVA_VERSION" ] ; then
      JAVA_VERSION="CurrentJDK"
    else
      echo "Using Java version: $JAVA_VERSION"
    fi
    if [ -z "$JAVA_HOME" ]; then
      if [ -x "/usr/libexec/java_home" ]; then
        JAVA_HOME=`/usr/libexec/java_home`
      else
        JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/${JAVA_VERSION}/Home
      fi
    fi
    ;;
esac

if [ -z "$JAVA_HOME" ] ; then
  if [ -r /etc/gentoo-release ] ; then
    JAVA_HOME=`java-config --jre-home`
  fi
fi

if $cygwin ; then
  [ -n "$JAVA_HOME" ] && JAVA_HOME=`cygpath --unix "$JAVA_HOME"`
fi

if [ -z "$JAVACMD" ] ; then
  if [ -n "$JAVA_HOME"  ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
      JAVACMD="$JAVA_HOME/jre/sh/java"
    else
      JAVACMD="$JAVA_HOME/bin/java"
    fi
  else
    JAVACMD=`which java`
  fi
fi

if [ ! -x "$JAVACMD" ] ; then
  echo "Error: JAVA_HOME is not defined correctly. We cannot execute $JAVACMD" 1>&2
  exit 1
fi

if $cygwin ; then
  [ -n "$JAVA_HOME" ] && JAVA_HOME=`cygpath --path --windows "$JAVA_HOME"`
fi
}
#######
# Display date and banner
echo "- $(date)"
if command -v figlet > /dev/null; then
   echo -e "\e[96m "
    figlet "Termux"
    echo -e "\033[0m- \e[93mTermux bootloader Unlock\033[0m"
    echo -e "- Tool version : 1.0 \e[93mbeta\033[0m "
    echo -e "- Build date   : Fri May 30 16:18:03 IST 2025"
    echo -e "- Developer    : \e[92m@Jonjeexe\033[0m | Telegram \e[92m@OnionXProject\033[0m"
    echo ""
    echo -e "-  \e[96mChoose Tools options\033[0m"
    echo -e "1. \e[93mUnlock bootloader MediaTek    ( Xaiome )\033[0m"
    echo -e "2. \e[93mUnlock bootloader Snapdragon  ( Xaiome )\033[0m"
    echo  ""
else
    echo "Error: figlet is not installed."
    exit 1
fi
# Read user input
    echo -n "[?] ENTER MODE NUMBER : "
    read num
    case $num in
    1) echo -e "- \e[96mStart Unlocking bootloader of MediaTek\033[0m"; 
        echo ""
        # Check for connected devices and store device ID
        id=$(fastboot devices | awk '{print $1}')

        # Check if a device is connected
         if [ -z "$id" ]; then               
               echo "- No device connected in Fastboot mode."
               echo "- Try again"
               bash Tool.sh
          else
               echo "- Target device is connected : $id"
        fi
        echo ""
        echo -e "? Host information"
        echo -e "- Phone : $(getprop ro.product.brand) A$(getprop ro.build.version.release)"
        echo -e "- Model : $(getprop ro.product.model)"
        echo ""
        echo -e "? Get Target information "
        codename=$(mi-fastboot getvar product 2>&1 | grep "product:" | awk '{print $2}')
        token=$(fastboot oem get_token 2>&1 | grep "token:" | awk '{print $2}')
        
        # Check if codename is empty
       if [ -z "$codename" ]; then
              echo "Error: Could not retrieve product codename. Ensure device is in Fastboot mode and connected."
              exit 0
       fi
       if [ -z "$token" ]; then
              echo "Error: Could not retrieve unlock token. Ensure device is in Fastboot mode and supports 'oem get_token'."
              exit 1
       fi 
       echo "- Device codename : $codename"
       echo "- Device Token   : $token"
       
       # Mi account data 
       echo "Enter Mi account data : "
       read -r mi_account

       # Check if Mi Account data was provided
       if [ -z "$mi_account" ]; then
           echo "Error: No Mi Account data provided."
           exit 1
       fi

       # Performing unlock bootloader
       echo ""
       echo -e "- Unlocking Bootloader of $codename"
       get_unlock;
       jar_output=$("$JAVACMD" -jar "$PRGDIR/get_token.jar" "$codename" "$token" "$mi_account" 2>&1)
      if [ $? -ne 0 ]; then
            echo "Error: get_token.jar failed to execute. Output: $jar_output"
       exit 1
      fi

      # Check if jar_output is empty
       if [ -z "$jar_output" ]; then
             echo "Warning: get_token.jar produced no output. It may have written to a file or performed a silent operation."
       fi
       
       # Unlock Bootloader
       echo "jar_output" | xxd -r -p > token.bin
       mi-fastboot stage token.bin && mi-fastboot oem unlock
       exit 0;;
       
      2) echo -e "- \e[96mStart Unlocking bootloader of Snapdragon \033[0m"; 
        
       exit 0;;
       
       *) clear; echo -e "Wrong! Input"; sleep 2; echo "Back to MENU..."; sleep 2;;
 esac
exit 0
       
       
      

# Placeholder for bootloader unlocking logic (if intended)
# echo "Starting bootloader unlocking process..."
# Add relevant commands here