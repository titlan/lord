#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#Disable China
wget http://iscn.kirito.moe/run.sh
. ./run.sh
if [[ $area == cn ]];then
echo "saludos"
exit
fi
#Check Root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: Debe ser usuario root para ejecutar este script${CEND}"; exit 1; }

#Check OS
if [ -f /etc/redhat-release ];then
        OS='CentOS'
    elif [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS='Debian'
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS='Ubuntu'
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
fi


# Get Public IP address
ipc=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1)
if [[ "$IP" = "" ]]; then
    ipc=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
fi

uuid=$(cat /proc/sys/kernel/random/uuid)

function Install(){
#Install Basic Packages
if [[ ${OS} == 'CentOS' ]];then
	yum install curl wget unzip ntp ntpdate -y
else
	apt-get update
	apt-get install curl unzip ntp wget ntpdate -y
fi

#Set DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf


#Update NTP settings
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/America/Tijuana /etc/localtime
ntpdate us.pool.ntp.org

#Disable SELinux
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi

#Run Install
cd /root

curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
    sucess_or_fail "v2ray包安装下载"
    curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh
    sucess_or_fail "v2ray数据包下载"
    bash install-release.sh
    sucess_or_fail "v2ray安装"
    bash install-dat-release.sh
    sucess_or_fail "v2ray数据包安装"

}

clear
echo 'Instalacion de V2Ray'

echo ''
echo 'este script apagara el firewall de iptables！'

while :; do echo
	read -p "Ingrese el nivel de usuario (ingrese 1 para uso personal, ingrese 0 para compartir:" level
	if [[ ! $level =~ ^[0-1]$ ]]; then
		echo "${CWARNING}Error de entrada Introduzca el número correcto!${CEND}"
	else
		break
	fi
done

echo ''

read -p "Ingrese el puerto principal (predeterminado: 32000):" mainport
[ -z "$mainport" ] && mainport=32000

echo ''

read -p "Está habilitado el enmascaramiento HTTP? (Habilitado de forma predeterminada) [y/n]:" ifhttpheader
	[ -z "$ifhttpheader" ] && ifhttpheader='y'
	if [[ $ifhttpheader == 'y' ]];then
		httpheader=',
    "streamSettings": {
      "network": "tcp",
      "tcpSettings": {
        "connectionReuse": true,
        "header": {
          "type": "http",
          "request": {
            "version": "1.1",
            "method": "GET",
            "path": ["/"],
            "headers": {
              "Host": ["www.baidu.com", "www.sogou.com/"],
              "User-Agent": [
                "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36",
                        "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"
              ],
              "Accept-Encoding": ["gzip, deflate"],
              "Connection": ["keep-alive"],
              "Pragma": "no-cache"
            }
          },
          "response": {
            "version": "1.1",
            "status": "200",
            "reason": "OK",
            "headers": {
              "Content-Type": ["application/octet-stream", "application/x-msdownload", "text/html", "application/x-shockwave-flash"],
              "Transfer-Encoding": ["chunked"],
              "Connection": ["keep-alive"],
              "Pragma": "no-cache"
            }
          }
        }
      }
    }'
	else
		httpheader=''
		read -p "Está habilitado el protocolo mKCP? (Habilitado de forma predeterminada) [y/n]:" ifmkcp
		[ -z "$ifmkcp" ] && ifmkcp='y'
		if [[ $ifmkcp == 'y' ]];then
        		mkcp=',
   		 		"streamSettings": {
   			 	"network": "kcp"
  				}'
		else
				mkcp=''
		fi
fi

echo ''

read -p "Habilitar el puerto dinámico? (Habilitado de forma predeterminada [y/n]:" ifdynamicport
  [ -z "$ifdynamicport" ] && ifdynamicport='y'
  if [[ $ifdynamicport == 'y' ]];then

    read -p "Punto de inicio del puerto de datos de entrada（por defecto：32001）:" subport1
    [ -z "$subport1" ] && subport1=32000

    read -p "Extremo del puerto de datos de entrada（por defecto：32500）:" subport2
    [ -z "$subport2" ] && subport2=32500

    read -p "Ingrese el número de puertos abiertos cada vez（por defecto：10）:" portnum
    [ -z "$portnum" ] && portnum=10

    read -p "Tiempo de cambio de puerto de entrada (unidad: minuto):" porttime
    [ -z "$porttime" ] && porttime=5
    dynamicport="
  \"inboundDetour\": [
    {
      \"protocol\": \"vmess\",
      \"port\": \"$subport1-$subport2\",
      \"tag\": \"detour\",
      \"settings\": {},
        \"allocate\": {
            \"strategy\": \"random\",
            \"concurrency\": $portnum,
            \"refresh\": $porttime
        }${mkcp}${httpheader}
            }
  ],
    "
  else
    dynamicport=''
  fi

echo ''

read -p "Está habilitado Mux.Cool? (Habilitado de forma predeterminada) [y/n]:" ifmux
  [ -z "$ifmux" ] && ifmux='y'
  if [[ $ifmux == 'y' ]];then
    mux=',
    "mux": {
      "enabled": true
    }
    '
  else
    mux=""
  fi

while :; do echo
  echo '1. HTTP'
  echo '2. Socks'
  read -p "seleccione el tipo de proxy: " chooseproxytype
  [ -z "$chooseproxytype" ] && chooseproxytype=1
  if [[ ! $chooseproxytype =~ ^[1-2]$ ]]; then
    echo 'ingrese el numero correcto！'
  else
    break
  fi
done

if [[ $chooseproxytype == 1 ]];then
  proxytype='http'
else
  proxytype='socks'
fi









#CheckIfInstalled
if [ ! -f "/usr/bin/v2ray/v2ray" ]; then
	Install
fi

#Disable iptables
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F

#Configure Server
service v2ray stop
rm -rf config
cat << EOF > config
{"log" : {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbound": {
    "port": $mainport,
    "protocol": "vmess",
    "settings": {
        "clients": [
            {
                "id": "$uuid",
                "level": $level,
                "alterId": 100
            }
        ]
    }${mkcp}${httpheader}
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  },
      ${dynamicport}
  "outboundDetour": [
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "strategy": "rules",
    "settings": {
      "rules": [
        {
          "type": "field",
          "ip": [
            "0.0.0.0/8",
            "10.0.0.0/8",
            "100.64.0.0/10",
            "127.0.0.0/8",
            "169.254.0.0/16",
            "172.16.0.0/12",
            "192.0.0.0/24",
            "192.0.2.0/24",
            "192.168.0.0/16",
            "198.18.0.0/15",
            "198.51.100.0/24",
            "203.0.113.0/24",
            "::1/128",
            "fc00::/7",
            "fe80::/10"
          ],
          "outboundTag": "blocked"
        }
      ]
    }
  }
}
EOF
rm -rf /etc/v2ray/config.back
mv /etc/v2ray/config.json /etc/v2ray/config.back
mv config /etc/v2ray/config.json

rm /root/config.json
cat << EOF > /root/config.json
{
  "log": {
    "loglevel": "info"
  },
  "inbound": {
    "port": 1080,
    "listen": "127.0.0.1",
    "protocol": "$proxytype",
    "settings": {
      "auth": "noauth",
      "udp": true,
      "ip": "127.0.0.1"
    }
  },
  "outbound": {
    "protocol": "vmess",
    "settings": {
        "vnext": [
            {
                "address": "$ipc",
                "port": $mainport,
                "users": [
                    {
                        "id": "$uuid",
                        "alterId": 100
                    }
                ]
            }
        ]
    }${mkcp}${httpheader}${mux}
  },
  "outboundDetour": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    }
  ],
  "dns": {
    "servers": [
      "8.8.8.8",
      "8.8.4.4",
      "localhost"
    ]
  },
  "routing": {
    "strategy": "rules",
    "settings": {
      "rules": [
        {
          "type": "chinasites",
          "outboundTag": "direct"
        },
        {
          "type": "field",
          "ip": [
            "0.0.0.0/8",
            "10.0.0.0/8",
            "100.64.0.0/10",
            "127.0.0.0/8",
            "169.254.0.0/16",
            "172.16.0.0/12",
            "192.0.0.0/24",
            "192.0.2.0/24",
            "192.168.0.0/16",
            "198.18.0.0/15",
            "198.51.100.0/24",
            "203.0.113.0/24",
            "::1/128",
            "fc00::/7",
            "fe80::/10"
          ],
          "outboundTag": "direct"
        },
        {
          "type": "chinaip",
          "outboundTag": "direct"
        }
      ]
    }
  }
}
EOF

service v2ray start
clear
#INstall Success
echo 'v2ray payload'
echo 'El archivo de configuración del cliente está en /root/config.json'
echo ''
echo "puerto：$mainport"
echo "UUID: $uuid"
