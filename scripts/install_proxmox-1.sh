#!/bin/bash
install_proxmox-1()
{
    echo -e "\e[1;36m1º parte: Passo 1/3\e[0m"
    echo "Adicionando uma entrada em /etc/hosts para seu endereço ip."

    # Obtendo o nome do host atual
    current_hostname=$(hostname)

    echo "Seu hostname:"
    hostname
    
    # Exibindo interfaces de rede
    # Caminho para o diretório de configuração
    config_dir="./configs"
    config_file="$config_dir/network.conf"

    # Verificar se o diretório existe ou criar se não existir
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
    fi

    # Exibindo informações de rede
    echo -e "\e[1;36mSuas interfaces de rede:\e[0m"

    # Criar um array associativo para armazenar as informações
    declare -A interfaces

    # Preencher o array associativo com informações das interfaces
    while read -r interface ip_address mascara_subrede gateway; do
        if [ -n "$interface" ]; then
            interfaces["$interface"]="$ip_address"
        fi
    done < <(ip addr | awk '/inet / {split($2, a, "/"); print $NF, a[1], $4, $6}')

    # Exibir opções para o usuário
    select interface_option in "${!interfaces[@]}"; do
        if [ -n "$interface_option" ]; then
            break
        else
            echo -e "\e[1;31mPor favor, selecione uma opção válida.\e[0m"
        fi
    done

    # Exibir informações selecionadas
    echo -e "\e[1;36mInformações da interface selecionada:\e[0m"
    echo "Interface: $interface_option"
    echo "Endereço IP: ${interfaces[$interface_option]}"

    # Extraindo informações
    read -r ip_address mascara_subrede gateway <<< "${interfaces[$interface_option]}"

    # Solicitando o endereço IP
    echo -e "\e[1;32mDigite o endereço de IP da interface correta (exemplo: 192.168.0.128): \e[0m"
    read -p "Resposta: " novo_ip_address

    # Guardar o endereço de IP, máscara de sub-rede e gateway no arquivo network.conf
    echo "INTERFACE=$interface_option" > "$config_file"
    echo "IP_ADDRESS=${novo_ip_address:-$ip_address}" >> "$config_file"
    echo "MASCARA_SUBREDE=$mascara_subrede" >> "$config_file"
    echo "GATEWAY=$gateway" >> "$config_file"

    echo -e "\e[1;36mConfigurações salvas no arquivo $config_file.\e[0m"
    read -p "crt+c" ok

    # Verificar se o arquivo /etc/hosts já contém uma entrada para o nome do host
    if grep -q "$current_hostname" /etc/hosts; then
        echo "O nome do host '$current_hostname' está presente no arquivo /etc/hosts."
    else 
        echo "Erro 01:"
        echo "O nome do host '$current_hostname' não está presente no arquivo /etc/hosts"
        exit 1
    fi

    # Adicionar a nova entrada ao arquivo /etc/hosts
    echo "${novo_ip_address:-$ip_address}       $current_hostname.proxmox.com $current_hostname" | tee -a /etc/hosts > /dev/null

    echo "Entrada adicionada com sucesso ao arquivo /etc/hosts:"
    cat /etc/hosts | grep "$current_hostname"

    echo "..."
}

install_proxmox-2()
{
    
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

    if [ "$resposta" == "sim" ]; then
        nala update && nala full-upgrade
    else
        apt update && apt full-upgrade
    fi

    echo "..."

}

install_proxmox-3()
{
    echo -e "\e[1;36m1º parte: Passo 3/3\e[0m"
    echo "Baixando o Proxmox VE Kernel."

    if [ "$resposta" == "sim" ]; then
        nala install -y proxmox-default-kernel
    else
        apt install -y proxmox-default-kernel
    fi

    if [ "$resposta" == "sim" ]; then
        neofetch
    fi

    echo -e "\e[1;32mInstalação da 1ºParte do ProxMox concluída com sucesso!\e[0m"
}

reboot_setup()
{
    echo -e "\e[1;93mExecutando 2º Parte da instalação após o reboot do ProxMox.\e[0m"

    # Exibe mensagem de aviso sobre a reinicialização
    echo -e "\e[1;91mAVISO: O sistema precisará ser reiniciado. Salvando trabalho...\e[0m"

    for user_home in /home/*; do
        PROFILE_FILE="$user_home/.bashrc"
        
        # Verifica se o arquivo de perfil existe antes de adicionar
        if [ -f "$PROFILE_FILE" ]; then
            # Adiciona a linha de execução do script ao final do arquivo
            echo "" >> "$PROFILE_FILE"
            echo "# Executar script após o login" >> "$PROFILE_FILE"
            echo "/Proxmox-Debian12/script/install_proxmox-2.sh" >> "$PROFILE_FILE"
            echo "" >> "$PROFILE_FILE"

            echo "Configuração automática concluída para o usuário: $(basename "$user_home")."
        fi

        # Adiciona a execução do script ao sudoers
        echo "$(basename "$user_home") ALL=(ALL:ALL) NOPASSWD: /Proxmox-Debian12/scripts/install_proxmox-2.sh" >> /etc/sudoers.d/proxmox_setup
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
    read -p "Deseja iniciar a configuração do proxmox? (Digite 'sim' para continuar): " resposta_proxmox

    if [ "$resposta_proxmox" != "sim" ]; then
        echo "Instalação cancelada. Saindo do script."
        exit 1
    fi

    echo -e "\e[1;36mBem-vindo ao script de instalação do Proxmox no Debian 12 Bookworm\e[0m"
    echo -e "\e[1;91mAVISO: Durante a instalação, o sistema pode reiniciar várias vezes. Evite Fechar o Script durante a instalação!\e[0m"

    # Comandos de instalação do Proxmox
    echo "iniciando instalação do Proxmox"
    echo "..."
    install_proxmox-1
    install_proxmox-2
    install_proxmox-3
    reboot_setup
}

main