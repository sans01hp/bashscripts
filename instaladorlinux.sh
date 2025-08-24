#!/usr/bin/env bash

# Definição das cores ANSI
YELLOW="\033[93m"
GREEN_BOLD="\033[1;32m"
CYAN_BOLD="\033[1;36m"
GREEN_LIGHT="\033[1;92m"
CYAN="\033[36m"
GREEN="\033[92m"
CYAN_LIGHT="\033[96m"
RED_BOLD="\033[1;91m"
YELLOW_BOLD="\033[1;93m"
BLUE_LIGHT="\033[94m"
PURPLE_LIGHT="\033[95m"
RESET="\033[0m"

printf "${YELLOW}Esse script foi feito com o propósito de ser usado no Kali para o userland${RESET}\n"
sleep 2

if [ "$(uname)" != "Linux" ]; then
    printf "${GREEN_BOLD}Você não está usando um sistema GNU/Linux ou similar${RESET}\n"
    exit 1
fi

printf "${CYAN_BOLD}Vamos começar atualizando o ${GREEN_LIGHT}Linux...${RESET}\n"
sleep 3
cd
sudo apt update -y

printf "${CYAN}Instalando linguagens de programação e ferramentas necessárias...${RESET}\n"
sleep 3

# Instalando pacotes
sudo apt install python3 -y
sudo apt install pypy3-venv -y
sudo apt install golang -y
sudo apt install curl -y
sudo apt install wget -y
sudo apt install iputils-ping -y
sudo apt install openssh-client -y
sudo apt install micro -y

printf "${YELLOW_BOLD}Editor ${GREEN_LIGHT}micro ${YELLOW_LIGHT}instalado. Use se precisar de autocomplete para comandos${RESET}\n"

printf "${CYAN}Configurando Micro para Python LSP...${RESET}\n"
sleep 2

# Instala python-lsp-server via pipx para suporte a LSP
sudo apt install pipx -y
pipx ensurepath
pipx install 'python-lsp-server[all]'

# Criar diretório de configuração do micro e habilitar plugin LSP
MICRO_CONFIG_DIR="$HOME/.config/micro"
mkdir -p "$MICRO_CONFIG_DIR/settings.json"

cat > "$MICRO_CONFIG_DIR/settings.json" <<setup 
{
    "plugin": ["lsp"],
    "lspservers": {
        "python": {
            "command": "pylsp"
        }
    }
}
setup

printf "${GREEN_BOLD}Micro configurado para suporte a Python LSP${RESET}\n"

# Instalando ferramentas Go
declare -A ferramentas=(
    ["kxss"]="github.com/Emoe/kxss@latest"
    ["subfinder"]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    ["httpx"]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
    ["gau"]="github.com/lc/gau/v2/cmd/gau@latest"
    ["anew"]="github.com/tomnomnom/anew@latest"
    ["ffuf"]="github.com/ffuf/ffuf@latest"
    ["getJS"]="github.com/003random/getJS@latest"
    ["nuclei"]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
)

printf "${CYAN}Instalando ferramentas em Golang...${RESET}\n"
sleep 2
for ferramenta in "${!ferramentas[@]}"; do
    printf "${GREEN}Instalando ${CYAN_LIGHT}%s...${RESET}\n" "${ferramenta}"
    sleep 1
    go install -v "${ferramentas[$ferramenta]}"
done

# Clonando repositórios
declare -A links=(
    ["ParamSpider"]="https://github.com/devanshbatham/ParamSpider"
    ["sherlock"]="https://github.com/sherlock-project/sherlock"
    ["git-dumper"]="https://github.com/arthaud/git-dumper"
    ["zphisher"]="https://github.com/htr-tech/zphisher"
    ["sqlmap"]="https://github.com/sqlmapproject/sqlmap"
    ["https-github.com-Rajkumrdusad-Tool-X"]="https://github.com/vaibhavguru/https-github.com-Rajkumrdusad-Tool-X.git"
    ["codigos_para_aprendizado"]="https://github.com/sans01hp/codigos_para_aprendizado"
    ["nuclei-templates"]="https://github.com/projectdiscovery/nuclei-templates"
)

printf "${CYAN}Baixando repositórios necessários...${RESET}\n"
for repo in "${!links[@]}"; do
    if [ ! -d "$repo" ]; then
        printf "Clonando %s...\n" "${repo}"
        git clone "${links[$repo]}"
    else
        printf "${GREEN}Atualizando repositório ${CYAN_LIGHT}%s...${RESET}\n" "${repo}"
        git -C "$repo" reset --hard
        git -C "$repo" pull
    fi
done

# Criando ambiente virtual e instalando pacotes Python

python3 -m venv ~/piplibs
source ~/piplibs/bin/activate

for repo in "${!links[@]}"; do
    REPO_PATH="./${repo}"
    if [ -f "$REPO_PATH/setup.py" ] || [ -f "$REPO_PATH/pyproject.toml" ]; then
        printf "${GREEN_BOLD}Tentando instalar $repo com pip${RESET}\n"
        pip install "$REPO_PATH" || printf "${RED_BOLD}Falha ao instalar $repo com pip. Instale manualmente se necessário.${RESET}\n"

        if [ -f ~/piplibs/bin/${repo} ]; then
            sudo ln -sf ~/piplibs/bin/${repo} /usr/local/bin/${repo}
        fi
    else
        printf "${YELLOW_BOLD}Repositório $repo não é um pacote Python instalável. Instalação manual será necessária.${RESET}\n"
    fi
done 

deactivate
printf "${GREEN_BOLD}Instalação concluída${RESET}\n"
sleep 2

# Criando links simbólicos para ferramentas Go

for go_tool in ~/go/bin/*; do
    tool_name=$(basename "$go_tool")
    sudo ln -sf "$go_tool" /usr/local/bin/"$tool_name"
done

printf "${YELLOW}Aviso: ${GREEN}As ferramentas em Golang foram linkadas para /usr/local/bin para facilitar o uso das mesmas.${RESET}\n"

# Exemplos de uso
printf "\nExemplos de uso das ferramentas instaladas:\n"
printf "1. subfinder: ${CYAN_LIGHT}subfinder -d alvo${RESET}\n"
printf "2. ffuf: ${BLUE_LIGHT}ffuf -u alvo/FUZZ -w caminho/da/wordlist${RESET}\n"
printf "3. nuclei: ${PURPLE_LIGHT}nuclei -u alvo -t nuclei-templates/cves${RESET}\n"
printf "4. micro: ${GREEN_LIGHT}micro arquivo.py${RESET}\n"
