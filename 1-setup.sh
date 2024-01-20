#!/bin/bash

echo "Este script instalará no seu Debian o 'sudo' e perguntará se você deseja instalar alguns pacotes adicionais, 
como 'nala', 'neofetch' e pacotes de ferramentas de rede: 'net-tools' e 'nmap'."

read -p "Deseja iniciar a instalação? (Digite 'sim' para continuar): " resposta

if [ "$resposta" != "sim" ]; then
    echo "Instalação cancelada. Saindo do script."
    exit 1
fi

echo "Iniciando a instalação..."
apt-get update

# Instalando pacotes ---------------------->

# sudo
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

# nala
read -p "Deseja instalar o 'nala'? (Opcional) (Digite 'sim' para instalar): " resposta_nala

if [ "$resposta_nala" == "sim" ]; then
    echo "Iniciando a instalação do 'nala'..."
    apt install -y nala
    echo "'nala' instalado com sucesso."
else
    echo "Continuando a instalação sem 'nala'..."
fi

read -p "Deseja instalar o 'neofetch'? (Opcional) (Digite 'sim' para instalar): " resposta_neofetch

if [ "$resposta_neofetch" == "sim" ]; then
    if [ "$resposta_nala" == "sim" ]; then
        echo "Iniciando a instalação do 'neofetch' com o nala..."
        nala install -y neofetch
        echo "'neofetch' instalado com sucesso."
    else
        echo "Iniciando a instalação do 'neofetch' com o apt..."
        apt install -y neofetch
        echo "'neofetch' instalado com sucesso."
    fi
else
    echo "Continuando a instalação sem o 'neofetch'..."
fi

# ferramentas de rede
read -p "Deseja instalar as ferramentas de rede 'net-tools' e 'nmap'? (Opcional) (Digite 'sim' para instalar): " resposta_net
if [ "$resposta_net" == "sim" ]; then
    if [ "$resposta_nala" == "sim" ]; then
        echo "Iniciando a instalação do 'net-tools' & 'nmap' com o nala..."
        nala install -y nmap && nala install -y net-tools
        echo "Pacotes instalados com sucesso."
    else
        echo "Iniciando a instalação do 'net-tools' & 'nmap' com o apt..."
        apt install -y nmap && apt install -y net-tools
        echo "Pacotes instalados com sucesso."
    fi
else
    echo "Continuando a instalação sem as ferramentas de rede..."
fi

 if [ "$resposta_nala" == "sim" ]; then
        echo "Atualizando o sistema..."
        nala update && nala upgrade
        echo "Atualização instalada com sucesso."
    else
        echo "Iniciando a instalação do 'net-tools' & 'nmap' com o apt..."
        apt-get update && apt-get upgrade
        echo "Atualização instalada com sucesso."
    fi

# Se o usuário atual foi modificado, atualiza as permissões imediatamente
if [ "$resposta" == "sim" ]; then
    su - "$current_user" -c "bash -c 'id;'"  # Comando dummy para efetuar login e atualizar as permissões
fi

# Ir para próxima etapa
read -p "Deseja iniciar a instalação e configuração do proxmox? (Digite 'sim' para continuar): " resposta

if [ "$resposta" != "sim" ]; then
    echo "Saindo do script."
    exit 1
else
    ./2-proxmox.sh
fi
