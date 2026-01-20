#!/usr/bin/env bash

# Definição das cores ANSI
YELLOW="\u001B[1;93m"
GREEN_BOLD="\u001B[1;32m"
CYAN_BOLD="\u001B[1;36m"
GREEN_LIGHT="\u001B[1;92m"
CYAN="\u001B[1;36m"
GREEN="\u001B[1;92m"
CYAN_LIGHT="\u001B[96m"
RED_BOLD="\u001B[1;91m"
YELLOW_BOLD="\u001B[1;93m"
BLUE_LIGHT="\u001B[1;94m"
PURPLE_LIGHT="\u001B[1;95m"
RESET="\u001B[0m"

printf "%bEsse script foi feito com o propósito de ser usado no Kali para o Userland%b\n" "$YELLOW" "$RESET"
sleep 2

if [ "$(uname)" != "Linux" ]; then
    printf "%bVocê não está usando um sistema GNU/Linux ou similar%b\n" "$GREEN_BOLD" "$RESET"
    exit 1
fi

# Solicita senha sudo uma vez no começo
printf "%bVerificando permissões de sudo...%b\n" "$CYAN_BOLD" "$RESET"
sudo -v

(
    while true; do
        sudo -n true
        sleep 60                                                                                                               
        kill -0 "$$" || exit
    done
) 2>/dev/null &

# ---------- Atualização do sistema ----------
printf "%bVamos começar atualizando o %bLinux...%b\n" "$CYAN_BOLD" "$GREEN_LIGHT" "$RESET"
sleep 3
cd 
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

# ---------- Instalação de pacotes APT ----------
printf "%bInstalando linguagens de programação e pacotes necessários...%b\n" "$CYAN" "$RESET"
sleep 1

pkg=(
    python3
    golang
    curl
    unzip
    wget
    iputils-ping
    openssh-client
    neovim
    cargo
    pipx
    zsh
    nmap
    htop
    gobuster
)

printf "%b[*] Instalando pacotes...%b\n" "$CYAN_BOLD" "$RESET"     
for p in "${pkg[@]}"; do                                                                                                   
    if command -v "${p}" &> /dev/null; then
        printf "%b[✔] %s já instalado.%b\n" "$GREEN_BOLD" "$p" "$RESET"                                                                                             
    else                                                                                                                       
       printf "%b[ * ] Instalando %s...%b\n" "$YELLOW" "$p" "$RESET"                                                                                                       
       sudo apt install -y "${p}"                                                                                         
    fi
done

printf "%bcriando um init.lua para Neovim em %b${HOME}/.config/nvim/init.lua%b\n" "$YELLOW_BOLD" "$GREEN_BOLD" "$RESET"

cat << 'EOF' > ~/.config/nvim/init.lua
vim.g.mapleader = " "

-- CORES (DESCOMENTE 1)
vim.opt.termguicolors = true        -- TRUE COLOR ATIVADO
vim.opt.background = "dark"

-- 🎨 PALETAS (escolha 1):
-- vim.cmd("colorscheme default")   -- Clássico original
-- vim.cmd("colorscheme desert")    -- 🏜️ Limpo/areia (RECOMENDADO)
-- vim.cmd("colorscheme slate")     -- 🌙 Escuro moderno
-- vim.cmd("colorscheme ron")       -- ⚫ Minimalista
-- vim.cmd("colorscheme industry")  -- 💻 Corporativo
-- vim.cmd("colorscheme blue")      -- 🔵 Azul clássico

-- INTERFACE
vim.opt.number = true               -- Números linha
vim.opt.relativenumber = true       -- Relativo
vim.opt.cursorline = true           -- Linha atual
vim.opt.wrap = false                -- Sem quebra linha
vim.opt.scrolloff = 8               -- Margem scroll
vim.opt.updatetime = 50             -- Mais responsivo

-- TABS/ESPÇO
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- BUSCA
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false            -- Sem highlight busca
vim.opt.incsearch = true

-- LSP NATIVO (Neovim 0.11+)
vim.lsp.enable('lua_ls')       -- Lua
vim.lsp.enable('bashls')       -- Bash
vim.lsp.enable('pyright')      -- Python
-- vim.lsp.enable('rust_analyzer') -- Rust (adicione se usar)

-- KEYBINDINGS LSP
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)  -- Definição
vim.keymap.set('n', 'K', vim.lsp.buf.hover)        -- Docs
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)

-- TERMINAL
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
EOF

# ------- Path para o venv -------
PIPLIBS="${HOME}/piplibs"
python3 -m venv "${PIPLIBS}"

# ------ Path para atualizaçãode livrarias pip ------
PYBIN="${PIPLIBS}/bin/python"
PIPBIN="${PIPLIBS}/bin/pip"

# Cria um alias permanente para ativar o venv rapidamente
SHELLRC="${HOME}/.${SHELL##*/}rc"                                                                                       
[ "$SHELL" = "/bin/bash" ] && SHELLRC="${HOME}/.bashrc"

if ! grep -Fq "alias venv='source ${HOME}/piplibs/bin/activate'" "$SHELLRC"; then
    printf "alias venv='source ${HOME}/piplibs/bin/activate'" >> "$SHELLRC"
fi
printf "%b[INFO]%b Use o comando 'venv' para ativar o ambiente Python.\n" "$CYAN_BOLD" "$RESET"
printf "%b[INFO]%b Após ativar o venv você pode instalar ferramentas Python via pip\n" "$CYAN_BOLD" "$RESET"

sleep 2
# Ativa o env dentro do script para instalar
source "${PIPLIBS}/bin/activate"

# ativa pipefail 
set -o pipefail 

# Upgrade pip/setuptools/wheel dentro do venv
"${PIPBIN}" install --upgrade pip setuptools wheel

# Desativar pipefail
set +o pipefail

# ---------- Instalando ferramentas Go ----------
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

printf "%bInstalando ferramentas em Golang...%b" "$CYAN" "$RESET"
sleep 1
for ferramenta in "${!ferramentas[@]}"; do
    printf "%bInstalando %b%s%b...%b\n" "$GREEN" "$CYAN_LIGHT" "${ferramenta}" "$GREEN" "$RESET"
    sleep 1
    env PATH="${HOME}/go/bin:${PATH}" go install -v "${ferramentas[${ferramenta}]}" || printf "%bFalha ao instalar %s%b\n" "$YELLOW" "${ferramenta}" "$RESET"
done

# ---------- Instalação manual do Aquatone
git clone https://github.com/shelld3v/aquatone.git
(cd aquatone && go build -o "${HOME}/go/bin/aquatone")

# ---------- Criando Pastas de Output -----------
bashscriptsoutdirs=(
    subfinder_results
    gau_results
    nmap_results
    gobuster_results
    ffuf_results
)

mkdir -p "${HOME}/bashscripts"
printf "%bCriando Pastas de Output em %b%s%b\n" "$YELLOW_BOLD" "$GREEN_BOLD" "${HOME}/bashscripts" "$RESET"
 for dir in "${bashscriptsoutdirs[@]}"; do
    outputdir="${HOME}/bashscripts/${dir}"
    if [[ ! -d "${outputdir}" ]]; then
        mkdir -p "${outputdir}"
        printf "%b[✔]%b Criado: %s\n" "$GREEN_BOLD" "$RESET" "${outputdir}"
    else
        printf "%b[=]%b O diretório já existe: %s\n" "$YELLOW_BOLD" "$RESET" "${outputdir}"
    fi
done

# ---------- Clonando repositórios ----------
declare -A links=(
    ["ParamSpider"]="https://github.com/devanshbatham/ParamSpider"
    ["https-github.com-Rajkumrdusad-Tool-X"]="https://github.com/vaibhavguru/https-github.com-Rajkumrdusad-Tool-X.git"
    ["codigos_para_aprendizado"]="https://github.com/sans01hp/codigos_para_aprendizado"
    ["nuclei-templates"]="https://github.com/projectdiscovery/nuclei-templates"
)

printf "%bBaixando repositórios necessários...%b\n" "$CYAN" "$RESET"
for repo in "${!links[@]}"; do
    if [ ! -d "${repo}" ]; then
        printf "%bClonando %s...%b\n" "$CYAN_LIGHT" "${repo}" "$RESET"
        git clone "${links[${repo}]}"
    else
        printf "%bAtualizando repositório %b%s%b...%b\n" "$GREEN" "$CYAN_LIGHT" "${repo}" "$GREEN" "$RESET"
        git -C "${repo}" reset --hard
        git -C "${repo}" pull
    fi
done

# SecLists Opcional 
if [ ! -d "SecLists" ]; then
    printf "%bDeseja instalar SecLists? (s/N)%b\n" "$CYAN_LIGHT" "$RESET"
    read opcao
    case "$opcao" in
        [sSyY]*) git clone https://github.com/danielmiessler/SecLists.git ;;
        *) printf "%bPulando SecLists%b\n" "$YELLOW_BOLD" "$RESET" ;;
    esac
fi

# ---------- Tentando instalar repositorios com pip (usando piplibs) ----------
for repo in "${!links[@]}"; do
    REPO_PATH="./${repo}"
    if [ -f "${REPO_PATH}/setup.py" ] || [ -f "${REPO_PATH}/pyproject.toml" ]; then                                            
        printf "%bTentando instalar %s com pip (no piplibs)%b\n" "$GREEN_BOLD" "${repo}" "$RESET"
        "${PIPBIN}" install "${REPO_PATH}" || printf "%bFalha ao instalar %s com pip. Instale manualmente se necessário.%b\n" "$RED_BOLD" "${repo}" "$RESET"
        if [ -f "${PIPLIBS}/bin/${repo}" ]; then
            sudo ln -sf "${PIPLIBS}/bin/${repo}" /usr/local/bin/"${repo}"
        fi
    else
        printf "%bRepositório %s não é um pacote Python instalável. Instalação manual será necessária.%b\n" "$YELLOW_BOLD" "${repo}" "$RESET"
    fi
done

# ---------- Ambiente virtual do projeto codigos_para_aprendizado ----------
path4env="${HOME}/codigos_para_aprendizado/python3"
if [[ -d "${path4env}" ]]; then
    printf "%bCriando ambiente virtual em %b%s%b\n" "$YELLOW_BOLD" "$GREEN_BOLD" "${path4env}" "$RESET"
    python3 -m venv "${path4env}/libs"
    source "${path4env}/libs/bin/activate"
    python -m pip install --upgrade pip setuptools wheel
    if python -m pip install -r "${path4env}/requirements.txt"; then
    	printf "%bSucesso ao instalar livrarias%b\n" "$GREEN_BOLD" "$RESET"
    else                                                                                                                       
    	printf "%bFalha na instalação de livrarias%b\n" "$RED_BOLD" "$RESET"
    fi
else
    printf "%b[AVISO]%bO PATH %s não foi encontrado.\n" "$YELLOW_BOLD" "$RESET" "${path4env}"
fi

# ---------- Links simbólicos para Go ----------
if compgen -G "${HOME}/go/bin/*" > /dev/null; then
	for go_tool in "${HOME}/go/bin/"*; do
    	tool_name=$(basename "${go_tool}")
        sudo ln -sf "${go_tool}" /usr/local/bin/"${tool_name}"
	done
fi

printf "%bAviso: %bAs ferramentas em Golang foram linkadas para /usr/local/bin para facilitar o uso das mesmas.%b\n" "$YELLOW" "$GREEN" "$RESET"
printf "%bInstalação concluída%b\n" "$GREEN_BOLD" "$RESET"
sleep 1

# ---------- Exemplos de uso ----------
printf "%bExemplos de uso das ferramentas instaladas:%b\n" "$CYAN_BOLD" "$RESET"
printf "1. subfinder: %bsubfinder -d alvo%b\n" "$CYAN_LIGHT" "$RESET"
printf "2. ffuf: %bffuf -u alvo/FUZZ -w caminho/da/wordlist%b\n" "$BLUE_LIGHT" "$RESET"
printf "3. nuclei: %bnuclei -u alvo -t nuclei-templates/cves%b\n" "$PURPLE_LIGHT" "$RESET"
printf "4. script de recon: %b./recon.sh -u alvo%b\n" "$GREEN_BOLD" "$RESET"
