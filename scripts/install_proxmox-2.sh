#!/bin/bash
# Carregar as variáveis de cores do arquivo colors.conf
cd /Proxmox-Debian12
source ./configs/colors.conf

# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo -e "${ciano}Tornando-se superusuário...${normal}"
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
        echo -e "${azul}Removida a configuração do perfil para o usuário:${ciano} $(basename "$user_home").${normal}"

        # Remover a entrada do sudoers
        sed -i "/$(basename "$user_home") ALL=(ALL:ALL) NOPASSWD: \/Proxmox-Debian12\/2-setup_proxmox.sh/d" /etc/sudoers.d/proxmox_setup
        echo -e "${azul}Removida a configuração do sudoers para o usuário: ${ciano}$(basename "$user_home").${normal}"
    done
}

proxmox-ve_packages()
{
    echo -e "${ciano}1º parte: Passo 1/3${normal}"
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
    echo -e "${ciano}2º parte: Passo 2/3${normal}"
    echo -e "${ciano}Removendo Kernel do Debian 12 p/ o Proxmox...${normal}"
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
    echo -e "${ciano}2º parte: Passo 3/3${normal}"
    echo -e "${ciano}Removendo os prober...${normal}"
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
    echo -e "${verde}2º Parte da instalação do ProxMox concluída com sucesso!${normal}"
    proxmox-ve_packages
    remove_kernel
    remove_os-prober

    # Verificar se o comando neofetch está instalado
    if command -v neofetch &> /dev/null; then
        neofetch
    fi

    remove_service

   echo -e "${ciano}Deseja configurar a bridge vmbr0 agora?${normal}"
    echo -e "(${amarelo}Importante: caso opte por não fazer agora, será necessário configurar a bridge mais tarde${normal})..."

    read -p "Configurar agora? [S/N]: " configurar_agora

    if [[ "${configurar_agora,,}" =~ ^[sS](im)?$ ]]; then
        # Caminho do script que você deseja executar
        script_a_executar="./scripts/configure_bridge"

        # Verifica se o script a ser executado existe
        if [ -e "$script_a_executar" ]; then
            # Executa o script
            bash "$script_a_executar"
        else
            echo -e "${vermelho}Erro: O script $script_a_executar não foi encontrado.${normal}"
        fi
    else
        echo -e "${amarelo}A configuração da bridge vmbr0 pode ser feita mais tarde executando o script ${ciano}Proxmox-Debian12/scripts/configure_bridge.sh${normal}"
    fi
}

main