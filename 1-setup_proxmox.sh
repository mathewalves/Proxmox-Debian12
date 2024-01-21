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
    PS3="Selecione um usuário para adicionar permissões de sudo ou pressione Enter para pular: "
    select novo_sudo_user in "${all_sudo_users[@]}" "Pular"; do
        if [[ -n "$novo_sudo_user" ]]; then
            # Verifica se o usuário selecionado já tem permissões de sudo
            if id "$novo_sudo_user" &>/dev/null && groups "$novo_sudo_user" | grep -qw sudo; then
                echo "O usuário $novo_sudo_user já possui permissões de sudo. Nenhuma ação necessária."
            else
                usermod -aG sudo "$novo_sudo_user"
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
        echo "'neofetch' instalado com sucesso."
    else
        echo -e "\e[1;36mIniciando a instalação do 'neofetch' com o apt...\e[0m"
        apt install -y neofetch
        echo "'neofetch' instalado com sucesso."
    fi
}

# Função para instalar ferramentas de rede
install_network_tools() 
{
    if [ "$resposta_nala" == "sim" ]; then
        echo -e "\e[1;36mIniciando a instalação do 'net-tools' & 'nmap' com o nala...\e[0m"
        nala install -y nmap && nala install -y net-tools
        echo "Pacotes instalados com sucesso."
    else
        echo -e "\e[1;36mIniciando a instalação do 'net-tools' & 'nmap' com o apt...\e[0m"
        apt install -y nmap && apt install -y net-tools
        echo "Pacotes instalados com sucesso."
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
    echo "Atualização instalada com sucesso."
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

    # Comandos de instalação do Proxmox
    echo "iniciando instalação do Proxmox"
    echo "..."
    echo -e "\e[1;36m1º parte: Passo 1/3\e[0m"
    echo "Adicionando uma entrada em /etc/hosts para seu endereço ip."

    # Obtendo o nome do host atual
    current_hostname=$(hostname)

    echo "Seu hostname:"
    hostname

    # Exibir interfaces de rede
    echo "Suas interfaces de rede"
    ip addr | awk '/inet / {split($2, a, "/"); print $NF, a[1]}'

    # Solicitar o endereço IP
    read -p "Digite o seu endereço de IP da interface correta. exemplo: (192.168.0.113): " ip_address

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
        nala install proxmox-default-kernel
    else
        apt install proxmox-default-kernel
    fi

    if [ "$resposta_neofetch" == "sim" ]; then
        neofetch
    fi

    echo -e "\e[1;32mInstalação da 1ºParte do ProxMox concluída com sucesso!\e[0m"
}

reboot_proxmox()
{
    echo -e "\e[1;93Executando 2ºParte da instalação do ProxMox.\e[0m"

    # Exibe mensagem de aviso sobre a reinicialização
    echo -e "\e[1;91mAVISO: O sistema será reiniciado. Salvando trabalho...\e[0m"

    # Agendando a execução do restante do script após o reboot
    SERVICO_PATH="/etc/systemd/system/meuservico.service"
    echo "[Unit]" > "$SERVICO_PATH"
    echo "Description=Meu Serviço de Reinicialização" >> "$SERVICO_PATH"
    echo "" >> "$SERVICO_PATH"
    echo "[Service]" >> "$SERVICO_PATH"
    echo "ExecStart=$(readlink -f "$0")" >> "$SERVICO_PATH"
    echo "ExecStartPost=/Proxmox-Debian12/2-setup_proxmox.sh" >> "$SERVICO_PATH"  # Adição para executar o segundo script após o reboot
    echo "" >> "$SERVICO_PATH"
    echo "[Install]" >> "$SERVICO_PATH"
    echo "WantedBy=default.target" >> "$SERVICO_PATH"

    # Recarregar o daemon do systemd para reconhecer as alterações
    systemctl daemon-reload

    # Habilitar e iniciar o serviço
    systemctl enable meuservico.service
    systemctl start meuservico.service

    echo -e "\e[1;32mTrabalho Salvo!\e[1;0m"

    echo "Aperte 'Enter' Para reiniciar agora e executar a 2ªParte do script junto com o boot do sistema"
    echo "ou aperte 'Ctrl+C' para continuar usando o computador..."
    echo "Lembre-se: se cancelar o reboot agora você terá que iniciar a 2ªParte do script manualmente."
    echo "..."
    read ok

    # Reinicia o sistema
    echo -e "\e[1;91mReiniciando o Sistema...\e[0m"
    systemctl reboot
}

   

main()
{
    echo -e "\e[1;36m            ~ Bem-vindo ao Script de Instalação do Proxmox no Debian 12 ~ \e[0m"
    echo -e "\e[1;34mEste script instalará no seu Debian 12 o ProxMox e perguntará se você deseja instalar alguns pacotes adicionais,"
    echo -e "como 'sudo', 'nala', 'neofetch' e pacotes de ferramentas de rede como o 'net-tools' e 'nmap'.\e[0m"
    echo -e "\e[1;93mScript feito por https://github.com/mathewalves.\e[0m"

    echo -e "\e[1;93mAperte 'Enter' para continuar...\e[0m" 
    read ok

    read -p "Deseja a instalar o sudo no debian? (Digite 'sim' para continuar): " resposta_sudo
    
    if ["$resposta_sudo" != "sim"]; then
        echo -e "\e[1;91mContinuando a instalação sem o 'sudo'...\e[0m"
    else
       install_sudo
    fi
    

    read -p "Deseja iniciar a instalação dos pacotes adicionais? (Digite 'sim' para continuar, 'pular' para pular): " resposta

    if [ "$resposta" == "sim" ]; then

        # Perguntar nala
        read -p "Deseja instalar o 'nala'? (Opcional) (Digite 'sim' para instalar): " resposta_nala
        if [ "$resposta_nala" == "sim" ]; then
            install_nala
        else
            echo "Continuando a instalação sem 'nala'..."
        fi

        # Perguntar neofetch
        read -p "Deseja instalar o 'neofetch'? (Opcional) (Digite 'sim' para instalar): " resposta_neofetch
        if [ "$resposta_neofetch" == "sim" ]; then
            install_neofetch
        else
            echo "Continuando a instalação sem 'neofetch'..."
        fi

        # Perguntar ferramentas de rede
        read -p "Deseja instalar as ferramentas de rede 'net-tools' e 'nmap'? (Opcional) (Digite 'sim' para instalar): " resposta_net
        if [ "$resposta_net" == "sim" ]; then
            install_network_tools
        else
            echo "Continuando a instalação sem as ferramentas de rede..."
        fi

        # Atualizar sistema
        update_system

        # configure proxmox
        configure_proxmox
        reboot_proxmox
    else 
    if [ "$resposta" != "pular" ]; then
        echo "Resposta inválida. Saindo do script."
        exit 1
    fi
        echo "Pulando para outra parte do script..."
        configure_proxmox
        reboot_proxmox
    fi
    
}

main
