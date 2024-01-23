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


 


    # Função para exibir informações da interface
    exibir_informacoes_interface() {
        interface="$1"
        ip_address="$2"
        gateway="$3"

        echo -e "\e[1;36mInformações da interface $interface:\e[0m"
        echo "Endereço IP: $ip_address"
        echo "Gateway: $gateway"
    }

    # Criar um array associativo para armazenar as informações
    declare -A interfaces

    # Preencher o array associativo com informações das interfaces
    while read -r interface ip_address _; do
        if [ -n "$interface" ]; then
            interfaces["$interface"]="$ip_address"
        fi
    done < <(ip addr show | awk '/inet / {split($2, a, "/"); print $NF, a[1]}')

    # Loop principal
    while true; do
        # Exibir opções para o usuário
        PS3="Selecione uma opção (Digite o número): "
        select interface_option in "${!interfaces[@]}"; do
            if [ -n "$interface_option" ]; then
                # Exibir informações completas da interface
                read -r ip_address <<< "${interfaces[$interface_option]}"
                gateway="$(ip route show dev "$interface_option" | awk '/via/ {print $3}')"

                # Obter a máscara de sub-rede (por padrão, /24 se não especificado)
                mascara_subrede="${ip_address##*/}"
                mascara_subrede="${mascara_subrede:-24}"

                # Adicionar a máscara de sub-rede ao endereço IP
                ip_address_with_mask="$ip_address/$mascara_subrede"

                exibir_informacoes_interface "$interface_option" "$ip_address_with_mask" "$gateway"

                # Perguntar ao usuário se deseja selecionar essa interface
                read -p "Deseja selecionar essa interface? (S/n): " escolha
                case "$escolha" in
                    [sS])
                        # Guardar as informações no arquivo network.conf
                        echo "INTERFACE=$interface_option" > "$config_file"
                        echo "IP_ADDRESS=$ip_address_with_mask" >> "$config_file"
                        echo "GATEWAY=$gateway" >> "$config_file"

                        echo -e "\e[1;36mConfigurações salvas no arquivo $config_file.\e[0m"
                        break 2  # Sair do loop principal
                        ;;
                    [nN])
                        # Continuar com o restante do loop
                        ;;
                    *)
                        echo -e "\e[1;31mEscolha inválida. Por favor, selecione novamente.\e[0m"
                        ;;
                esac
            else
                echo -e "\e[1;31mPor favor, selecione uma opção válida.\e[0m"
            fi
        done
    done


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
            echo "/Proxmox-Debian12/scripts/install_proxmox-2.sh" >> "$PROFILE_FILE"
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
    echo -e "\e[1;33mDeseja iniciar a configuração do Proxmox? (Digite 'sim' para continuar):\e[0m"
    read -p "Resposta: " resposta_proxmox

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