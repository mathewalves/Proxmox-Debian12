[![Version](https://img.shields.io/badge/Version-1.0.1-red.svg)](version) [![License](https://img.shields.io/badge/License-BSD--Clause_3-green.svg)](LICENSE) [![Readme em Português e Inglês](https://img.shields.io/badge/README-en%2Fpt--br-blue)](#)

```bash
                                                                  _               
             _ __  _ __ _____  ___ __ ___   _____  __    ___  ___| |_ _   _ _ __  
            | '_ \| '__/ _ \ \/ / '_ ` _ \ / _ \ \/ /   / __|/ _ \ __| | | | '_ \ 
            | |_) | | | (_) >  <| | | | | | (_) >  <    \__ \  __/ |_| |_| | |_) |
            | .__/|_|  \___/_/\_\_| |_| |_|\___/_/\_\___|___/\___|\__|\__,_| .__/ 
            |_|                                    |_____|                 |_|     v1.0.1  
```

[![Language](https://img.shields.io/badge/🌎-English:-blue)](#)

# Proxmox VE Installer on Debian 12 Bookworm

This setup/script automates the installation of Proxmox on Debian 12 and the creation of a bridge to facilitate network configuration.

**Note: This script is designed to run on a Debian 12 system. Make sure to have superuser permissions before executing the script.**

## Requirements

- Installed Debian 12 Bookworm
- Superuser permissions
  ```bash
  su root
  ```
- Installed Git
  ```bash
  apt install git
  ```
- (Important) Clone the repository from the directory:

  ```bash
   cd /
  ```

## Usage Instructions

1. Clone the repository to your Debian 12 system.
```bash
# With git already installed on your machine, clone the repository
git clone https://github.com/mathewalves/Proxmox-Debian12.git

# Access the downloaded folder with the 'cd' command
cd /Proxmox-Debian12
```
2. Make the script executable.
```bash
# Give execution permission to the setup
chmod +x ./setup
```

3. Run the setup.
```bash
./setup
```

## Additional Packages

The script installs some additional packages to enhance the experience and provide additional functionalities. The packages include:

1. **'sudo':** Essential tool to grant administrative permissions to the selected user.
2. **'nala':** An application that enhances the graphical interface of 'apt'.
3. **'neofetch':** A system information display tool with a colorful and user-friendly interface.
4. **'net-tools':** A classic set of network utilities, such as ifconfig and route.
5. **'nmap':** A powerful network scanning and security auditing tool.

Make sure to review the official documentation for each package for more details on their functionalities.

## Features

1. **Proxmox Installation:** The script automatically installs Proxmox on the Debian 12 base.

2. **Additional Packages:** These additional packages are installed to enhance the user experience and provide useful tools for the system and Proxmox environment.

3. **Bridge Creation:** Facilitates network configuration by creating a bridge named vmbr0. You can choose to configure manually or use DHCP.

## Updates and Support

For support or to report issues, [ open an issue](https://github.com/mathewalves/Proxmox-Debian12/issues).

## License
This script is distributed under the [BSD 3-Clause License](https://opensource.org/licenses/BSD-3-Clause).

## Acknowledgments

Thank you for using the Proxmox Installation Script on Debian 12
If you come across any improvements or would like to contribute, feel free to create a pull request. Your contributions are welcome to enhance this script.

We appreciate your participation in the community and your contribution to the ongoing development of this script.

**Enjoy Proxmox!** 🚀

---

[![Language](https://img.shields.io/badge/🇧🇷-PT--BR:-green)](#)


# Instalador do Proxmox VE no Debian 12 Bookworm

Este setup/script automatiza a instalação do Proxmox sobre o Debian 12 e a criação da bridge para facilitar a configuração de redes.

**Nota: Este script foi projetado para ser executado em um sistema Debian 12. Certifique-se de ter permissões de superusuário antes de executar o script.**

## Requisitos

- Debian 12 Bookworm instalado
- Permissões de superusuário
  ```bash
  su root
  ```
- Git instalado
  ```bash
  apt install git
  ```
- (Importante) Clonar o repositório apartir do diretório:

  ```bash
   cd /
  ```

## Instruções de Uso

1. Clone o repositório para o seu sistema Debian 12.
```bash
# Com o git já instalado na sua máquina clone o repositório
git clone https://github.com/mathewalves/Proxmox-Debian12.git

# Acesse a pasta baixada com o comando 'cd'
cd /Proxmox-Debian12
```
2. Torne o script executável.
```bash
# Dá permissão de execução para o setup
chmod +x ./setup
```

3. Execute o setup.
```bash
./setup
```

## Pacotes Adicionais

O script instala alguns pacotes adicionais para melhorar a experiência e fornecer funcionalidades adicionais. Os pacotes incluem:

1. **'sudo':** Ferramenta essencial para conceder permissões administrativas ao usuário selecionado.
2. **'nala':** Uma aplicação que melhora a interface gráfica do 'apt'.
3. **'neofetch':** Uma ferramenta de exibição de informações do sistema com uma interface colorida e amigável.
4. **'net-tools':** Conjunto de utilitários clássicos de rede, como ifconfig e route.
5. **'nmap':** Uma poderosa ferramenta de exploração de rede e auditoria de segurança.

Certifique-se de revisar a documentação oficial de cada pacote para obter mais detalhes sobre suas funcionalidades.

## Funcionalidades

1. **Instalação do Proxmox:** O script instala automaticamente o Proxmox sobre a base do Debian 12.

2. **Pacotes Adicionais:** Esses pacotes adicionais são instalados para melhorar a experiência do usuário e fornecer ferramentas úteis para o sistema e para o ambiente Proxmox.

3. **Criação de Bridge:** Facilita a configuração de redes criando uma bridge chamada `vmbr0`. Você pode optar por configurar manualmente ou usar DHCP.

## Atualizações e Suporte

Para obter suporte ou relatar problemas, [abra uma issue](https://github.com/mathewalves/Proxmox-Debian12/issues).

## Licença

Este script é distribuído sob a licença [BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause).

## Agradecimentos

Se você identificar oportunidades de melhoria ou quiser contribuir, sinta-se à vontade para criar um pull request. Estamos abertos a colaborações para aprimorar esta ferramenta.

Agradecemos por fazer parte da comunidade e por contribuir para o desenvolvimento contínuo deste script.

**Divirta-se com o Proxmox!** 🚀