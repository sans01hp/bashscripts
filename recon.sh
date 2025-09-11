#!/usr/bin/env bash

# =========================================================
# Script de Recon
# =========================================================

# ---------- Cores ANSI ----------
YELLOW="\033[93m"
CYAN_LIGHT="\033[96m"
GREEN="\033[92m"
PURPLE="\033[95m"
RED="\033[91m"
BLUE="\033[94m"
RESET="\033[0m"

# ---------- Funções ----------
menu() {
    clear
    printf "%b1-Recon completo (Subfinder + Httpx + Gau)%b\n" "$GREEN" "$RESET"
    printf "%b2-Usar Nuclei %b[ROOT NECESSÁRIO]%b\n" "$PURPLE" "$RED" "$RESET"
    printf "%b4-Achar informações no JavaScript%b\n" "$CYAN_LIGHT" "$RESET"
    printf "%b9-Mudar alvo%b\n" "$RED" "$RESET"
    printf "%b00-Sair%b\n" "$YELLOW" "$RESET"
}

recon_all() {
    printf "%b[INFO]%b Rodando Subfinder + Httpx + Gau em: %s\n" "$GREEN" "$RESET" "${url}"

    # Diretório e arquivo de saída
    output_dir="${HOME}/bashscripts/subd_results"
    mkdir -p "${output_dir}"

    domain="${url#*://}"    # remove http:// ou https://
    domain="${domain%%/*}"  # remove caminho

    output_file="${output_dir}/${domain}.txt"

    printf "%b[INFO]%b Salvando resultados em: %s\n" "$CYAN_LIGHT" "$RESET" "${output_file}"

    # Pipeline principal
    subfinder -d "${domain}" -silent \
        | httpx -silent \
        | gau -silent > "${output_file}"

    if [[ $? -eq 0 ]]; then
        printf "%b[OK]%b Recon concluído. Arquivo: %s\n" "$GREEN" "$RESET" "${output_file}"
    else
        printf "%b[ERRO]%b Falha durante o recon para %s\n" "$RED" "$RESET" "${url}"
    fi
}

javascript() {
    printf "%b[INFO]%b Coletando informações no JavaScript...\n" "$GREEN" "$RESET"
    printf "%s\n" "${url}" | getJS
}

nuclei() {
    printf "%bQuais templates quer usar?%b\n" "$YELLOW" "$GREEN"
    printf "1-todos\n"
    printf "2-exposures\n"
    printf "3-cves\n"
    printf "4-exposed panels\n"
    printf "5-fuzzing\n"
    printf "6-vulnerabilities%b\n" "$RESET"

    read -r template

    case $template in
        1) $HOME/go/bin/nuclei -u "${url}" -t $HOME/nuclei-templates ;;
        2) $HOME/go/bin/nuclei -u "${url}" -t $HOME/nuclei-templates/exposures ;;
        3) $HOME/go/bin/nuclei -u "${url}" -t $HOME/nuclei-templates/cves ;;
        4) $HOME/go/bin/nuclei -u "${url}" -t $HOME/nuclei-templates/exposed-panels ;;
        5) $HOME/go/bin/nuclei -u "${url}" -t $HOME/nuclei-templates/fuzzing ;;
        6) $HOME/go/bin/nuclei -u "${url}" -t $HOME/nuclei-templates/vulnerabilities ;;
        *)
            printf "%bOpção inválida %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
            return ;;
    esac
}

resetar_url() {
    printf "%bDigite o %bDominio/Url %bque deseja analisar:%b\n" "$YELLOW" "$CYAN_LIGHT" "$YELLOW" "$RESET"
    read -r url

    if [[ -z "${url}" ]]; then
        printf "%b[ERRO]%b URL vazia.%b\n" "$RED" "$YELLOW" "$RESET"
        return 1
    fi

    if [[ "${url}" != https://* ]]; then
        url="https://${url}"
    fi

    if [[ "${url}" =~ ^https://(([a-zA-Z0-9\u00a1-\uffff-]+\.)+[a-zA-Z\u00a1-\uffff]{2,})(/.*)?$ ]]; then
        printf "%bAtualmente analisando o link: %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "${url}" "$RESET"
    else
        printf "%b[ERRO]%b Dominio ou subdominio %s invalido.%b\n" "$RED" "$YELLOW" "${url}" "$RESET"
        return 2
    fi
}

# ---------- Entrada inicial ----------
if [[ -z "$1" ]]; then
    printf "%b[ERRO]%b Você precisa passar uma URL como argumento.%b\n" "$RED" "$YELLOW" "$RESET"
    printf "Uso: %s <dominio ou url>\n" "$0"
    exit 1
fi

url="$1"

if [[ "${url}" != https://* ]]; then
    url="https://${url}"
fi

if [[ "${url}" =~ ^https://(([a-zA-Z0-9\u00a1-\uffff-]+\.)+[a-zA-Z\u00a1-\uffff]{2,})(/.*)?$ ]]; then
    printf "%bAtualmente analisando o link: %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "${url}" "$RESET"
else
    printf "%b[ERRO]%b Dominio ou subdominio %s invalido.%b\n" "$RED" "$YELLOW" "${url}" "$RESET"
    exit 2
fi

# ---------- Loop principal ----------
while true; do
    menu
    read -r opcao
    case $opcao in
        1) recon_all ;;
        2) nuclei ;;
        4) javascript ;;
        9) resetar_url ;;
        00)
            printf "%bSaindo...%b\n" "$YELLOW" "$RESET"
            exit 0
            ;;
        *)
            printf "%bOpção inválida %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
            ;;
    esac
done
