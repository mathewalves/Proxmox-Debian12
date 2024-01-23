#!/bin/bash

# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo -e "\e[1;92mTornando-se superusuário...\e[0m"
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

chmod +x scripts/*
chmod +rw configs/*


# Função para instalar sudo
install_sudo() 
{
    echo -e "\e[1;32mIniciando instalação do sudo...\e[0m"
    nala install -y sudo

    echo "Selecione um usuário para adicionar permissões sudo:"

    # Lista todos os usuários do sistema com permissões de sudo
    all_sudo_users=$(grep -E '^[^:]+:[^:]+:[0-9]{4,}' /etc/passwd | cut -d: -f1)

    # Pergunta ao usuário se deseja adicionar permissões de sudo
    PS3="Selecione um usuário para adicionar permissões de sudo ou digite 'pular' para pular: "
    select novo_sudo_user in $all_sudo_users; do
        if [[ -n "$novo_sudo_user" ]]; then
            # Verifica se o usuário selecionado já tem permissões de sudo
            if id "$novo_sudo_user" &>/dev/null && groups "$novo_sudo_user" | grep -qw sudo; then
                echo "O usuário $novo_sudo_user já possui permissões de sudo. Nenhuma ação necessária."
            else
                sed -i "/^sudo/s/$/$novo_sudo_user/" /etc/group
                echo "Permissões de sudo atualizadas para o usuário $novo_sudo_user."
            fi
        else
            echo "Permissões de sudo não foram alteradas."
        fi
        break
    done
}

# Função para instalar o nala
install_nala() 
{
    echo -e "\e[1;36mIniciando a instalação do 'nala'...\e[0m"
    apt install -y nala
    echo -e "\e[1;32m'nala' instalado com sucesso!\e[0m"
}


# Função para instalar o neofetch
install_neofetch() 
{
    echo -e "\e[1;36mIniciando a instalação do 'neofetch' com o nala...\e[0m"
    nala install -y neofetch
    echo -e "\e[1;32m'neofetch' instalado com sucesso!\e[0m"
}

# Função para instalar ferramentas de rede
install_network_tools() 
{
    echo -e "\e[1;36mIniciando a instalação do 'net-tools' & 'nmap' com o nala...\e[0m"
    nala install -y nmap && nala install -y net-tools
    echo -e "\e[1;32mPacotes instalados com sucesso!\e[0m"
}

# Função para atualizar o sistema
update_system() 
{
    echo -e "\e[1;36mAtualizando o sistema...\e[0m"
    if [ "$resposta" == "sim" ]; then
        nala update && nala upgrade
    else
        apt-get update && apt-get upgrade
    fi
    echo -e "\e[1;32mAtualização feita com sucesso!\e[0m"
}
   
main()
{
    # Emoji ASCII
    echo -e "\e[1;96m                                                             _                 "
    echo -e "\e[1;96m  _ __  _ __ _____  ___ __ ___   _____  __          ___  ___| |_ _   _ _ __ "
    echo -e "\e[1;96m | '_ \| '__/ _ \ \/ / '_ \` _ \ / _ \ \/ /         / __|/ _ \ __| | | | _  \\"
    echo -e "\e[1;96m | |_) | | | (_) >  <| | | | | | (_) >  <          \__ \  __/ |_| |_| | |_) |"
    echo -e "\e[1;96m | .__/|_|  \___/_/\_\_| |_| |_|\___/_/\_\  _____  |___/\___|\__|\__,_| .__/"
    echo -e "\e[1;96m |_|                                       |_____|                    |_|    "  
    echo -e "\e[0m"
    

    # Bem-vindo com estilo
    echo -e "\e[1;96m            Script desenvolvido por: \e[1;92mhttps://github.com/mathewalves\e[0m."
    echo ""
    echo ""
    echo -e "\e[1;96m --> Bem-vindo ao Script de Instalação do Proxmox no Debian 12 ~~\e[0m"
    echo -e "\e[;94m Este script instalará o Proxmox no seu Debian 12 e oferecerá a opção de instalar alguns pacotes adicionais...\e[0m"
    echo ""
    # Adicionando mensagem sobre reinicialização
    echo -e "\e[1;91mAVISO: Durante a instalação, o sistema pode reiniciar várias vezes. Evite Fechar o Script durante a instalação!\e[0m"
    echo -e "\e[1;93mPor favor, esteja ciente disso. Aperte 'Enter' para continuar...\e[0m" 
    read ok

    
    echo -e "\e[1;32mDeseja instalar os pacotes adicionais (Opcional)? Pacotes a serem instalados: 'sudo', 'nala',"
    echo -e "'neofetch', 'net-tools' e 'nmap'. (Digite 'sim' para continuar, 'pular' para pular):\e[0m"
    read -p "Resposta:  " resposta

    if [ "$resposta" == "sim" ]; then
        # Instalação de Pacotes adicionais
        install_nala
        install_sudo
        install_neofetch
        install_network_tools


        # Atualizar sistema
        update_system

        # Install proxmox parte 1
        ./scripts/install_proxmox-1.sh
    else 
    if [ "$resposta" != "pular" ]; then
        echo -e "\e[1;91mResposta inválida. Saindo do script.\e[0m"
        exit 1
    fi
        echo -e "\e[1;91mPulando para instalação do proxmox...\e[0m"
        ./scripts/install_proxmox-1.sh
    fi 
}

main
