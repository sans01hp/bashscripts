#!/bin/bash

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


printf "${CYAN_BOLD} Vamos começar atualizando o ${GREEN_LIGHT}Linux...${RESET}\n"
sleep 3

cd

sudo apt update -y


printf "${CYAN}Instalando linguagens de programação e ferramentas necessárias....${RESET}\n"
sleep 3

# Instalando pacotes
sudo apt install python3 -y
sudo apt install pypy3-venv -y
sudo apt install golang -y
sudo apt install curl -y
sudo apt install wget -y

printf "${CYAN} Instalando ferramentas em Golang...${RESET}\n"
sleep 3

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

for ferramenta in "${!ferramentas[@]}"; do
    printf "${GREEN}Instalando ${CYAN_LIGHT}%s...${RESET}\n" "${ferramenta}"
    sleep 1
    go install -v "${ferramentas[$ferramenta]}"
done


printf "${CYAN}Baixando repositórios de outras ferramentas necessárias para o script ${GREEN}testadordeurl${RESET}...\n"
printf "${RED_BOLD}Algumas ferramentas possuem instalações diferentes. Verifique como instalar as ferramentas pesquisando elas em ${GREEN}https://github.com${RESET}\n"
printf "${GREEN}Baixando pipx${RESET}\n"

# O kali linux deixou de usar o pip e recomenda o uso do pipx, mais a frente um ambiente virtual será criado para usar o pip para instalar as ferramentas
sudo apt install pipx -y

sleep 3

# Baixando Repositórios
declare -A links=(
    ["ParamSpider"]="https://github.com/devanshbatham/ParamSpider"
    ["Cam-Hackers"]="https://github.com/AngelSecurityTeam/Cam-Hackers"
    ["EyeSeeYou"]="https://github.com/BraydenP07/EyeSeeYou"
    ["sherlock"]="https://github.com/sherlock-project/sherlock"
    ["git-dumper"]="https://github.com/arthaud/git-dumper"
    ["zphisher"]="https://github.com/htr-tech/zphisher"
    ["cam-finder"]="https://github.com/member87/cam-finder.git"
    ["sqlmap"]="https://github.com/sqlmapproject/sqlmap"
    ["https-github.com-Rajkumrdusad-Tool-X"]="https://github.com/vaibhavguru/https-github.com-Rajkumrdusad-Tool-X.git"
)

for repo in "${!links[@]}"; do
    if [ ! -d "$repo" ]; then
        # Diretório não existe, então clone-o
        printf "Clonando %s...\n" "${repo}"
        git clone "${links[$repo]}"
    else
        printf "${GREEN}Atualizando o repositório ${CYAN_LIGHT}%s...${RESET}\n" "${repo}"
        git -C "$repo" reset --hard
        git -C "$repo" pull
    fi
done

# Criando o ambiente virtual
python3 -m venv venv/tools
source venv/tools/bin/activate

for repo in "${!links[@]}"; do
    REPO_PATH="./${repo}"

    if [ -f "$REPO_PATH/setup.py" ] || [ -f "$REPO_PATH/pyproject.toml" ]; then
        printf "${GREEN_BOLD}Tentando instalar $repo com pip${RESET}\n"

        pip install "$REPO_PATH" || \
        printf "${RED_BOLD}Falha ao instalar $repo com pip. Instale manualmente se necessário.${RESET}\n"
    else
        printf "${YELLOW_BOLD}Repositório $repo não é um pacote Python instalável. Instalação manual será necessária.${RESET}\n"
    fi

    cp /venv/tools/bin/${repo} /usr/local/bin/ 2>/dev/null || \
    printf "${YELLOW_BOLD}Executável ${repo} não encontrado no venv/bin${RESET}\n"
done > logpip.txt

deactivate

printf "${GREEN_BOLD}Instalação concluída${RESET}\n"
sleep 3

cp /go/bin/* /usr/local/bin

printf "${YELLOW}Aviso: ${GREEN}As ferramentas em Golang foram copiadas para /usr/local/bin para facilitar o uso das mesmas.\n"
printf "Ao invés de digitar o caminho /go/bin/ferramenta, você poderá agora chamar a ferramenta apenas digitando o seu nome${RESET}\n"
printf "Ex1: ${CYAN_LIGHT}subfinder -d alvo${RESET}\n"
printf "Ex2: ${BLUE_LIGHT}ffuf -u alvo/FUZZ(palavra padrão para ser substituída pelas da wordlist) -w caminho da wordlist${RESET}\n"
printf "Ex3: ${PURPLE_LIGHT}nuclei -u alvo -t /nuclei-templates/cves${RESET}\n"
