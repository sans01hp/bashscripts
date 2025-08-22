#!/usr/bin/env bash

# =========================================================
# Script de instalação de ferramentas e configuração do Micro com Python LSP
# =========================================================

# ---------- Cores ANSI ----------
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

printf "${YELLOW}Esse script foi feito para uso no Kali Linux UserLand${RESET}\n"
sleep 2

# ---------- Verifica se é Linux ----------
if [ "$(uname)" != "Linux" ]; then
    printf "${GREEN_BOLD}Você não está usando um sistema GNU/Linux ou similar${RESET}\n"
    exit 1
fi

printf "${CYAN_BOLD}Atualizando o sistema...${RESET}\n"
sleep 2
cd
sudo apt update -y

# ---------- Instalando pacotes ----------
printf "${CYAN}Instalando linguagens e ferramentas necessárias...${RESET}\n"
sleep 2

sudo apt install -y python3 python3-venv pypy3-venv golang curl wget iputils-ping openssh-client micro pipx

printf "${YELLOW_BOLD}Editor ${GREEN_LIGHT}micro${YELLOW_LIGHT} instalado.${RESET}\n"

# ---------- Instalando Python LSP ----------
printf "${CYAN}Instalando python-lsp-server via pipx...${RESET}\n"
pipx install 'python-lsp-server[all]'

# ---------- Configurando Micro para usar LSP ----------
MICRO_CONFIG_DIR="$HOME/.config/micro"
MICRO_SETTINGS="$MICRO_CONFIG_DIR/settings.json"
mkdir -p "$MICRO_CONFIG_DIR"

# Se não existir settings.json, cria
if [ ! -f "$MICRO_SETTINGS" ]; then
    echo '{}' > "$MICRO_SETTINGS"
fi

# Adiciona ou atualiza a configuração do LSP para Python
jq '. + {
  "lsp": {
    "python": {
      "command": "pylsp",
      "args": [],
      "rootPatterns": [".git", ".venv", "pyproject.toml"]
    }
  }
}' "$MICRO_SETTINGS" > "$MICRO_SETTINGS.tmp" && mv "$MICRO_SETTINGS.tmp" "$MICRO_SETTINGS"

printf "${GREEN_BOLD}Micro configurado com Python LSP (pylsp).${RESET}\n"

# ---------- Instalando ferramentas Go ----------
printf "${CYAN}Instalando ferramentas Go...${RESET}\n"
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

# ---------- Clonando repositórios ----------
printf "${CYAN}Baixando repositórios necessários...${RESET}\n"
declare -A links=(
    ["ParamSpider"]="https://github.com/devanshbatham/ParamSpider"
    ["sherlock"]="https://github.com/sherlock-project/sherlock"
    ["git-dumper"]="https://github.com/arthaud/git-dumper"
    ["zphisher"]="https://github.com/htr-tech/zphisher"
    ["sqlmap"]="https://github.com/sqlmapproject/sqlmap"
    ["Tool-X"]="https://github.com/vaibhavguru/https-github.com-Rajkumrdusad-Tool-X.git"
    ["codigos_para_aprendizado"]="https://github.com/sans01hp/codigos_para_aprendizado"
)

for repo in "${!links[@]}"; do
    if [ ! -d "$repo" ]; then
        printf "Clonando %s...\n" "${repo}"
        git clone "${links[$repo]}"
    else
        printf "${GREEN}Atualizando %s...${RESET}\n" "$repo"
        git -C "$repo" reset --hard
        git -C "$repo" pull
    fi
done

# ---------- Criando ambiente virtual ----------
python3 -m venv ~/piplibs
source ~/piplibs/bin/activate

for repo in "${!links[@]}"; do
    REPO_PATH="./${repo}"
    if [ -f "$REPO_PATH/setup.py" ] || [ -f "$REPO_PATH/pyproject.toml" ]; then
        printf "${GREEN_BOLD}Instalando $repo via pip...${RESET}\n"
        pip install "$REPO_PATH" || \
        printf "${RED_BOLD}Falha ao instalar $repo via pip. Instale manualmente.${RESET}\n"

        if [ -f ~/piplibs/bin/${repo} ]; then
            sudo ln -sf ~/piplibs/bin/${repo} /usr/local/bin/${repo}
        fi
    else
        printf "${YELLOW_BOLD}$repo não é um pacote Python instalável.${RESET}\n"
    fi
done | tee logpip.txt

deactivate

# ---------- Links simbólicos para ferramentas Go ----------
for go_tool in ~/go/bin/*; do
    tool_name=$(basename "$go_tool")
    sudo ln -sf "$go_tool" /usr/local/bin/"$tool_name"
done

printf "${GREEN_BOLD}Instalação concluída!${RESET}\n"
sleep 1
printf "${YELLOW}Aviso: ${GREEN}As ferramentas Go foram linkadas para /usr/local/bin.\n"
printf "Agora você pode chamá-las apenas pelo nome.${RESET}\n"
printf "${CYAN_LIGHT}Ex1: subfinder -d alvo${RESET}\n"
printf "${BLUE_LIGHT}Ex2: ffuf -u alvo/FUZZ -w caminho/da/wordlist${RESET}\n"
printf "${PURPLE_LIGHT}Ex3: nuclei -u alvo -t /nuclei-templates/cves${RESET}\n"a
