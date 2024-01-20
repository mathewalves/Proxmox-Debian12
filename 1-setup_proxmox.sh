#!/bin/bash

# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo "Tornando-se superusuário..."
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

# Função para instalar sudo
install_sudo()
{
    echo "Iniciando instalação do sudo..."
    apt-get install -y sudo

    echo "Selecione um usuário para adicionar permissões sudo:"

    # Lista todos os usuários do sistema
    all_users=$(grep -E '^[^:]+:[^:]+:[0-9]{4,}' /etc/passwd | cut -d: -f1)

    # Mostra uma lista numerada de usuários
    select current_user in $all_users; do
        if [ -n "$current_user" ]; then
            # Verifica se o usuário selecionado existe
            if id "$current_user" >/dev/null 2>&1; then
                sed -i "/^sudo/s/$/,$current_user/" /etc/group
                echo "Permissões de sudo atualizadas para o usuário $current_user."
            else
                echo "Usuário $current_user não encontrado."
            fi
            break
        else
            echo "Opção inválida. Tente novamente."
        fi
    done

    # Se o usuário atual foi modificado, atualiza as permissões imediatamente
    if [ "$resposta" == "sim" ]; then
        su - "$current_user" -c "bash -c 'id;'"  # Comando dummy para efetuar login e atualizar as permissões
    fi
}

# Função para instalar o nala
install_nala() 
{

    echo "Iniciando a instalação do 'nala'..."
    apt install -y nala
    echo "'nala' instalado com sucesso."
}

# Função para instalar o neofetch
install_neofetch() 
{
    if [ "$resposta_nala" == "sim" ]; then
        echo "Iniciando a instalação do 'neofetch' com o nala..."
        nala install -y neofetch
        echo "'neofetch' instalado com sucesso."
    else
        echo "Iniciando a instalação do 'neofetch' com o apt..."
        apt install -y neofetch
        echo "'neofetch' instalado com sucesso."
    fi
}

# Função para instalar ferramentas de rede
install_network_tools() 
{

    if [ "$resposta_nala" == "sim" ]; then
        echo "Iniciando a instalação do 'net-tools' & 'nmap' com o nala..."
        nala install -y nmap && nala install -y net-tools
        echo "Pacotes instalados com sucesso."
    else
        echo "Iniciando a instalação do 'net-tools' & 'nmap' com o apt..."
        apt install -y nmap && apt install -y net-tools
        echo "Pacotes instalados com sucesso."
    fi
}

# Função para atualizar o sistema
update_system() 
{
    echo "Atualizando o sistema..."
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

    echo "Bem-vindo ao script de instalação do Proxmox no Debian 12 Bookworm"

    # Comandos de instalação do Proxmox
    echo "iniciando instalação do Proxmox"
    echo "..."
    echo "Passo 1/4"
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
    echo "Passo 2/4"
    echo "Adicionando o repositório do Proxmox VE."

    echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

    echo "Verificando Key..."

    if [ "$(sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg | cut -d ' ' -f1)" != "chave_esperada" ]; then
        echo "Erro: A chave não corresponde à esperada. A instalação do Proxmox pode ser comprometida."
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
    echo "Passo 3/4"
    echo "Install the Proxmox VE Kernel."

    if [ "$resposta_nala" == "sim" ]; then
        nala install proxmox-default-kernel
    else
        apt install proxmox-default-kernel
    fi

    echo "Instalação concluída com sucesso!"
    echo "Lembre-se de configurar o Proxmox conforme necessário após a instalação."

    # Exibe mensagem de aviso sobre a reinicialização
    echo "AVISO: O sistema será reiniciado. Salvando trabalho..."

    # Agendando a execução do restante do script após o reboot
    echo "(sleep 5 && /Proxmox-Debian12/2-setup_proxmox.sh) | at now + 1 minute"

    # Reinicia o sistema
    systemctl reboot
}

   

main()
{
    echo "Este script instalará no seu Debian o 'sudo' e perguntará se você deseja instalar alguns pacotes adicionais, 
    como 'nala', 'neofetch' e pacotes de ferramentas de rede: 'net-tools' e 'nmap'."

    read ok

    # Instalar sudo
    install_sudo

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
    else 
    if [ "$resposta" != "pular" ]; then
        echo "Resposta inválida. Saindo do script."
        exit 1
    fi
        echo "Pulando para outra parte do script..."
        configure_proxmox
    fi
    
}

main
