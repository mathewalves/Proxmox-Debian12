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

configure_bridge()
{
    config_file="configs/network.conf"

    # Check if the configuration file exists
    if [ ! -f "$config_file" ]; then
        whiptail --title "Network Configuration" --msgbox "The configuration file $config_file does not exist. Run the script install_proxmox-1.sh first or configure manually." 15 60
    fi

    # Read configurations from the file
    source "$config_file"

    # Display network information
    whiptail --title "Network Configuration" --msgbox "Interface Information:\n\nPhysical Interface: $INTERFACE\nIP Address: $IP_ADDRESS\nGateway: $GATEWAY" 15 60

    # Use the variables read from the file or prompt for new ones if blank
    while true; do
        choice=$(whiptail --title "Network Configuration" --menu "Select an option:" 15 60 6 \
            "1" "Configure Manually" \
            "2" "Use DHCP" \
            "3" "Exit" 3>&1 1>&2 2>&3)

        case $choice in
            "1")
                # Manual configuration
                physical_interface=$(whiptail --inputbox "Enter the name of the physical interface (leave blank to keep $INTERFACE):" 10 60 "$INTERFACE" --title "Manual Configuration" 3>&1 1>&2 2>&3)
                ip_address=$(whiptail --inputbox "Enter the IP address for the bridge (leave blank to keep $IP_ADDRESS):" 10 60 "$IP_ADDRESS" --title "Manual Configuration" 3>&1 1>&2 2>&3)
                gateway=$(whiptail --inputbox "Enter the gateway for the bridge (leave blank to keep $GATEWAY):" 10 60 "$GATEWAY" --title "Manual Configuration" 3>&1 1>&2 2>&3)

                # Use the variables read or the new ones entered
                INTERFACE=${physical_interface:-$INTERFACE}
                IP_ADDRESS=${ip_address:-$IP_ADDRESS}

                # Validate if the gateway is a valid IP address
                if [[ -n "$gateway" && ! "$gateway" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    whiptail --title "Network Configuration" --msgbox "Invalid gateway. Exiting..." 10 60
                    exit 1
                fi

                GATEWAY=${gateway:-$GATEWAY}

                # Update the configuration file
                echo "INTERFACE=$INTERFACE" > "$config_file"
                echo "IP_ADDRESS=$IP_ADDRESS" >> "$config_file"
                echo "GATEWAY=$GATEWAY" >> "$config_file"

                # Comment out the physical interface configurations in the configuration file
                sed -i "/iface $INTERFACE inet static/,/iface/ s/^/#/" /etc/network/interfaces
                sed -i "/iface $INTERFACE inet dhcp/,/iface/ s/^/#/" /etc/network/interfaces

                # Create the vmbr0 bridge with the new information
                cat <<EOF >> /etc/network/interfaces
# Proxmox Bridge
auto vmbr0
iface vmbr0 inet static
    address $IP_ADDRESS
    gateway $GATEWAY
    bridge_ports $INTERFACE
    bridge_stp off
    bridge_fd 0
EOF

                whiptail --title "Network Configuration" --msgbox "The vmbr0 bridge was created successfully!" 10 60
                break
                ;;

            "2")
                # DHCP configuration

                # Comment out the physical interface configurations in the configuration file
                sed -i "/iface $INTERFACE inet static/,/iface/ s/^/#/" /etc/network/interfaces
                sed -i "/iface $INTERFACE inet dhcp/,/iface/ s/^/#/" /etc/network/interfaces

                # Create the vmbr0 bridge with DHCP
                cat <<EOF >> /etc/network/interfaces
# Proxmox Bridge
auto vmbr0
iface vmbr0 inet dhcp
    bridge_ports $INTERFACE
    bridge_stp off
    bridge_fd 0
EOF

                whiptail --title "Network Configuration" --msgbox "The vmbr0 bridge was configured with DHCP." 10 60
                break
                ;;

            "3")
                whiptail --title "Network Configuration" --msgbox "You can configure the vmbr0 bridge later by running the script /Proxmox-Debian12/scripts/configure_bridge.sh, manually, or through the Proxmox web interface. Refer to the Proxmox documentation for more information." 15 60
                exit 0
                ;;

            *)
                whiptail --title "Network Configuration" --msgbox "Invalid option" 10 60
                ;;
        esac
    done

    # Restart the network service to apply the changes
    whiptail --title "Network Configuration" --msgbox "Restarting the network service to apply the changes..." 10 60
    systemctl restart networking
    ip link set dev vmbr0 up

    whiptail --title "Network Configuration" --msgbox "The vmbr0 bridge was created successfully!" 10 60
}

configurar_bridge()
{
   config_file="configs/network.conf"

    # Verificar se o arquivo de configuração existe
    if [ ! -f "$config_file" ]; then
        whiptail --title "Configuração de Rede" --msgbox "O arquivo de configuração $config_file não existe. Execute o script install_proxmox-1.sh primeiro ou configure manualmente." 15 60
    fi

    # Ler as configurações do arquivo
    source "$config_file"

    # Exibindo informações de rede
    whiptail --title "Configuração de Rede" --msgbox "Informações da Interface:\n\nInterface Física: $INTERFACE\nEndereço IP: $IP_ADDRESS\nGateway: $GATEWAY" 15 60

    # Utilizar as variáveis lidas do arquivo ou solicitar novas se estiverem em branco
    while true; do
        choice=$(whiptail --title "Configuração de Rede" --menu "Selecione uma opção:" 15 60 6 \
            "1" "Configurar Manualmente" \
            "2" "Usar DHCP" \
            "3" "Sair" 3>&1 1>&2 2>&3)

        case $choice in
            "1")
                # Leitura manual das configurações
                interface_fisica=$(whiptail --inputbox "Informe o nome da interface física (deixe em branco para manter $INTERFACE):" 10 60 "$INTERFACE" --title "Configuração Manual" 3>&1 1>&2 2>&3)
                endereco_ip=$(whiptail --inputbox "Informe o endereço IP para a bridge (deixe em branco para manter $IP_ADDRESS):" 10 60 "$IP_ADDRESS" --title "Configuração Manual" 3>&1 1>&2 2>&3)
                gateway=$(whiptail --inputbox "Informe o gateway para a bridge (deixe em branco para manter $GATEWAY):" 10 60 "$GATEWAY" --title "Configuração Manual" 3>&1 1>&2 2>&3)

                # Utilizar as variáveis lidas ou as novas informadas
                INTERFACE=${interface_fisica:-$INTERFACE}
                IP_ADDRESS=${endereco_ip:-$IP_ADDRESS}

                # Validar se o gateway é um endereço IP válido
                if [[ -n "$gateway" && ! "$gateway" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    whiptail --title "Configuração de Rede" --msgbox "Gateway inválido. Saindo..." 10 60
                    exit 1
                fi

                GATEWAY=${gateway:-$GATEWAY}

                # Atualizar o arquivo de configuração
                echo "INTERFACE=$INTERFACE" > "$config_file"
                echo "IP_ADDRESS=$IP_ADDRESS" >> "$config_file"
                echo "GATEWAY=$GATEWAY" >> "$config_file"

                # Comentar as configurações da interface física no arquivo de configuração
                sed -i "/iface $INTERFACE inet static/,/iface/ s/^/#/" /etc/network/interfaces
                sed -i "/iface $INTERFACE inet dhcp/,/iface/ s/^/#/" /etc/network/interfaces

                # Criar a bridge vmbr0 com as novas informações
cat <<EOF >> /etc/network/interfaces
# Bridge Proxmox
auto vmbr0
iface vmbr0 inet static
    address $IP_ADDRESS
    gateway $GATEWAY
    bridge_ports $INTERFACE
    bridge_stp off
    bridge_fd 0
EOF

                whiptail --title "Configuração de Rede" --msgbox "A bridge vmbr0 foi criada com sucesso!" 10 60
                break
                ;;

            "2")
                # Configuração para DHCP

                # Comentar as configurações da interface física no arquivo de configuração
                sed -i "/iface $INTERFACE inet static/,/iface/ s/^/#/" /etc/network/interfaces
                sed -i "/iface $INTERFACE inet dhcp/,/iface/ s/^/#/" /etc/network/interfaces

                # Criar a bridge vmbr0 com as novas informações
                cat <<EOF >> /etc/network/interfaces
# Bridge Proxmox
auto vmbr0
iface vmbr0 inet dhcp
    bridge_ports $INTERFACE
    bridge_stp off
    bridge_fd 0
EOF

                whiptail --title "Configuração de Rede" --msgbox "A bridge vmbr0 foi configurada com DHCP." 10 60
                break
                ;;

            "3")
                whiptail --title "Configuração de Rede" --msgbox "Você pode configurar a bridge vmbr0 posteriormente executando o script /Proxmox-Debian12/scripts/configure_bridge.sh, manualmente ou através da interface web do Proxmox. Consulte a documentação do Proxmox para mais informações." 15 60
                exit 0
                ;;

            *)
                whiptail --title "Configuração de Rede" --msgbox "Opção inválida" 10 60
                ;;
        esac
    done

    # Reiniciar o serviço de rede para aplicar as alterações
    whiptail --title "Configuração de Rede" --msgbox "Reiniciando o serviço de rede para aplicar as alterações..." 10 60
    systemctl restart networking
    ip link set dev vmbr0 up

    whiptail --title "Configuração de Rede" --msgbox "A bridge vmbr0 foi criada com sucesso!" 10 60
}

remove_start_script() 
{
    # Remove script initialization along with the system // Remover inicialização do script junto com o sistema
    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"

        # Remove the script line from the profile file
        sed -i '/# Run script after login/,/# End of script 2/d' "$PROFILE_FILE"
        echo -e "${blue}Removed configuration from the profile for user:${cyan} $(basename "$user_home").${normal}"
    done

    # Remove the lines added to /root/.bashrc
    sed -i '/# Run script after login/,/\/Proxmox-Debian12\/scripts\/configure_bridge.sh/d' /root/.bashrc
    echo -e "${blue}Removed automatic script configuration from /root/.bashrc.${normal}"
}

main()
{
    super_user
    if [ "$LANGUAGE" == "en" ]; then
        echo -e "${cyan}3rd part: Configuring bridge"
        echo -e "...${default}"
        configure_bridge
    else
        echo -e "${cyan}3ª parte: Configurando a ponte (bridge)"
        echo -e "...${default}"
        configurar_bridge
    fi

    remove_start_script
    
    if [ "$LANGUAGE" == "en" ]; then
        ask_reboot
        clear
        whiptail --title "Installation Completed" --msgbox "Proxmox installation and network configuration completed successfully!\nRemember to configure Proxmox as needed." 15 60
        whiptail --title "Network Configuration" --msgbox "You can configure the vmbr0 bridge later by running the script /Proxmox-Debian12/scripts/configure_bridge.sh or through the Proxmox web interface. Refer to the Proxmox documentation for more information." 15 60
    else
        clear
        whiptail --title "Instalação Concluída" --msgbox "Instalação e configuração de rede do Proxmox concluídas com sucesso!\nLembre-se de configurar o Proxmox conforme necessário." 15 60
        whiptail --title "Configuração de Rede" --msgbox "Você pode configurar a bridge vmbr0 posteriormente executando o script /Proxmox-Debian12/scripts/configure_bridge.sh, ou através da interface web do Proxmox. Consulte a documentação do Proxmox para mais informações." 15 60
    fi

    cd /Proxmox-Debian12
    ./scripts/welcome.sh
}

main
