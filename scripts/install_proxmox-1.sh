#!/bin/bash

cd /Proxmox-Debian12

# Carregar as variáveis de cores do arquivo colors.conf
source ./configs/colors.conf

install_proxmox-1()
{
    echo -e "${ciano}1º parte: Passo 1/3${normal}"

    # Obtendo o nome do host atual
    current_hostname=$(hostname)

    echo -e "${azul}nome do Host atual: ${ciano}"
    hostname
    echo -e "${normal}"
    
    # Exibindo interfaces de rede
    # Caminho para o diretório de configuração
    config_dir="./configs"
    config_file="$config_dir/network.conf"

    # Verificar se o diretório existe ou criar se não existir
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
    fi

    echo -e "${ciano}Selecione a sua interface de rede: [Digite o número]${normal}"
   # Função para exibir informações da interface
    exibir_informacoes_interface() {
        interface="$1"
        ip_address="$2"
        gateway="$3"

        echo -e "${azul}Informações da interface ${ciano}$interface"
        echo -e "${azul}Endereço IP: ${normal}$ip_address"
        echo -e "${azul}Gateway: ${normal}$gateway"
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
                read -r ip_address <<< "$(echo "${interfaces[$interface_option]}" | awk '{print $1}')"
                gateway="$(ip route show dev "$interface_option" | awk '/via/ {print $3}')"

                # Obter a máscara de sub-rede (por padrão, /24 se não especificado)
                mascara_subrede="$(ip addr show dev "$interface_option" | awk '/inet / {split($2, a, "/"); print a[2]}')"
                mascara_subrede="${mascara_subrede:-24}"

                # Adicionar a máscara de sub-rede ao endereço IP
                ip_address_with_mask="$ip_address/$mascara_subrede"

                exibir_informacoes_interface "$interface_option" "$ip_address" "$gateway"

                # Perguntar ao usuário se deseja selecionar essa interface
                read -p "Deseja selecionar essa interface? [S/N]: " escolha
                case "$escolha" in
                    [sS])
                        # Guardar as informações no arquivo network.conf
                        echo "INTERFACE=$interface_option" > "$config_file"
                        echo "IP_ADDRESS=$ip_address_with_mask" >> "$config_file"
                        echo "GATEWAY=$gateway" >> "$config_file"

                        echo -e "${verde}Configurações salvas no arquivo ${ciano}$config_file.${normal}"
                        break 2  # Sair do loop principal
                        ;;
                    [nN])
                        # Continuar com o restante do loop
                        ;;
                    *)
                        echo -e "${amarelo}Escolha inválida. Por favor, selecione novamente.${normal}"
                        ;;
                esac
            else
                echo -e "${amarelo}Por favor, selecione uma opção válida.${normal}"
            fi
        done
    done

    echo -e "${azul}Adicionando ou atualizando uma entrada em /etc/hosts para seu endereço IP...${normal}"
    # Verificar se o arquivo /etc/hosts já contém uma entrada para o nome do host
    if grep -qE "$ip_address\s+$current_hostname\.proxmox\.com\s+$current_hostname" /etc/hosts; then
        # A entrada já existe, atualize-a
        sed -i -E "s/($ip_address\s+$current_hostname\.proxmox\.com\s+$current_hostname).*/$ip_address       $current_hostname.proxmox.com $current_hostname/" /etc/hosts
        echo -e "${azul}A entrada para ${ciano}'$current_hostname'${azul} foi atualizada no arquivo ${ciano}/etc/hosts.${normal}"
    else 
        # A entrada não existe, adicione-a
        echo "$ip_address       $current_hostname.proxmox.com $current_hostname" | tee -a /etc/hosts > /dev/null
        echo -e "${verde}Entrada adicionada com sucesso ao arquivo ${ciano}/etc/hosts:${normal}"
        cat /etc/hosts | grep "$current_hostname"
    fi

    echo -e "${ciano}...${normal}"
}

install_proxmox-2()
{
    
    echo -e "${ciano}1º parte: Passo 2/3${normal}"
    echo -e "${ciano}Adicionando o repositório do Proxmox VE...${normal}"

    echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

    echo -e "${amarelo}Verificando Key...${normal}"

    # Calcula o hash da chave
    chave_hash=$(sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg | cut -d ' ' -f1)

    # Verifica se a chave está vazia
    if [ -z "$chave_hash" ]; then
    echo -e "${vermelho}Erro: A chave não corresponde à esperada ou está vazia. A instalação do Proxmox pode ser comprometida.${normal}"
    exit 1
    else
    echo -e "${verde}Sucesso: A chave corresponde à esperada.${normal}"
    fi

    apt-get update && apt-get -y full-upgrade


    echo -e "${ciano}...${normal}"

}

install_proxmox-3()
{
    echo -e "${ciano}1º parte: Passo 3/3"
    echo -e "Baixando o Proxmox VE Kernel... ${normal}"

     if command -v nala &> /dev/null; then
        # Executar com 'nala' se estiver instalado
        nala install -y proxmox-default-kernel
    else
        # Executar com 'apt' se 'nala' não estiver instalado
         apt install -y proxmox-default-kernel
    fi

    echo -e "${verde}Instalação da 1ºParte do ProxMox concluída com sucesso!${normal}"
}

reboot_setup()
{
    echo -e "${amarelo}A 2º Parte da instalação será iniciada após o proximo reboot.${normal}"

    # Exibe mensagem de aviso sobre a reinicialização
    echo -e "${amarelo}AVISO: O sistema precisará ser reiniciado. Salvando trabalho...${normal}"

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

        # Adicione as seguintes linhas ao final do arquivo /root/.bashrc
        echo "" >> /root/.bashrc
        echo "# Executar script após o login" >> /root/.bashrc
        echo "/Proxmox-Debian12/scripts/install_proxmox-2.sh" >> /root/.bashrc
        echo "" >> /root/.bashrc

        echo "Configuração automática concluída para o usuário root."
    done

    # Habilita o serviço para iniciar na inicialização

    echo -e "${verde}Trabalho Salvo!${ciano}"
    echo -e "${ciano}Reiniciado o sistema automaticamente para concluir a instalação...${normal}"

    # Aguarda alguns segundos antes de reiniciar
    sleep 5

    # Reinicia o sistema
    systemctl reboot
}

main()
{
    # Instalação do Proxmox
    echo -e "${ciano}iniciando instalação do Proxmox${normal}"
    install_proxmox-1
    install_proxmox-2
    install_proxmox-3
    reboot_setup
}

main