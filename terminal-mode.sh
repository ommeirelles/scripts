#!/usr/bin/env bash

OPT_TYPE=""

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

while getopts o:tg flag; do
    case "${flag}" in
    o) OPT_TYPE=${OPTARG} ;;
    t) OPT_TYPE="TERMINAL" ;;
    g) OPT_TYPE="GUI" ;;
    esac
done

declare -a AVAILABLE_OPTS=("GUI" "TERMINAL")

# CHEK IF OPT_TYPE ISN'T A VALID OPTION
if [[ ! " ${AVAILABLE_OPTS[*]} " =~ " ${OPT_TYPE} " ]]; then
    echo "
Invalid arguments. 
Usage:
    ./terminal-mode.sh -t  # sets the default boot mode to terminal
    ./terminal-mode.sh -g  # sets the default boot mode to gui (graphical user interface)
    ./terminal-mode.sh -o [GUI|TERMINAL] # sets the default boot mode to the option passed as argument
"
    exit 2
fi

function printFilesValues() {
    grep "GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub
    grep "GRUB_TERMINAL=" /etc/default/grub
}

# CHEK IF OPT_TYPE IS INSIDE A LIST OF VALID OPTIONS
if [[ " ${AVAILABLE_OPTS[*]} " =~ " ${OPT_TYPE} " ]]; then
    # UPDATE GRUB COMMAND
    update-grub

    clear && printFilesValues

    if [[ $OPT_TYPE == "GUI" ]]; then
        echo "Setting to GUI mode..."
        # SET GRUB CMDLINE_LINUX_DEFAULT TO "quiet splash"
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="text"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub

        if [[ $(grep "GRUB_TERMINAL=" /etc/default/grub) == "GRUB_TERMINAL=console" ]]; then
            # REPLACE GRUB_TERMINAL=console TO #GRUB_TERMINAL=console
            sed -i 's/GRUB_TERMINAL=console/#GRUB_TERMINAL=console/' /etc/default/grub

        elif [[ $(grep "GRUB_TERMINAL=" /etc/default/grub) == "#GRUB_TERMINAL=console" ]]; then
            # DO NOTHING AS IT IS CORRECT ALREADY
            echo ""
        else
            # INSERT #GRUB_TERMINAL=console IN FILE
            echo "#GRUB_TERMINAL=console" >>/etc/default/grub
        fi

        systemctl enable graphical.target --force
        systemctl set-default graphical

    elif [[ $OPT_TYPE == "TERMINAL" ]]; then
        echo "Setting to TERMINAL mode..."
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="text"/' /etc/default/grub

        if [[ $(grep "GRUB_TERMINAL=" /etc/default/grub) == "#GRUB_TERMINAL=console" ]]; then
            # REPLACE #GRUB_TERMINAL=console TO GRUB_TERMINAL=console
            sed -i 's/#GRUB_TERMINAL=console/GRUB_TERMINAL=console/' /etc/default/grub
        elif [[ $(grep "GRUB_TERMINAL=" /etc/default/grub) == "GRUB_TERMINAL=console" ]]; then
            # DO NOTHING AS IT IS CORRECT ALREADY
            echo ""
        else
            # INSERT GRUB_TERMINAL=console IN FILE
            echo "GRUB_TERMINAL=console" >>/etc/default/grub
        fi

        systemctl enable multi-user.target --force
        systemctl set-default multi-user
    else
        echo "Invalid option"
        exit 2
    fi
    printFilesValues
    echo "Proceed [y/n]?"
    read -r CONTINUE
    echo $CONTINUE

    if [[ $CONTINUE == "y" ]]; then
        clear
        update-grub
        reboot
    fi
fi
