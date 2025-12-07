#!/usr/bin/env bash

# =========================================================
# Script de Recon
# =========================================================

# ---------- Cores ANSI ----------
YELLOW="\u001B[93m"
CYAN_LIGHT="\u001B[96m"
GREEN="\u001B[92m"
PURPLE="\u001B[95m"
RED="\u001B[91m"
BLUE="\u001B[94m"
RESET="\u001B[0m"

# ---------- Funções ----------
menu() {
        printf "%b1-Recon completo (Subfinder + Httpx + Gau)%b
" "$GREEN" "$RESET"
        printf "%b2-Usar Nuclei %b[ROOT NECESSÁRIO]%b
" "$PURPLE" "$RED" "$RESET"
        printf "%b4-Achar informações no JavaScript%b
" "$CYAN_LIGHT" "$RESET"
        printf "%b9-Mudar alvo%b
" "$RED" "$RESET"
        printf "%b00-Sair%b
" "$YELLOW" "$RESET"
}

recon_all() {
    out_file="${HOME}/bashscripts/"
    gau_dir="${HOME}/bashscripts/gau_results"
    subfinder_dir="${HOME}/bashscripts/subfinder_results"
    nmap_dir="${HOME}/bashscripts/nmap_results"
    mkdir -p "$gau_dir" "$subfinder_dir" "$nmap_dir"

    domain="${url#*://}"
    domain="${domain%%/*}"

    gau_output="${gau_dir}/${domain}.txt"
    subfinder_output="${subfinder_dir}/${domain}.txt"
    nmap_output="${nmap_dir}/${domain}.txt"

    printf "%b[INFO]%b Rodando Subfinder...
" "$GREEN" "$RESET"
    subfinder -d "$domain" -silent | tee "$subfinder_output"

    printf "%b[INFO]%b Rodando Httpx e Gau...
" "$GREEN" "$RESET"
    cat "$subfinder_output" | httpx -silent | gau | tee "$gau_output"

    printf "%b[INFO]%b Rodando Nmap...
" "$GREEN" "$RESET"
    if ! sudo nmap -T4 -F -sV -iL "$subfinder_output" -oN "$nmap_output" ; then
        printf "%b[WARNING]%b Nmap falhou, tentando modo unprivileged...
" "$YELLOW" "$RESET"
        nmap --unprivileged -T4 -F -sV -iL "$subfinder_output" -oN "${nmap_output%.txt}_unprivileged.txt"
    fi

    printf "%b[OK]%b Recon completo. Diretórios de saída:
- Subfinder: %s
- Gau: %s
- Nmap: %s
" \
    "$GREEN" "$RESET" "$subfinder_dir" "$gau_dir" "$nmap_dir"
}

javascript() {
        printf "%b[INFO]%b Coletando informações no JavaScript...
" "$GREEN" "$RESET"
        printf "%s
" "${url}" | getJS
}

nuclei() {
        printf "%bQuais templates quer usar?%b
" "$YELLOW" "$RESET"
        printf "1-todos
"
        printf "2-exposures
"
        printf "3-cves
"
        printf "4-exposed panels
"
        printf "5-fuzzing
"
        printf "6-vulnerabilities
"

        read -r template

        case "$template" in
                1) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates" ;;
                2) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/exposures" ;;
                3) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/cves" ;;
                4) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/exposed-panels" ;;
                5) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/fuzzing" ;;
                6) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/vulnerabilities" ;;
                *)
                        printf "%bOpção inválida %b%s%b
" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
                        return ;;
        esac
}

resetar_url() {
        printf "%bDigite o %bDominio/Url %bque deseja analisar:%b
" "$YELLOW" "$CYAN_LIGHT" "$YELLOW" "$RESET"
        read -r url

        if [[ -z "${url}" ]]; then
                printf "%b[ERRO]%b URL vazia.%b
" "$RED" "$YELLOW" "$RESET"
                return 1
        fi

        if [[ "${url}" != https://* && "${url}" != http://* ]]; then
                url="https://${url}"
        fi

        # regex simplificado e portátil
        if [[ "${url}" =~ ^https?://([A-Za-z0-9.-]+.[A-Za-z]{2,})(/.*)?$ ]]; then
                printf "%bAtualmente analisando o link: %b%s%b
" "$YELLOW" "$CYAN_LIGHT" "${url}" "$RESET"
                return 0
        else
                printf "%b[ERRO]%b Dominio ou subdominio %s invalido.%b
" "$RED" "$YELLOW" "${url}" "$RESET"
                return 2
        fi
}

# ---------- Entrada inicial ----------
output=""
url=""

while getopts "u:h" flag; do
        case "$flag" in
                h)
                        echo "Forma de uso: $0 -u <url>"
                        echo "-u      define a url inicial (ex: -u exemplo.com ou -u https://exemplo.com)"
                        echo "-h      mostra esse texto"
                        exit 0
                        ;;
                u)
                        url=$OPTARG
                        # Regex de validação 
                        if [[ "${url}" != https://* && "${url}" != http://* ]]; then
                                url="https://${url}"
                        fi
                        if ! [[ "${url}" =~ ^https?://([A-Za-z0-9.-]+.[A-Za-z]{2,})(/.*)?$ ]]; then
                                printf "%b[ERRO]%b Dominio ou subdominio %s invalido.%b
" "$RED" "$YELLOW" "${url}" "$RESET"
                                exit 2
                        fi
                        ;;
                ?)
                        echo "Opção inválida. Use -h para ajuda."
                        exit 1
                        ;;
        esac
done

# verifica se a variavel está vazia
if [[ -z "${url}" ]]; then
        printf "%bA flag -u não pode ser vazia%b
" "$YELLOW" "$RESET"
        printf "%bUse $0 -u <url ou dominio>%b" "$GREEN" "$RESET"
        exit 1
fi

# ---------- Loop principal ----------
while true; do
        menu
        printf "%bDigite o numero da opção que você quer%b:" "$GREEN" "$RESET"
        read -r opcao
        case "$opcao" in
                1) recon_all ;;
                2) nuclei ;;
                4) javascript ;;
                9) resetar_url ;;
                00)
                        printf "%bSaindo...%b
" "$YELLOW" "$RESET"
                        exit 0
                        ;;
                *)
                        printf "%bOpção inválida %b%s%b
" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
                        ;;
        esac
done
