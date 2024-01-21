#!/bin/bash
# Tornando-se root
if [ "$(whoami)" != "root" ]; then
    echo -e "\e[1;92mTornando-se superusuário...\e[0m"
    sudo -E bash "$0" "$@"  # Executa o script como root
    exit $?
fi

echo "Script 2 iniciado em $(date)" >> /tmp/script2.log
read ok

# Remover o serviço do systemd
remove_service() 
{
    # Verificar se o serviço existe antes de tentar removê-lo
    if systemctl is-active --quiet meuservico.service; then
        systemctl stop meuservico.service
        systemctl disable meuservico.service
        rm /etc/systemd/system/meuservico.service
        systemctl daemon-reload
        echo "Serviço de agendamento de inicialização da 2ªParte do Script removida com Sucesso."
    else
        echo "Nenhum serviço de agendamento está ativo. Nenhuma ação necessária."
    fi
}

proxmox-ve_packages()
{
    if command -v nala &> /dev/null; then
        # Executar com 'nala' se estiver instalado
        nala install proxmox-ve postfix open-iscsi chrony
    else
        # Executar com 'apt' se 'nala' não estiver instalado
        apt install proxmox-ve postfix open-iscsi chrony
    fi
}

# Remover kernel do Debian
remove_kernel()
{
    if command -v nala &> /dev/null; then
        # Executar com 'nala' se estiver instalado
        nala remove linux-image-amd64 'linux-image-6.1*'
    else
        # Executar com 'apt' se 'nala' não estiver instalado
        apt remove linux-image-amd64 'linux-image-6.1*'
    fi

    update-grub
}

remove_os-prober()
{
   if command -v nala &> /dev/null; then
        # Executar com 'nala' se estiver instalado
        nala remove os-prober
    else
        # Executar com 'apt' se 'nala' não estiver instalado
        apt remove os-prober
    fi 
}

conexao()
{
    ip_address=$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /etc/hosts | tail -n 1 | awk '{print $1}')

    # Mensagem com ênfase no endereço IP
    echo -e "Conecte-se à interface web do Proxmox VE"
    echo -e "Conecte-se à interface web de administração (\e[1;34mhttps://${negrito}${verde}${ip_address}${normal}\e[0m:8006)."
    echo -e "Se você fez uma instalação recente e ainda não adicionou nenhum usuário, você deve selecionar a autenticação PAM e fazer login com a conta de usuário root."
}


main()
{
    negrito=$(tput bold)
    normal=$(tput sgr0)
    verde=$(tput setaf 2)

    proxmox-ve_packages
    remove_kernel
    remove_os-prober
    remove_service

    # Mensagem de instalação concluída com cores e efeitos
    echo -e "${negrito}${verde}Instalação concluída com sucesso!${normal}"

    conexao
}

main