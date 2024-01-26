#!/bin/bash

# Proxmox Setup v1.0.1
# by: Matheew Alves

cd /Proxmox-Debian12

# Load configs files
source ./configs/colors.conf
source ./configs/language.conf

# Becoming superuser // Tornando-se superusuário
super_user()
{
    if [ "$(whoami)" != "root" ]; then
        if [ "$LANGUAGE" == "en" ]; then
            echo -e "${ciano}Log in as superuser...${default}"
        else
            echo -e "${ciano}Faça o login como superusuário...${default}" 
        fi
        sudo -E bash "$0" "$@"
        exit $?
    fi
}

add_welcome()
{
    # Add script execution to user profiles
    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"
        
        # Check if the profile file exists before adding
        if [ -f "$PROFILE_FILE" ]; then
            # Add the script execution line to the end of the file
            echo "" >> "$PROFILE_FILE"
            echo "# Execute script after login" >> "$PROFILE_FILE"
            echo "/Proxmox-Debian12/scripts/custom_welcome.sh" >> "$PROFILE_FILE"
            echo "" >> "$PROFILE_FILE"

            echo "Automatic configuration completed for user: $(basename "$user_home")."
        fi

        # Add the following lines to the end of the /root/.bashrc file
        echo "" >> /root/.bashrc
        echo "# Execute script after login" >> /root/.bashrc
        echo "/Proxmox-Debian12/scripts/custom_welcome.sh" >> /root/.bashrc
        echo "" >> /root/.bashrc

        echo "Automatic configuration completed for the root user."
    done
}

ask_reboot()
{
    # Prompt for restarting the computer using whiptail
    if whiptail --yesno "(Optional) Do you want to restart your computer now?" 10 50 --yes-button "Yes" --no-button "No"; then
        # Messages after choosing to restart
        whiptail --title "Installation Completed" --msgbox "Proxmox installation and network configuration completed successfully!\nRemember to configure Proxmox as needed." 15 60
        whiptail --title "Restarting the System" --msgbox "Restarting the system..." 10 50
        systemctl reboot
    else
        # Message after choosing not to restart
        whiptail --title "Installation Completed" --msgbox "Proxmox installation and network configuration completed successfully!\nRemember to configure Proxmox as needed." 15 60
    fi
}

perguntar_reboot()
{
    # Question about restarting the computer using whiptail
    if whiptail --yesno "(Opcional) Deseja reiniciar o computador agora?" 10 50 --yes-button "Sim" --no-button "Não"; then
        # Messages after choosing to restart
        whiptail --title "Reiniciando o Sistema" --msgbox "Reiniciando o sistema..." 10 50
        systemctl reboot
    else
        # Message after choosing not to restart
        exit 1
    fi
}

main()
{
    super_user
    if [ "$LANGUAGE" == "en" ]; then
        if whiptail --yesno "(Optional) Do you want to add a custom welcome screen?" 10 50 --yes-button "Yes" --no-button "No"; then
            add_welcome
            ask_reboot
        else
            exit 1
        fi
    else
        if whiptail --yesno "(Opcional) Deseja adicionar tela de bem-vindo customizada?" 10 50 --yes-button "Sim" --no-button "Não"; then
            add_welcome
            perguntar_reboot
        else
            exit 1
        fi
    fi
}

main