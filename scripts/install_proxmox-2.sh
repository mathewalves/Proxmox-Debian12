#!/bin/bash

# Proxmox Setup v1.0.1
# by: Matheew Alves

cd /Proxmox-Debian12

# Load configs files // Carregar os arquivos de configuração
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

# Remove script initialization along with the system // Remover inicialização do script junto com o sistema
remove_start_script() 
{
    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"
        
        # Remove the script line from the profile file
        sed -i '/# Execute script after login/,/# End of script 2/d' "$PROFILE_FILE"
        echo -e "${blue}Removed profile configuration for user:${cyan} $(basename "$user_home").${normal}"

        # Remove the lines added to /root/.bashrc
        sed -i '/# Execute script after login/,/\/Proxmox-Debian12\/scripts\/install_proxmox-2.sh/d' /root/.bashrc
        echo -e "${blue}Removed automatic script configuration in /root/.bashrc.${normal}"
    done
}

# Start bridge configuration after reboot // Iniciar configuração da bridge após o reboot
configure_bridge() 
{
    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"

        # Check if the profile file exists before adding
        if [ -f "$PROFILE_FILE" ]; then
            # Add the script execution line at the end of the file
            echo -e "\n# Run script after login" >> "$PROFILE_FILE"
            echo "/Proxmox-Debian12/scripts/configure_bridge.sh" >> "$PROFILE_FILE"

            echo "Automatic configuration completed for user: $(basename "$user_home")."
        fi
    done

    # Add the following lines at the end of the /root/.bashrc file
    echo -e "\n# Run script after login" >> /root/.bashrc
    echo "/Proxmox-Debian12/scripts/configure_bridge.sh" >> /root/.bashrc

    echo "Automatic configuration completed for the root user."
}


proxmox-ve_packages()
{
    if [ "$LANGUAGE" == "en" ]; then
        echo -e "${cyan}Setting up Proxmox 2nd part."
        echo -e "Step 1/3: Proxmox VE packages"
        echo -e "...${default}"
    else
        echo -e "${cyan}Configurando a 2ª parte do Proxmox."
        echo -e "Passo 1/3: Pacotes do Proxmox VE"
        echo -e "...${default}"
    fi

    if command -v nala &> /dev/null; then
        # Execute with 'nala' if installed
        nala install -y proxmox-ve postfix open-iscsi chrony
    else
        # Execute with 'apt' if 'nala' is not installed
        apt install -y proxmox-ve postfix open-iscsi chrony
    fi
}

# Remove Debian kernel // Remover kernel do Debian
remove_kernel()
{
    if [ "$LANGUAGE" == "en" ]; then
        echo -e "${cyan}Setting up Proxmox 2nd part."
        echo -e "Step 2/3: Removing old kernel"
        echo -e "...${default}"
    else
        echo -e "${cyan}Configurando a 2ª parte do Proxmox."
        echo -e "Passo 2/3: Removendo o kernel antigo"
        echo -e "...${default}"
    fi

    if command -v nala &> /dev/null; then
        # Execute with 'nala' if installed
        nala remove -y linux-image-amd64 'linux-image-6.1*'
    else
        # Execute with 'apt' if 'nala' is not installed
        apt remove -y linux-image-amd64 'linux-image-6.1*'
    fi

    update-grub
}

remove_os-prober()
{
    if [ "$LANGUAGE" == "en" ]; then
        echo -e "${cyan}Setting up Proxmox 2nd part."
        echo -e "Step 3/3: Removing os-prober"
        echo -e "...${default}"
    else
        echo -e "${cyan}Configurando a 2ª parte do Proxmox."
        echo -e "Passo 3/3: Removendo o os-prober"
        echo -e "...${default}"
    fi

    if command -v nala &> /dev/null; then
        # Execute with 'nala' if installed
        nala remove -y os-prober
    else
        # Execute with 'apt' if 'nala' is not installed
        apt remove -y os-prober
    fi
}

main()
{
    super_user
    proxmox-ve_packages
    remove_kernel
    remove_os-prober

    # Check if the neofetch command is installed // Verificar se o comando neofetch está instalado
    if command -v neofetch &> /dev/null; then
        neofetch
    fi

    if [ "$LANGUAGE" == "en" ]; then
        echo -e "${green}2º Part of ProxMox installation completed successfully!${default}" 
    else
        echo -e "${green}2º Parte da instalação do ProxMox concluída com sucesso!${default}"
    fi

    remove_start_script
    configure_bridge

    if [ "$LANGUAGE" == "en" ]; then
        echo -e "${red}WARNING: ${yellow}System automatically restarted to complete the installation..."
        echo -e "Log in as the '${cyan}root${yellow}' user after the reboot!${default}"
    else
        echo -e "${red}AVISO: ${yellow}Reiniciado o sistema automaticamente para concluir a instalação..."
        echo -e "Faça o login como usuário '${cyan}root${yellow}' após o reboot!${default}"
    fi
    sleep 5
    systemctl reboot
}

main