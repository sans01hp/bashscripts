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

# ---------- Instalação de pacotes ----------
printf "%bInstalando linguagens de programação e ferramentas necessárias...%b\n" "$CYAN" "$RESET"
sleep 3

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
	micro
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

printf "%bEditor %bmicro %binstalado. Use se precisar de autocomplete para comandos%b\n" "$YELLOW_BOLD" "$GREEN_LIGHT" "$YELLOW" "$RESET"
printf "%bConfigurando Micro para Python LSP...%b\n" "$CYAN" "$RESET"
sleep 2

# Instala python-lsp-server via pipx
pipx ensurepath
pipx install 'python-lsp-server[all]'

MICRO_CONFIG_DIR="${HOME}/.config/micro"
mkdir -p "${MICRO_CONFIG_DIR}"
cat > "${MICRO_CONFIG_DIR}/settings.json" <<setup
{
	"plugin": ["lsp"],
	"lspservers": {
		"python": {
			"command": "pylsp"
		}
	}
}
setup

printf "%bMicro configurado para suporte a Python LSP%b\n" "$GREEN_BOLD" "$RESET"

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
	["aquatone"]="github.com/michenriksen/aquatone@latest"
)

printf "%bInstalando ferramentas em Golang...%b\n" "$CYAN" "$RESET"
sleep 2
for ferramenta in "${!ferramentas[@]}"; do
	printf "%bInstalando %b%s%b...%b\n" "$GREEN" "$CYAN_LIGHT" "${ferramenta}" "$GREEN" "$RESET"
	sleep 1
	go install -v "${ferramentas[${ferramenta}]}"
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

# ---------- Ambiente virtual Python ----------
python3 -m venv "${HOME}/piplibs"
source "${HOME}/piplibs/bin/activate"

for repo in "${!links[@]}"; do
	REPO_PATH="./${repo}"
	if [ -f "${REPO_PATH}/setup.py" ] || [ -f "${REPO_PATH}/pyproject.toml" ]; then
		printf "%bTentando instalar %s com pip%b\n" "$GREEN_BOLD" "${repo}" "$RESET"
		pip install "${REPO_PATH}" || printf "%bFalha ao instalar %s com pip. Instale manualmente se necessário.%b\n" "$RED_BOLD" "${repo}" "$RESET"
		if [ -f "${HOME}/piplibs/bin/${repo}" ]; then
			sudo ln -sf "${HOME}/piplibs/bin/${repo}" /usr/local/bin/"${repo}"
		fi
	else
		printf "%bRepositório %s não é um pacote Python instalável. Instalação manual será necessária.%b\n" "$YELLOW_BOLD" "${repo}" "$RESET"
	fi
done

deactivate

# ---------- Ambiente virtual de codigos_para_aprendizado  ----------
path4env="${HOME}/codigos_para_aprendizado/python3"
if [[ -d "${path4env}" ]]; then
	printf "%bCriando ambiente virtual em %b%s%b\n" "${YELLOW_BOLD}" "${GREEN_BOLD}" "${path4env}" "${RESET}"
	python3 -m venv "${path4env}/libs"
	source "${path4env}/libs/bin/activate"
	pip install -r "${path4env}/requirements.txt" #2> /dev/null
	if [[ $? -eq 0 ]]; then
		printf "%bSucesso ao instalar livrarias%b\n" "${GREEN_BOLD}" "${RESET}"
	else
		printf "%bFalha na instalação de livrarias%b\n" "${RED_BOLD}" "${RESET}"
	fi
else
	printf "%b[AVISO]%bO PATH ${path4env} não foi encontrado.\n" "${YELLOW_BOLD}" "${RESET}"
fi

# ---------- Links simbólicos para Go ----------
for go_tool in "${HOME}/go/bin/"*; do
	tool_name=$(basename "${go_tool}")
	sudo ln -sf "${go_tool}" /usr/local/bin/"${tool_name}"
done

printf "%bAviso: %bAs ferramentas em Golang foram linkadas para /usr/local/bin para facilitar o uso das mesmas.%b\n" "$YELLOW" "$GREEN" "$RESET"
printf "%bInstalação concluída%b\n" "$GREEN_BOLD" "$RESET"
sleep 2

# ---------- Exemplos de uso ----------
printf "\n%bExemplos de uso das ferramentas instaladas:%b\n" "$CYAN_BOLD" "$RESET"
printf "1. subfinder: %bsubfinder -d alvo%b\n" "$CYAN_LIGHT" "$RESET"
printf "2. ffuf: %bffuf -u alvo/FUZZ -w caminho/da/wordlist%b\n" "$BLUE_LIGHT" "$RESET"
printf "3. nuclei: %bnuclei -u alvo -t nuclei-templates/cves%b\n" "$PURPLE_LIGHT"
