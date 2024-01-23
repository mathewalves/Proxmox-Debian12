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
        PROFILE_FILE="$user_home/.bashrc"
        
        # Remover a linha do script do arquivo de perfil
        sed -i '/# Executar script após o login/,/# Fim do script 2/d' "$PROFILE_FILE"
        echo "Removida a configuração do perfil para o usuário: $(basename "$user_home")."

        # Remover a entrada do sudoers
        sed -i "/$(basename "$user_home") ALL=(ALL:ALL) NOPASSWD: \/Proxmox-Debian12\/2-setup_proxmox.sh/d" /etc/sudoers.d/proxmox_setup
        echo "Removida a configuração do sudoers para o usuário: $(basename "$user_home")."
    done
}

proxmox-ve_packages()
{
    echo -e "\e[1;36m1º parte: Passo 1/3\e[0m"
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
    echo -e "\e[1;36m2º parte: Passo 2/3\e[0m"
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
    echo -e "\e[1;36m2º parte: Passo 3/3\e[0m"
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
    echo -e "\e[1;93m2º Parte da instalação do ProxMox executado com sucesso.\e[0m"
    proxmox-ve_packages
    remove_kernel
    remove_os-prober

    # Mensagem de instalação concluída com cores e efeitos
    echo -e "Instalação concluída com sucesso!"

    # Verificar se o comando neofetch está instalado
    if command -v neofetch &> /dev/null; then
        neofetch
    fi

    remove_service

    ./configure_bridge.sh
}

main