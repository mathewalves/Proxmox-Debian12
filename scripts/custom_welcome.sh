#!/bin/bash
cd /Proxmox-Debian12
source ./configs/colors.conf

welcome()
{
    current_user=$(whoami)
    echo -e "${ciano} ${verde}Bem-vindo, $current_user!"   

    # Bloco ASCII art
    echo -e "${vermelho}
     ____  _________  _  ______ ___  ____  _  __
    / __ \/ ___/ __ \| |/_/ __ \`__ \/ __ \| |/_/
   / /_/ / /  / /_/ />  </ / / / / / /_/ />  <  
  / .___/_/   \____/_/|_/_/ /_/ /_/\____/_/|_|  ${amarelo}https://pve.proxmox.com/${vermelho}
 /_/              

 ${normal}"               

    if command -v neofetch &> /dev/null; then
        echo ""
        neofetch
    fi

    # Obtendo o endereço IP
    ip=$(hostname -I | cut -d' ' -f1)

    # Número da porta padrão do Proxmox
    porta_proxmox=8006

   # Mensagem de boas-vindas
    echo -e "${amarelo}
  +---------------------------------------------------------------------+
  |   Para acessar a interface do ${vermelho}Proxmox${amarelo}, abra um navegador e digite:  |
 ###                    ${azul}https://$ip:$porta_proxmox/${amarelo}                  ###
  |                 Usuário: ${verde}root${amarelo} | Senha: ${verde}(a senha do root)${amarelo}            |
  +---------------------------------------------------------------------+

${normal}"
}

main()
{
    clear
    welcome
    cd ~
}

main