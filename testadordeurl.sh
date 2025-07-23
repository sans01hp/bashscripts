#!/bin/bash

# Cores ANSI
YELLOW="\033[93m"
CYAN_LIGHT="\033[96m"
GREEN="\033[92m"
PURPLE="\033[95m"
RED="\033[91m"
BLUE="\033[94m"
RESET="\033[0m"

printf "${YELLOW}Digite o ${CYAN_LIGHT}Dominio/Url ${YELLOW}que deseja analisar:${RESET}\n"
read url

# Verifica se começa com "https://"
if [[ "${url}" != "https://"* ]]; then
  url="https://${url}"
fi

printf "${YELLOW}Atualmente analisando o link: ${CYAN_LIGHT}%s${RESET}\n" "$url"

# Funções
menu() {
  printf "1-${GREEN}Montar urls${RESET}\n"
  printf "2-${PURPLE}Usar Nuclei ${RED}[ROOT NECESSÁRIO]${RESET}\n"
  printf "3-${BLUE}Subdominios ativos${RESET}\n"
  printf "4-${CYAN_LIGHT}Achar informações no JavaScript${RESET}\n"
  printf "9-${RED}Mudar alvo${RESET}\n"
  printf "00-${YELLOW}Sair${RESET}\n"
}

acharurls() {
  printf "Montando urls em ${GREEN}%s${RESET}\n" "$url"
  printf "$url" | gau
}

javascript() {
  printf "Coletando informações no JavaScript...\n"
  printf "$url" | getJS
}

nuclei() {
  printf "${YELLOW} Quais templates quer usar?${GREEN}\n"
  printf "1-todos\n"
  printf "2-exposures\n"
  printf "3-cves\n"
  printf "4-exposed panels\n"
  printf "5-fuzzing\n"
  printf "6-vulnerabilities${RESET}\n"

  read -r template

  case $template in
    1) ~/go/bin/nuclei -u "$url" -t ~/nuclei-templates ;;
    2) ~/go/bin/nuclei -u "$url" -t ~/nuclei-templates/exposures ;;
    3) ~/go/bin/nuclei -u "$url" -t ~/nuclei-templates/cves ;;
    4) ~/go/bin/nuclei -u "$url" -t ~/nuclei-templates/exposed-panels ;;
    5) ~/go/bin/nuclei -u "$url" -t ~/nuclei-templates/fuzzing ;;
    6) ~/go/bin/nuclei -u "$url" -t ~/nuclei-templates/vulnerabilities ;;
    *) printf "${YELLOW}Opção inválida ${CYAN_LIGHT}(⁠╯⁠°⁠□⁠°⁠）⁠╯⁠︵⁠┻⁠━⁠┻${RESET}\n" ;;
  esac
}

subd() {
  subfinder -d "${url##https://}" | httpx -sc -title
}

# Loop principal
while true; do
  menu
  read -r opcao

  case $opcao in
    1) acharurls ;;
    2) nuclei ;;
    3) subd ;;
    4) javascript ;;
    9)
      printf "${YELLOW}Digite o ${CYAN_LIGHT}Dominio/Url ${YELLOW}que deseja analisar:${RESET}\n"
      read url

      if [[ "${url}" != "https://"* ]]; then
        url="https://${url}"
      fi

      printf "${YELLOW}Atualmente analisando o link: ${CYAN_LIGHT}%s${RESET}\n" "$url"
      ;;
    00)
      printf "${YELLOW}Saindo...${RESET}\n"
      exit 0
      ;;
    *)
      printf "${YELLOW}Opção inválida ${CYAN_LIGHT}(⁠╯⁠°⁠□⁠°⁠）⁠╯⁠︵⁠┻⁠━⁠┻${RESET}\n"
      ;;
  esac
done
