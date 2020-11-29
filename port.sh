#!/bin/bash
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
FUCHSIA="\033[0;35m"
YELLOW="\033[33m"
BLUE="\033[0;36m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
function install(){
source <(curl -sL https://multi.netlify.app/v2ray.sh)
}
function menu(){
v2ray
}
function estadisticas(){
v2ray stats
}
function cdn(){
v2raycdn
}
function protocolo(){
v2ray stream
}
function tls(){
v2ray tls
}
function puerto(){
v2ray port
}
function inform(){
v2ray info
}
function deleter(){
v2ray del
}
function agre(){
v2ray add
}
function nuevo(){
v2ray new
}
main() {
  echo -e "
${YELLOW}╚>♞ VPSPACK v. $vpspackversion ♞<╝
${YELLOW} ═══════════════════════
${GREEN}1.▻ INSTALAR
${YELLOW} ═══════════════════════
${GREEN}2.▻ MENU MANAGER PLUS
${YELLOW} ═══════════════════════
${GREEN}3.▻ ESTADISTICAS
${YELLOW} ═══════════════════════
${GREEN}4.▻ ABRIR CDN
${YELLOW} ═══════════════════════
${GREEN}5.▻ ELEGIR PROTOCOLO
${YELLOW} ═══════════════════════
${GREEN}6.▻ ABRIR TLS
${YELLOW} ═══════════════════════
${GREEN}7.▻ ABRIR PUERTO
${YELLOW} ═══════════════════════
${GREEN}8.▻ INFORMACION
${YELLOW} ═══════════════════════
${GREEN}9.▻ ELIMINAR GRUPO
${YELLOW} ═══════════════════════
${GREEN}10.▻ CREAR GRUPO
${YELLOW} ═══════════════════════
${GREEN}11.▻ NUEVO GRUPO
${YELLOW} ═══════════════════════
${GREEN}0.↫ REGRESAR${NO_COLOR}"
  read -rp "Elija una opcion：" menu_num
  case $menu_num in
  1)
    install
    ;;
  2)
    menu
    ;;
  3)
    estadisticas
    ;;
  4)
    cdn
    ;;
  5)
    protocolo
    ;;
  6)
    tls
    ;;  
  7)
    puerto
    ;;
  8)
    inform
    ;;
  9)
    deleter
    ;;
  10)
    agre
    ;;
  11)
    nuevo
    ;;
  0)
    vpspack
    ;;  
  esac
}
main
