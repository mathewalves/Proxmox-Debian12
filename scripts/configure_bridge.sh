#!/bin/bash
# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo -e "\e[1;92mTornando-se superusuário...\e[0m"
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

bridge()
{
    # Caminho para o arquivo de configuração
    config_file="../configs/network.conf"

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
    echo "Máscara de Sub-rede: $MASCARA_SUBREDE"
    echo "Gateway: $GATEWAY"

    # Utilizar as variáveis lidas do arquivo ou solicitar novas se estiverem em branco
    read -p "Informe o nome da interface física (deixe em branco para manter $INTERFACE): " interface_fisica
    read -p "Informe o endereço IP para a bridge (deixe em branco para manter $IP_ADDRESS): " endereco_ip
    read -p "Informe a máscara de sub-rede para a bridge (deixe em branco para manter $MASCARA_SUBREDE): " mascara_subrede
    read -p "Informe o gateway para a bridge (deixe em branco para manter $GATEWAY): " gateway

    # Utilizar as variáveis lidas ou as novas informadas
    INTERFACE=${interface_fisica:-$INTERFACE}
    IP_ADDRESS=${endereco_ip:-$IP_ADDRESS}
    MASCARA_SUBREDE=${mascara_subrede:-$MASCARA_SUBREDE}
    GATEWAY=${gateway:-$GATEWAY}


# Criar a bridge vmbr0
echo "Criando a bridge vmbr0..."
cat <<EOF >> /etc/network/interfaces
auto vmbr0
iface vmbr0 inet static
    address $IP_ADDRESS
    netmask $MASCARA_SUBREDE
    gateway $GATEWAY
    bridge_ports $INTERFACE
    bridge_stp off
    bridge_fd 0
EOF

    # Reiniciar o serviço de rede para aplicar as alterações
    echo "Reiniciando o serviço de rede..."
    systemctl restart networking

    echo "A bridge vmbr0 foi criada com sucesso!"
}

reboot()
{
    echo -e "\e[1;32mInstalação e configuração do Proxmox concluída com sucesso!\e[0m"
    echo -e "\e[1;91mAVISO: O sistema será reiniciado automaticamente para concluir a instalação.\e[0m"
    sleep 5
    systemctl reboot
}

main()
{
    bridge
    reboot
}

main
