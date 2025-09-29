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
    printf "%b1-Recon completo (Subfinder + Httpx + Gau)%b\n" "$GREEN" "$RESET"
    printf "%b2-Usar Nuclei %b[ROOT NECESSÁRIO]%b\n" "$PURPLE" "$RED" "$RESET"
    printf "%b4-Achar informações no JavaScript%b\n" "$CYAN_LIGHT" "$RESET"
    printf "%b9-Mudar alvo%b\n" "$RED" "$RESET"
    printf "%b00-Sair%b\n" "$YELLOW" "$RESET"
}

recon_all() {
    printf "%b[INFO]%b Rodando Subfinder + Httpx + Gau em: %s\n" "$GREEN" "$RESET" "${url}"

    output_dir="${HOME}/bashscripts/subd_results"
    mkdir -p "$output_dir"

    domain="${url#*://}"    # remove http:// ou https://
    domain="${domain%%/*}"  # remove caminho/paths

    out_file="${output_dir}/${domain}.txt"

    printf "%b[INFO]%b Salvando resultados em: %s\n" "$CYAN_LIGHT" "$RESET" "$out_file"

    # pipeline simples, resultado mostrado e salvo com tee
    subfinder -d "$domain" -silent \
      | httpx -silent \
      | gau \
      | tee "$out_file"

    status=$?

    if [[ $status -eq 0 ]]; then
        printf "%b[OK]%b Recon concluído. Arquivo: %s\n" "$GREEN" "$RESET" "$out_file"
        return 0
    else
        printf "%b[ERRO]%b Falha durante o recon para %s (status %d)\n" "$RED" "$RESET" "${url}" "$status"
        return $status
    fi
}
javascript() {
    printf "%b[INFO]%b Coletando informações no JavaScript...\n" "$GREEN" "$RESET"
    printf "%s\n" "${url}" | getJS
}

nuclei() {
    printf "%bQuais templates quer usar?%b\n" "$YELLOW" "$RESET"
    printf "1-todos\n"
    printf "2-exposures\n"
    printf "3-cves\n"
    printf "4-exposed panels\n"
    printf "5-fuzzing\n"
    printf "6-vulnerabilities\n"

    read -r template

    case "$template" in
        1) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates" ;;
        2) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/exposures" ;;
        3) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/cves" ;;
        4) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/exposed-panels" ;;
        5) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/fuzzing" ;;
        6) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/vulnerabilities" ;;
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

    if [[ "${url}" != https://* && "${url}" != http://* ]]; then
        url="https://${url}"
    fi

    # regex simplificado e portátil
    if [[ "${url}" =~ ^https?://([A-Za-z0-9.-]+\.[A-Za-z]{2,})(/.*)?$ ]]; then
        printf "%bAtualmente analisando o link: %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "${url}" "$RESET"
        return 0
    else
        printf "%b[ERRO]%b Dominio ou subdominio %s invalido.%b\n" "$RED" "$YELLOW" "${url}" "$RESET"
        return 2
    fi
}

# ---------- Entrada inicial ----------
output=""
url=""

while getopts "u:o:h" flag; do
    case "$flag" in
       h)
          echo "Forma de uso: $0 -u <url> -o <nome_do_arquivo_de_saida.txt> (opcional)"
          echo "-u      define a url inicial (ex: -u exemplo.com ou -u https://exemplo.com)"
          echo "-h      mostra esse texto"
          echo "-o      output para fuzzing (ex: -o resultado.txt)"
          exit 0
          ;;
       o) output=$OPTARG ;;
       u)
          url=$OPTARG
          # normalize
          if [[ "${url}" != https://* && "${url}" != http://* ]]; then
              url="https://${url}"
          fi
          if ! [[ "${url}" =~ ^https?://([A-Za-z0-9.-]+\.[A-Za-z]{2,})(/.*)?$ ]]; then
              printf "%b[ERRO]%b Dominio ou subdominio %s invalido.%b\n" "$RED" "$YELLOW" "${url}" "$RESET"
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
    printf "%bA flag -u não pode ser vazia%b\n" "${YELLOW}" "${RESET}"
	printf "%bUse $0 -u <url ou dominio>%b" "${GREEN}" "${RESET}"
	exit 1 
fi	
# ---------- Loop principal ----------
while true; do
    menu
    printf "%bDigite o numero da opção que você quer%b:" "${GREEN}" "${RESET}"
    read -r  opcao
    case "$opcao" in
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
