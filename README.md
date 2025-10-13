# Bashscripts — instalador_recon

Instala e configura um ambiente de *recon* (ferramentas Go, Neovim com LSP, pip venvs e repositórios) pensado para uso em Kali Linux (ex.: UserLAnd / VM).

> Observação: o script pede `sudo` durante a execução (ele não precisa ser executado como root — apenas garanta que seu usuário tenha sudo).

## Como instalar

```bash
git clone https://github.com/sans01hp/bashscripts
cd bashscripts
chmod +x instalador_recon.sh
./instalador_recon.sh
