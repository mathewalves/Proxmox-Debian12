# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo "Tornando-se superusuário..."
    sudo -E bash $0
    exit $?
fi

echo "Bem-vindo ao script de instalação do Proxmox no Debian 12 Bookworm"
echo "Este script também instalará alguns pacotes adicionais, como 'nala', 'net-tools', 'nmap' e 'neofetch'."

read -p "Deseja iniciar a instalação? (Digite 'sim' para continuar): " resposta

if [ "$resposta" != "sim" ]; then
    echo "Instalação cancelada. Saindo do script."
    exit 1
fi

echo "Iniciando a instalação..."

# Instalando pacotes
echo "Instalando 'nala'..."
apt install -y nala

echo "Instalando 'neofetch'..."
nala install -y neofetch

echo "Instalando 'net-tools'..."
nala install -y net-tools

echo "Instalando 'nmap'..."
nala install -y nmap

# Comandos de instalação do Proxmox

# Substitua este comentário pelos comandos reais de instalação do Proxmox e outros pacotes

echo "Instalação concluída com sucesso!"
echo "Lembre-se de configurar o Proxmox conforme necessário após a instalação."