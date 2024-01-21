#!/bin/bash

# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo -e "\e[1;92mTornando-se superusuário...\e[0m"
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

# Função para instalar sudo
install_sudo() 
{
    echo -e "\e[1;32mIniciando instalação do sudo...\e[0m"
    apt-get install -y sudo

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
    echo "'nala' instalado com sucesso."
}


# Função para instalar o neofetch
install_neofetch() 
{
    if [ "$resposta_nala" == "sim" ]; then
        echo -e "\e[1;36mIniciando a instalação do 'neofetch' com o nala...\e[0m"
        nala install -y neofetch
        echo -e "\e[1;32m'neofetch' instalado com sucesso!\e[0m"
    else
        echo -e "\e[1;36mIniciando a instalação do 'neofetch' com o apt...\e[0m"
        apt install -y neofetch
        echo -e "\e[1;32m'neofetch' instalado com sucesso!\e[0m"
    fi
}

# Função para instalar ferramentas de rede
install_network_tools() 
{
    if [ "$resposta_nala" == "sim" ]; then
        echo -e "\e[1;36mIniciando a instalação do 'net-tools' & 'nmap' com o nala...\e[0m"
        nala install -y nmap && nala install -y net-tools
        echo -e "\e[1;32mPacotes instalados com sucesso!\e[0m"
    else
        echo -e "\e[1;36mIniciando a instalação do 'net-tools' & 'nmap' com o apt...\e[0m"
        apt install -y nmap && apt install -y net-tools
        echo -e "\e[1;32mPacotes instalados com sucesso!\e[0m"
    fi
}

# Função para atualizar o sistema
update_system() 
{
    echo -e "\e[1;36mAtualizando o sistema...\e[0m"
    if [ "$resposta_nala" == "sim" ]; then
        nala update && nala upgrade
    else
        apt-get update && apt-get upgrade
    fi
    echo -e "\e[1;32mAtualização feita com sucesso!\e[0m"
}

## Função para configurar o Proxmox
configure_proxmox() 
{
    read -p "Deseja iniciar a configuração do proxmox? (Digite 'sim' para continuar): " resposta

    if [ "$resposta" != "sim" ]; then
        echo "Instalação cancelada. Saindo do script."
        exit 1
    fi

    echo -e "\e[1;36mBem-vindo ao script de instalação do Proxmox no Debian 12 Bookworm\e[0m"
    echo -e "\e[1;91mAVISO: Durante a instalação, o sistema pode reiniciar várias vezes. Evite Fechar o Script durante a instalação!\e[0m"

    # Comandos de instalação do Proxmox
    echo "iniciando instalação do Proxmox"
    echo "..."
    echo -e "\e[1;36m1º parte: Passo 1/3\e[0m"
    echo "Adicionando uma entrada em /etc/hosts para seu endereço ip."

    # Obtendo o nome do host atual
    current_hostname=$(hostname)

    echo "Seu hostname:"
    hostname

    # Exibindo interfaces de rede
    echo -e "\e[1;36mSuas interfaces de rede:\e[0m"
    ip addr | awk '/inet / {split($2, a, "/"); print $NF, a[1]}'

    # Solicitando o endereço IP
    echo -e "\e[1;32mDigite o endereço de IP da interface correta (exemplo: 192.168.0.113): \e[0m"
    read -p "Resposta: " ip_address

    # Verificar se o arquivo /etc/hosts já contém uma entrada para o nome do host
    if grep -q "$current_hostname" /etc/hosts; then
        echo "O nome do host '$current_hostname' está presente no arquivo /etc/hosts."
    else 
        echo "Erro 01:"
        echo "O nome do host '$current_hostname' não está presente no arquivo /etc/hosts"
        exit 1
    fi

    # Adicionar a nova entrada ao arquivo /etc/hosts
    echo "$ip_address       $current_hostname.proxmox.com $current_hostname" | tee -a /etc/hosts > /dev/null

    echo "Entrada adicionada com sucesso ao arquivo /etc/hosts:"
    cat /etc/hosts | grep "$current_hostname"

    echo "Configuração de ip feita com sucesso:"
    hostname
    hostname --ip-address

    echo "..."
     echo -e "\e[1;36m1º parte: Passo 2/3\e[0m"
    echo "Adicionando o repositório do Proxmox VE."

    echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

    echo "Verificando Key..."

    # Calcula o hash da chave
    chave_hash=$(sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg | cut -d ' ' -f1)

    # Verifica se a chave está vazia
    if [ -z "$chave_hash" ]; then
    echo "Erro: A chave não corresponde à esperada ou está vazia. A instalação do Proxmox pode ser comprometida."
    exit 1
    else
    echo "Sucesso: A chave corresponde à esperada."
    fi

    if [ "$resposta_nala" == "sim" ]; then
        nala update && nala full-upgrade
    else
        apt update && apt full-upgrade
    fi

    echo "..."
    echo -e "\e[1;36m1º parte: Passo 3/3\e[0m"
    echo "Baixando o Proxmox VE Kernel."

    if [ "$resposta_nala" == "sim" ]; then
        nala install -y proxmox-default-kernel
    else
        apt install -y proxmox-default-kernel
    fi

    if [ "$resposta_neofetch" == "sim" ]; then
        neofetch
    fi

    echo -e "\e[1;32mInstalação da 1ºParte do ProxMox concluída com sucesso!\e[0m"
}

reboot_proxmox()
{
    echo -e "\e[1;93mExecutando 2º Parte da instalação do ProxMox.\e[0m"

    # Exibe mensagem de aviso sobre a reinicialização
    echo -e "\e[1;91mAVISO: O sistema precisará ser reiniciado. Salvando trabalho...\e[0m"

    chmod +x ./2-setup_proxmox.sh

    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"
        
        # Verifica se o arquivo de perfil existe antes de adicionar
        if [ -f "$PROFILE_FILE" ]; then
            # Adiciona a linha de execução do script ao final do arquivo
            echo "" >> "$PROFILE_FILE"
            echo "# Executar script após o login" >> "$PROFILE_FILE"
            echo "/Proxmox-Debian12/2-setup_proxmox.sh" >> "$PROFILE_FILE"
            echo "" >> "$PROFILE_FILE"

            echo "Configuração automática concluída para o usuário: $(basename "$user_home")."
        fi

        # Adiciona a execução do script ao sudoers
        echo "$(basename "$user_home") ALL=(ALL:ALL) NOPASSWD: /Proxmox-Debian12/2-setup_proxmox.sh" >> /etc/sudoers.d/proxmox_setup
        echo "Configuração do sudoers concluída para o usuário: $(basename "$user_home")."
    done

    # Habilita o serviço para iniciar na inicialização

    echo -e "\e[1;32mTrabalho Salvo!\e[0m"
    echo -e "\e[1;91mO sistema será reiniciado automaticamente para concluir a instalação.\e[0m"

    # Aguarda alguns segundos antes de reiniciar
    sleep 5

    # Reinicia o sistema
    systemctl reboot
}

   

main()
{
     # emoji ASCII
    echo -e "\e[1;96m"    
    echo -e "\e[1;96m                                                                  _       _   "
    echo -e "\e[1;96m  _ __  _ __ _____  ___ __ ___   _____  __          ___  ___ _ __(_)_ __ | |_ "
    echo -e "\e[1;96m | '_ \| '__/ _ \ \/ / '_ \` _ \ / _ \ \/ /         / __|/ __| '__| | '_ \| __|"
    echo -e "\e[1;96m | |_) | | | (_) >  <| | | | | | (_) >  <          \__ \ (__| |  | | |_) | |_ "
    echo -e "\e[1;96m | .__/|_|  \___/_/\_\_| |_| |_|\___/_/\_\  _____  |___/\___|_|  |_| .__/ \__|"
    echo -e "\e[1;96m |_|                                       |_____|                 |_|"  
    echo -e "\e[0m"   

    # Bem-vindo com estilo
    echo -e "\e[1;96m            Script desenvolvido por: \e[1;92mhttps://github.com/mathewalves\e[0m."
    echo ""
    echo ""
    echo -e "\e[1;96m --> Bem-vindo ao Script de Instalação do Proxmox no Debian 12 ~~\e[0m"
    echo -e "\e[;94m Este script instalará o Proxmox no seu Debian 12 e oferecerá a opção de instalar alguns pacotes adicionais,\e[0m"
    echo -e "\e[;94m como 'sudo', 'nala', 'neofetch', e ferramentas de rede como 'net-tools' e 'nmap'.\e[0m"
    echo ""
    # Adicionando mensagem sobre reinicialização
    echo -e "\e[1;91mAVISO: Durante a instalação, o sistema pode reiniciar várias vezes. Evite Fechar o Script durante a instalação!\e[0m"
    echo -e "\e[1;93mPor favor, esteja ciente disso. Aperte 'Enter' para continuar...\e[0m" 
    read ok

    echo -e "\e[1;32mDeseja instalar o sudo no Debian? (Digite 'sim' para continuar)\e[0m"
    read -p "Resposta: " resposta_sudo
    echo -e "\e[0m"
    
    if ["$resposta_sudo" != "sim"]; then
        echo -e "\e[1;91mContinuando a instalação sem o 'sudo'...\e[0m"
    else
       install_sudo
    fi
    
    echo -e "\e[1;32mDeseja iniciar a instalação dos pacotes adicionais? (Digite 'sim' para continuar, 'pular' para pular):\e[0m"
    read -p "Resposta:  " resposta
    echo -e "\e[0m"

    if [ "$resposta" == "sim" ]; then

        # Perguntar nala
        echo -e "\e[1;32mDeseja instalar o 'nala'? (Opcional) (Digite 'sim' para instalar): \e[0m"
        read -p "Resposta: " resposta_nala
        echo -e "\e[0m"

        if [ "$resposta_nala" == "sim" ]; then
            install_nala
        else
            echo -e "\e[1;91mContinuando a instalação sem 'nala'...\e[0m"
        fi

        # Perguntar neofetch
        echo -e "\e[1;32mDeseja instalar o 'neofetch'? (Opcional) (Digite 'sim' para instalar):  \e[0m"
        read -p "Resposta: " resposta_neofetch
        echo -e "\e[0m"

        if [ "$resposta_neofetch" == "sim" ]; then
            install_neofetch
        else
            echo -e "\e[1;91mContinuando a instalação sem 'neofetch'...\e[0m"
        fi

        # Perguntar ferramentas de rede
        echo -e "\e[1;32mDeseja instalar as ferramentas de rede 'net-tools' e 'nmap'? (Opcional) (Digite 'sim' para instalar): \e[0m"
        read -p "Resposta: " resposta_net
        echo -e "\e[0m"

        if [ "$resposta_net" == "sim" ]; then
            install_network_tools
        else
            echo -e "\e[1;91mContinuando a instalação sem as ferramentas de rede...\e[0m"
        fi

        # Atualizar sistema
        update_system

        # configure proxmox
        configure_proxmox
        reboot_proxmox
    else 
    if [ "$resposta" != "pular" ]; then
        echo -e "\e[1;91mResposta inválida. Saindo do script.\e[0m"
        exit 1
    fi
        echo -e "\e[1;91mPulando para outra parte do script...\e[0m"
        configure_proxmox
        reboot_proxmox
    fi
    
}

main
