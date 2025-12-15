#!/usr/bin/env bash

# Definição das cores ANSI
YELLOW="\033[1;93m"
GREEN_BOLD="\033[1;32m"
CYAN_BOLD="\033[1;36m"
GREEN_LIGHT="\033[1;92m"
CYAN="\033[1;36m"
GREEN="\033[1;92m"
CYAN_LIGHT="\033[96m"
RED_BOLD="\033[1;91m"
YELLOW_BOLD="\033[1;93m"
BLUE_LIGHT="\033[1;94m"
PURPLE_LIGHT="\033[1;95m"
RESET="\033[0m"

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
cd ~
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
    cargo
    pipx
    zsh 
    neovim
    nodejs
    npm
    nmap
    htop   
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

# Instalar e configurar Neovim em ~/.config/nvim/init.lua
# Ativar o pipefail para capturar erros na pipeline
set -o pipefail

# -------- Diretórios --------
CONFIG_DIR="${HOME}/.config/nvim"
mkdir -p "${CONFIG_DIR}"

# -------- Instalação do Lazy.nvim --------
printf "%b[+] Instalando Lazy.nvim...%b\n" "$CYAN" "$RESET"
LAZY_DIR="${HOME}/.local/share/nvim/lazy/lazy.nvim"
if [ ! -d "${LAZY_DIR}" ]; then
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "${LAZY_DIR}"
fi

# -------- Configuração do init.lua --------
cat > "${CONFIG_DIR}/init.lua" <<'EOF'
-- ========== Lazy.nvim ==========
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Tema
  { "ellisonleao/gruvbox.nvim", priority = 1000, config = function() vim.cmd.colorscheme("gruvbox") end },

  -- Syntax highlight & LSP
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "neovim/nvim-lspconfig" },

  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
})

local lspconfig = require("lspconfig")
lspconfig.pyright.setup({})
lspconfig.gopls.setup({})
lspconfig.bashls.setup({})

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

function ToggleNumbers()
  local num = vim.wo.number
  local rnum = vim.wo.relativenumber
  local ruler = vim.wo.ruler
  if num or rnum or ruler then
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.ruler = false
    print("📘 Numeração e ruler desativados")
  else
    vim.wo.number = true
    vim.wo.relativenumber = true
    vim.wo.ruler = true
    print("📗 Numeração e ruler ativados")
  end
end

vim.api.nvim_set_keymap("n", "<C-n>", [[:lua ToggleNumbers()<CR>]], { noremap = true, silent = true })
EOF

# -------- Criando ambiente isolado para pacotes python em $HOME/piplibs/ -------

# ------- Path para o venv -------
PIPLIBS="${HOME}/piplibs"
python3 -m venv "${PIPLIBS}"

# ------ Path para atualizaçãode livrarias pip ------
PYBIN="${PIPLIBS}/bin/python"
PIPBIN="${PIPLIBS}/bin/pip"

# Cria um alias permanente para ativar o venv rapidamente
if ! grep -Fq "alias venv='source ${HOME}/piplibs/bin/activate'" "${HOME}/.zshrc"; then
    printf "alias venv='source ${HOME}/piplibs/bin/activate'" >> "${HOME}/.zshrc"
    printf "%b[✔]%b Alias 'venv' adicionado ao .zshrc\n" "$GREEN_BOLD" "$RESET"
else
    printf "%b[=]%b Alias 'venv' já existe no .zshrc\n" "$YELLOW_BOLD" "$RESET"
fi
printf "%b[INFO]%b Use o comando 'venv' para ativar o ambiente Python.\n" "$CYAN_BOLD" "$RESET"
printf "%b[INFO]%b Após ativar, o Neovim funcionará com todos os LSPs e plugins corretamente.\n" "$CYAN_BOLD" "$RESET"
# Ativa o env dentro do script para instalar e para o nvim headless
source "${PIPLIBS}/bin/activate"

# Upgrade pip/setuptools/wheel dentro do venv (opcional, recomendado)
"${PIPBIN}" install --upgrade pip setuptools wheel

# Instalar pynvim e pylsp no venv
if ! "${PIPBIN}" install pynvim "python-lsp-server[all]"; then
    printf "%bFalha instalando pynvim/pylsp no venv%b\n" "$YELLOW" "$RESET"
fi

# Instalar gopls e bash-language-server (gopls via go install; bash-language-server via npm)
GO111MODULE=on go install golang.org/x/tools/gopls@latest || printf "%bFalha instalando gopls%b\n" "$YELLOW" "$RESET"
sudo npm install -g bash-language-server || printf "%bFalha instalando bash-language-server%b\n" "$YELLOW" "$RESET"

# -------- Lazy sync plugins (assegurar que nvim veja o piplibs) --------
env PATH="${HOME}/go/bin:${PIPLIBS}/bin:${PATH}" nvim --headless "+Lazy sync" +qa || printf "%bLazy sync falhou — abra o nvim e rode :Lazy sync%b\n" "$YELLOW" "$RESET"

# -------- Mensagem final parcial --------
printf "%b[✔] Instalação do Neovim concluída!%b\n" "$GREEN_BOLD" "$RESET"
printf "%bIMPORTANTE:%b Para usar o Neovim com os LSPs, ative o venv:%b\n  %bsource ~/piplibs/bin/activate%b\n" "$YELLOW" "$RESET" "$CYAN" "$RESET"

# Desativar pipefail local
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
    ["gobuster"]="github.com/OJ/gobuster/v3@latest"
)

printf "%bInstalando ferramentas em Golang...%b\n" "$CYAN" "$RESET"
sleep 1
for ferramenta in "${!ferramentas[@]}"; do
    printf "%bInstalando %b%s%b...%b\n" "$GREEN" "$CYAN_LIGHT" "${ferramenta}" "$GREEN" "$RESET"
    sleep 1
    # Garantir go bin no PATH para installs e uso imediato
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
    ["sherlock"]="https://github.com/sherlock-project/sherlock"
    ["git-dumper"]="https://github.com/arthaud/git-dumper"
    ["zphisher"]="https://github.com/htr-tech/zphisher"
    ["sqlmap"]="https://github.com/sqlmapproject/sqlmap"
    ["https-github.com-Rajkumrdusad-Tool-X"]="https://github.com/vaibhavguru/https-github.com-Rajkumrdusad-Tool-X.git"
    ["codigos_para_aprendizado"]="https://github.com/sans01hp/codigos_para_aprendizado"
    ["nuclei-templates"]="https://github.com/projectdiscovery/nuclei-templates"
    ["seclists"]="https://github.com/danielmiessler/SecLists"
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

# ---------- Tentando instalar repositorios com pip (usando piplibs) ----------
for repo in "${!links[@]}"; do
    REPO_PATH="./${repo}"
    if [ -f "${REPO_PATH}/setup.py" ] || [ -f "${REPO_PATH}/pyproject.toml" ]; then
        printf "%bTentando instalar %s com pip (no piplibs)%b\n" "$GREEN_BOLD" "${repo}" "$RESET"
        "${PIPBIN}" install "${REPO_PATH}" || printf "%bFalha ao instalar %s com pip. Instale manualmente se necessário.%b\n" "$RED_BOLD" "${repo}" "$RESET"
        # Linkar executáveis caso tenham sido instalados no piplibs/bin
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
    # Ativar apenas para instalar as dependências do projeto (acaba o source ao fim do script 
    source "${path4env}/libs/bin/activate"
    python -m pip install --upgrade pip setuptools wheel
    if python -m pip install -r "${path4env}/requirements.txt"; then
        printf "%bSucesso ao instalar livrarias%b\n" "$GREEN_BOLD" "$RESET"
    else
        printf "%bFalha na instalação de livrarias (verifique logs)%b\n" "$RED_BOLD" "$RESET"
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
printf "\n%bExemplos de uso das ferramentas instaladas:%b\n" "$CYAN_BOLD" "$RESET"
printf "1. subfinder: %bsubfinder -d alvo%b\n" "$CYAN_LIGHT" "$RESET"
printf "2. ffuf: %bffuf -u alvo/FUZZ -w caminho/da/wordlist%b\n" "$BLUE_LIGHT" "$RESET"
printf "3. nuclei: %bnuclei -u alvo -t nuclei-templates/cves%b\n" "$PURPLE_LIGHT" "$RESET"
printf "4. script de recon: %b./recon.sh -u alvo%b\n" "$GREEN_BOLD" "$RESET"

