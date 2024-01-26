#!/bin/bash

# Proxmox Setup v1.0.1
# by: Matheew Alves

cd /Proxmox-Debian12

# Load configs files // Carregar os arquivos de configuração
source ./configs/colors.conf
source ./configs/language.conf

welcome()
{
    # Welcome message and ASCII art block
    echo -e "${cyan} ${green}Welcome, $current_user!"

    # ASCII art block
echo -e "${red}
     ____  _________  _  ______ ___  ____  _  __
    / __ \/ ___/ __ \| |/_/ __ \`__ \/ __ \| |/_/
   / /_/ / /  / /_/ />  </ / / / / / /_/ />  <  
  / .___/_/   \____/_/|_/_/ /_/ /_/\____/_/|_|  ${yellow}https://pve.proxmox.com/${red}
 /_/              

 ${normal}"               

    # Check if neofetch is installed and display system information
    if command -v neofetch &> /dev/null; then
        echo ""
        neofetch
    fi

    # Get the IP address
    ip=$(hostname -I | cut -d' ' -f1)

    # Default Proxmox port number
    proxmox_port=8006

    # Welcome message with access information
echo -e "${yellow}
  +---------------------------------------------------------------------+
  |      To access the ${red}Proxmox${yellow} interface, open a browser and type:      |
 ###                    ${blue}https://$ip:$proxmox_port/${yellow}                  ###
  |               User: ${green}root${yellow} | Password: ${green}(root password)${yellow}                |
  +---------------------------------------------------------------------+

${default}"
}

bem_vindo()
{
    echo -e "${cyan} ${green}Bem-vindo, $current_user!"   

    # Bloco ASCII art
    echo -e "${red}
     ____  _________  _  ______ ___  ____  _  __
    / __ \/ ___/ __ \| |/_/ __ \`__ \/ __ \| |/_/
   / /_/ / /  / /_/ />  </ / / / / / /_/ />  <  
  / .___/_/   \____/_/|_/_/ /_/ /_/\____/_/|_|  ${yellow}https://pve.proxmox.com/${red}
 /_/              

 ${default}"               

    if command -v neofetch &> /dev/null; then
        echo ""
        neofetch
    fi

    # Obtendo o endereço IP
    ip=$(hostname -I | cut -d' ' -f1)

    # Número da porta padrão do Proxmox
    porta_proxmox=8006

   # Mensagem de boas-vindas
    echo -e "${yellow}
  +---------------------------------------------------------------------+
  |   Para acessar a interface do ${red}Proxmox${yellow}, abra um navegador e digite:  |
 ###                    ${blue}https://$ip:$porta_proxmox/${yellow}                  ###
  |                 Usuário: ${green}root${yellow} | Senha: ${green}(a senha do root)${yellow}            |
  +---------------------------------------------------------------------+

${default}"   
}

main()
{
    current_user=$(whoami)
    clear
    if [ "$LANGUAGE" == "en" ]; then
        welcome
    else
        bem_vindo
    fi
    cd ~
}

main