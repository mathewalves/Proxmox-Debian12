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

   echo -e "\e[1;33mDeseja configurar a bridge vmbr0 agora?\e[0m"
    echo -e "(\e[1;31mImportante: caso opte por não fazer agora, será necessário configurar a bridge mais tarde\e[0m)..."

    read -p "Configurar agora? (Digite '\e[1;36msim\e[0m' para configurar): " configurar_agora

    if [[ "${configurar_agora,,}" =~ ^[sS](im)?$ ]]; then
        # Obtém o diretório do script atual
        script_directory="$(dirname "$(readlink -f "$0")")"

        # Caminho do script que você deseja executar
        script_a_executar="$script_directory/configure_bridge"

        # Verifica se o script a ser executado existe
        if [ -e "$script_a_executar" ]; then
            # Executa o script
            bash "$script_a_executar"
        else
            echo "Erro: O script $script_a_executar não foi encontrado."
        fi
    else
        echo -e "\e[1;33mA configuração da bridge vmbr0 pode ser feita mais tarde executando o script \e[1;36m./configure_bridge.sh\e[0m"
    fi
}

main