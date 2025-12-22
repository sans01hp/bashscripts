# Bashscripts — instalador_recon

Instala e configura um ambiente de *recon* (ferramentas Go, Micro com LSP, pip venvs e repositórios) pensado para uso em Kali Linux (ex.: VirtualBox).

> Observação: o script pede `sudo` durante a execução (ele não precisa ser executado usando o usuario root — ele usa o proprio usuario root mesmo que você execute por um usuario padrão. apenas garanta que tenha uma usuario Root)

> Pelo motivo acima e problemas recorrentes com o userland, esse script tem foco para uso direto no pc/notebook. é possivel usar em termux ou Userland para android, mas espere comportamento inesperado de ferramentas ou editores. 
>O micro não funciona corretamente no android

## O scripts ja vem com chmod 700, mas se não funcionar:

```bash
git clone https://github.com/sans01hp/bashscripts
cd bashscripts
chmod +x instalador_recon.sh
./instalador_recon.sh

```
Bom uso.

