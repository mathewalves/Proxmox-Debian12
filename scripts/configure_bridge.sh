#!/bin/bash
# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo -e "\e[1;92mTornando-se superusuário...\e[0m"
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

verificar_bridge()
{
    # Verificar se a bridge vmbr0 já existe
    if grep -q "iface vmbr0" /etc/network/interfaces; then
        echo "A bridge vmbr0 já existe. Reconfigurando..."
        
        # Remover a configuração existente, incluindo a linha 'auto vmbr0'
        sed -i '/auto vmbr0/,/iface vmbr0/,/^$/d' /etc/network/interfaces
    else
        echo "Criando a bridge vmbr0..."
    fi
}

bridge()
{
    # Caminho para o arquivo de configuração
    cd /Proxmox-Debian12
    config_file="configs/network.conf"

    # Verificar se o arquivo de configuração existe
    if [ ! -f "$config_file" ]; then
        echo -e "\e[1;31mO arquivo de configuração $config_file não existe. Execute o script install_proxmox-1.sh primeiro ou configure manualmente.\e[0m"
        exit 1
    fi

    # Ler as configurações do arquivo
    source "$config_file"

    # Exibindo informações de rede
    echo -e "\e[1;36mConfigurações de rede:\e[0m"
    echo "Interface Física: $INTERFACE"
    echo "Endereço IP para a bridge: $IP_ADDRESS"
    echo "Gateway: $GATEWAY"

    verificar_bridge

    # Utilizar as variáveis lidas do arquivo ou solicitar novas se estiverem em branco
    echo -e "Configurando as informações da interface de rede para criação da bridge..."
    PS3="Selecione uma opção (Digite o número): "
    options=("Configurar Manualmente" "Usar DHCP" "Sair")

  select opt in "${options[@]}"; do
    case $opt in
        "Configurar Manualmente")
            # Leitura manual das configurações
            read -p "Informe o nome da interface física (deixe em branco para manter "$INTERFACE"): " interface_fisica
            read -p "Informe o endereço IP para a bridge com net mask (deixe em branco para manter "$IP_ADDRESS"): " endereco_ip
            read -p "Informe o gateway para a bridge (deixe em branco para manter "$GATEWAY"): " gateway

            # Utilizar as variáveis lidas ou as novas informadas
            INTERFACE=${interface_fisica:-$INTERFACE}
            IP_ADDRESS=${endereco_ip:-$IP_ADDRESS}

            # Validar se o gateway é um endereço IP válido
            if [[ -n "$gateway" && ! "$gateway" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Gateway inválido. Saindo..."
                exit 1
            fi

            GATEWAY=${gateway:-$GATEWAY}

            # Atualizar o arquivo de configuração
            echo "INTERFACE=$INTERFACE" > "$config_file"
            echo "IP_ADDRESS=$IP_ADDRESS" >> "$config_file"
            echo "GATEWAY=$GATEWAY" >> "$config_file"

            # Criar a bridge vmbr0 com as novas informações
            cat <<EOF >> /etc/network/interfaces
# Configurações da Interface Física
# ...

# Configurações da Bridge vmbr0
auto vmbr0
iface vmbr0 inet static
    address $IP_ADDRESS
    gateway $GATEWAY
    bridge_ports $INTERFACE
    bridge_stp off
    bridge_fd 0
EOF

            break 2
            ;;

        "Usar DHCP")
            # Configuração para DHCP
            # Atualizar o arquivo de configuração
            echo "INTERFACE=$INTERFACE" > "$config_file"
            echo "IP_ADDRESS=" >> "$config_file"  # Remover o IP se estiver presente
            echo "GATEWAY=" >> "$config_file"     # Remover o GATEWAY se estiver presente

            # Criar a bridge vmbr0 com as novas informações
            cat <<EOF >> /etc/network/interfaces
# Configurações da Interface Física
# ...

# Configurações da Bridge vmbr0 para DHCP
auto vmbr0
iface vmbr0 inet dhcp
    bridge_ports $INTERFACE
    bridge_stp off
    bridge_fd 0
EOF

            break 2
            ;;

        "Sair")
            echo "Saindo..."
            exit 0
            ;;

        *) echo "Opção inválida";;
    esac
done


    # Reiniciar o serviço de rede para aplicar as alterações
    echo "Reiniciando o serviço de rede..."
    systemctl restart networking

    echo "A bridge vmbr0 foi criada com sucesso!"
    cd /
}

reboot()
{
    echo -e "\e[1;32mInstalação e configuração do Proxmox concluída com sucesso!\e[0m"
    echo -e "\e[1;91mAVISO: O sistema será reiniciado.\e[0m"
    sleep 5
    systemctl reboot
}

main()
{
    bridge

    echo -e "Deseja reiniciar o computador agora? (Opcional)"
    read -p "Resposta " perguntar_reboot

    if ["$perguntar_reboot" == "sim"]; then
        reboot
    fi
    
}

main
