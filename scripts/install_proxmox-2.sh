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

# Remover inicialização do script junto com o sistema
remove_start-script() 
{
    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"
        
        # Remover a linha do script do arquivo de perfil
        sed -i '/# Executar script após o login/,/# Fim do script 2/d' "$PROFILE_FILE"
        echo -e "${azul}Removida a configuração do perfil para o usuário:${ciano} $(basename "$user_home").${normal}"

       # Remover as linhas adicionadas ao /root/.bashrc
        sed -i '/# Executar script após o login/,/\/Proxmox-Debian12\/scripts\/install_proxmox-2.sh/d' /root/.bashrc
        echo -e "${azul}Removida a configuração automática do script no /root/.bashrc.${normal}"
    done
}

# Iniciar configuração da bridge após o reboot
configure_bridge() 
{
    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"
        
        # Verifica se o arquivo de perfil existe antes de adicionar
        if [ -f "$PROFILE_FILE" ]; then
            # Adiciona a linha de execução do script ao final do arquivo
            echo "" >> "$PROFILE_FILE"
            echo "# Executar script após o login" >> "$PROFILE_FILE"
            echo "/Proxmox-Debian12/scripts/configure_bridge.sh" >> "$PROFILE_FILE"
            echo "" >> "$PROFILE_FILE"

            echo "Configuração automática concluída para o usuário: $(basename "$user_home")."
        fi

        # Adicione as seguintes linhas ao final do arquivo /root/.bashrc
        echo "" >> /root/.bashrc
        echo "# Executar script após o login" >> /root/.bashrc
        echo "/Proxmox-Debian12/scripts/configure_bridge.sh" >> /root/.bashrc
        echo "" >> /root/.bashrc

        echo "Configuração automática concluída para o usuário root."
    done
}

proxmox-ve_packages()
{
    echo -e "${ciano}Setup Proxmox 2º parte."
    echo -e "${ciano}Passo 1/3: Proxmox VE packages"
    echo -e "...${normal}"
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
    echo -e "${ciano}Setup Proxmox 2º parte."
    echo -e "Passo 2/3: Removendo kernel antigo"
    echo -e "...${normal}"
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
    echo -e "${ciano}Setup Proxmox 2º parte."
    echo -e "${ciano}Passo 3/3: Removendo os-prober"
    echo -e "...${normal}"
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

    # Verificar se o comando neofetch está instalado
    if command -v neofetch &> /dev/null; then
        neofetch
    fi

    remove_start-script
    echo -e "${verde}2º Parte da instalação do ProxMox concluída com sucesso!${normal}"
    configure_bridge  

    echo -e "${ciano}Reiniciado o sistema automaticamente para concluir a instalação...${normal}"
    echo -e "${amarelo}Faça o login como usuário '${ciano}root${amarelo}' após o reboot!${normal}"
    

    # Aguarda alguns segundos antes de reiniciar
    sleep 5

    # Reinicia o sistema
    systemctl reboot
}

main