#!/bin/bash

install() {
  wget https://www.dropbox.com/s/rxb1qasbu27l87h/backup.tar.bz2
sleep 5
tar xvpjf backup.tar.bz2 -C /
}
main() {
  echo -e "
${FUCHSIA}=====================================
${GREEN}1. Instalar Script ADMRufu
${FUCHSIA}===================================================
  read -rp "elija una opcion：" menu_num
  case $menu_num in
  1)
    install
    ;;
  esac
}
main
