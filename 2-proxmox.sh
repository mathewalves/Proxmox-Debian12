# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo "Tornando-se superusuário..."
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

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



echo "Instalação concluída com sucesso!"
echo "Lembre-se de configurar o Proxmox conforme necessário após a instalação."