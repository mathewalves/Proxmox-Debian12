#!/bin/bash

# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo -e "${ciano}Tornando-se superusuário...${normal}"
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

cd /Proxmox-Debian12

chmod +x scripts/*
chmod +rw configs/*

# Carregar as variáveis de cores do arquivo colors.conf
source ./configs/colors.conf


# Função para instalar sudo
install_sudo() 
{
    echo -e "${ciano}Iniciando instalação do sudo...${normal}"
    nala install -y sudo

    echo -e "${azul}Procurando usuários para adicionar permissões sudo...${normal}"

    # Lista todos os usuários do sistema com permissões de sudo
    all_sudo_users=$(grep -E '^[^:]+:[^:]+:[0-9]{4,}' /etc/passwd | cut -d: -f1)

    # Pergunta ao usuário se deseja adicionar permissões de sudo
    PS3="Selecione um usuário para adicionar permissões de sudo ou digite 'pular' para pular: "
    select novo_sudo_user in $all_sudo_users; do
        if [[ -n "$novo_sudo_user" ]]; then
            # Verifica se o usuário selecionado já tem permissões de sudo
            if id "$novo_sudo_user" &>/dev/null && groups "$novo_sudo_user" | grep -qw sudo; then
                echo -e "${azul}O usuário ${ciano}$novo_sudo_user${azul} já possui permissões de sudo. Nenhuma ação necessária.${normal}"
            else
                sed -i "/^sudo/s/$/$novo_sudo_user/" /etc/group
                echo -e "${verde}Permissões de sudo atualizadas para o usuário:${ciano} $novo_sudo_user${normal}."
            fi
        else
            echo "${amarelo}Permissões de sudo não foram alteradas.${normal}"
        fi
        break
    done
}

# Função para instalar o nala
install_nala() 
{
    echo -e "${ciano}Iniciando a instalação do 'nala'...${normal}"
    apt install -y nala
    echo -e "${verde}'nala' instalado com sucesso!${normal}"
}


# Função para instalar o neofetch
install_neofetch() 
{
    echo -e "${ciano}Iniciando a instalação do 'neofetch' com o nala...${normal}"
    nala install -y neofetch
    echo -e "${verde}'neofetch' instalado com sucesso!${normal}"
}

# Função para instalar ferramentas de rede
install_network_tools() 
{
    echo -e "${ciano}Iniciando a instalação do 'net-tools' & 'nmap' com o nala...${normal}"
    nala install -y nmap && nala install -y net-tools
    echo -e "${verde}Pacotes instalados com sucesso!${normal}"
}

# Função para atualizar o sistema
update_system() 
{
    echo -e "${ciano}Atualizando o sistema...${normal}"
    if [ "$resposta" == "sim" ]; then
        nala update && nala upgrade
    else
        apt-get update && apt-get upgrade
    fi
    echo -e "${verde}Atualização feita com sucesso!${normal}"
}
   
main()
{
    # Emoji ASCII
    echo -e "${ciano}                                                             _                 "
    echo -e "${ciano}  _ __  _ __ _____  ___ __ ___   _____  __          ___  ___| |_ _   _ _ __ "
    echo -e "${ciano} | '_ \| '__/ _ \ \/ / '_ \` _ \ / _ \ \/ /         / __|/ _ \ __| | | | _  \\"
    echo -e "${ciano} | |_) | | | (_) >  <| | | | | | (_) >  <          \__ \  __/ |_| |_| | |_) |"
    echo -e "${ciano} | .__/|_|  \___/_/\_\_| |_| |_|\___/_/\_\  _____  |___/\___|\__|\__,_| .__/"
    echo -e "${ciano} |_|                                       |_____|                    |_|    "  
    echo -e "\e[0m"
    

    # Bem-vindo com estilo
    echo -e "${ciano}            Script desenvolvido por: \e[1;92mhttps://github.com/mathewalves${normal}."
    echo ""
    echo ""
    echo -e "${ciano} --> Bem-vindo ao Script de Instalação do Proxmox no Debian 12 ~~${normal}"
    echo -e "${azul} Este script instalará o Proxmox no seu Debian 12 e oferecerá a opção de instalar alguns pacotes adicionais...${normal}"
    echo ""
    # Adicionando mensagem sobre reinicialização
    echo -e "${vermelho}AVISO: Durante a instalação, o sistema pode reiniciar várias vezes. Evite Fechar o Script durante a instalação!${normal}"
    echo -e "${amarelo}Por favor, esteja ciente disso. Aperte 'Enter' para continuar...${normal}" 
    read ok

    
    echo -e "${azul}Deseja instalar os ${verde}pacotes adicionais${azul}? [S/N]?"
    read -p "Resposta:  " resposta

    # Converte a resposta para minúsculas antes de comparar
    resposta=$(echo "$resposta" | tr '[:upper:]' '[:lower:]')

    if [ "$resposta" == "s" ]; then
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
    if [ "$resposta" != "n" ]; then
        echo -e "${amarelo}Resposta inválida. Saindo do script.${normal}"
        exit 1
    fi
        echo -e "${ciano}Pulando instalação dos pacotes adicionais...${normal}"
        ./scripts/install_proxmox-1.sh
    fi 
}

main
