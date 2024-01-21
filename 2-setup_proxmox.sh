#!/bin/bash
# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo -e "\e[1;92mTornando-se superusuário...\e[0m"
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

# Remover o serviço do systemd
remove_service() 
{
    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"  # Pode ser alterado para ~/.bash_profile se preferir

        if [ -f "$PROFILE_FILE" ]; then
            sed -i '/2-setup_proxmox.sh/d' "$PROFILE_FILE"
            echo "Removida a execução deste script do perfil do usuário: $(basename "$user_home")."
        fi
    done
}

proxmox-ve_packages()
{
    if command -v nala &> /dev/null; then
        # Executar com 'nala' se estiver instalado
        nala install -y proxmox-ve postfix open-iscsi chrony
    else
        # Executar com 'apt' se 'nala' não estiver instalado
        apt install -y proxmox-ve postfix open-iscsi chrony
    fi
}

# Remover kernel do Debian
remove_kernel()
{
    if command -v nala &> /dev/null; then
        # Executar com 'nala' se estiver instalado
        nala remove -y linux-image-amd64 'linux-image-6.1*'
    else
        # Executar com 'apt' se 'nala' não estiver instalado
        apt remove -y linux-image-amd64 'linux-image-6.1*'
    fi

    update-grub
}

remove_os-prober()
{
   if command -v nala &> /dev/null; then
        # Executar com 'nala' se estiver instalado
        nala remove -y os-prober
    else
        # Executar com 'apt' se 'nala' não estiver instalado
        apt remove -y os-prober
    fi 
}


main()
{
    proxmox-ve_packages
    remove_kernel
    remove_os-prober

    # Mensagem de instalação concluída com cores e efeitos
    echo -e "Instalação concluída com sucesso!"
    neofetch

    remove_service
    systemctl reboot
}

main