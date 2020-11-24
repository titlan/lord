#!/bin/bash

blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
#copy from 秋水逸冰 ss scripts
if [[ -f /etc/redhat-release ]]; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
fi

function install_trojan(){
$systemPackage -y install net-tools
Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
Port443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`
if [ -n "$Port80" ]; then
    process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
    red "════════════════════════════════════════════════════════════"
    red "El puerto 80 está ocupado, el puerto ocupado es: ${process80},la instalación terminó"
    red "════════════════════════════════════════════════════════════"
    exit 1
fi
if [ -n "$Port443" ]; then
    process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
    red "════════════════════════════════════════════════════════════"
    red "El puerto 443 está ocupado, el puerto ocupado es: ${process443},la instalación terminó"
    red "════════════════════════════════════════════════════════════"
    exit 1
fi
CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
if [ "$CHECK" == "SELINUX=enforcing" ]; then
    red "════════════════════════════════════════════════════════════"
    red "Para evitar que no se pueda solicitar un certificado, reinicie el VPS antes de ejecutar este script"
    red "════════════════════════════════════════════════════════════"
    read -p "¿Quieres reiniciar ahora? Por favor ingresa [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
	    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
	    echo -e "VPS reiniciando..."
	    reboot
	fi
    exit
fi
if [ "$CHECK" == "SELINUX=permissive" ]; then
    red "═══════════════════════════════════════════════════════════════════════"
    red "Para evitar que no se pueda solicitar un certificado, reinicie el VPS antes de ejecutar este script."
    red "═══════════════════════════════════════════════════════════════════════"
    read -p "¿Quieres reiniciar ahora? Por favor ingresa [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
	    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
	    echo -e "VPS reiniciando..."
	    reboot
	fi
    exit
fi
if [ "$release" == "centos" ]; then
    if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
    red "════════════════════════════════"
    red "El sistema actual no es compatible"
    red "════════════════════════════════"
    exit
    fi
    if  [ -n "$(grep ' 5\.' /etc/redhat-release)" ] ;then
    red "════════════════════════════════"
    red "El sistema actual no es compatible"
    red "════════════════════════════════"
    exit
    fi
    systemctl stop firewalld
    systemctl disable firewalld
    rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
elif [ "$release" == "ubuntu" ]; then
    if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
    red "════════════════════════════════"
    red "El sistema actual no es compatible"
    red "════════════════════════════════"
    exit
    fi
    if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
    red "════════════════════════════════"
    red "El sistema actual no es compatible"
    red "════════════════════════════════"
    exit
    fi
    systemctl stop ufw
    systemctl disable ufw
    apt-get update
fi
$systemPackage -y install  nginx wget unzip zip curl tar >/dev/null 2>&1
systemctl enable nginx
systemctl stop nginx
green "═════════════════════════════════════════════"
blue "Ingrese el nombre de dominio vinculado a su IP"
green "═════════════════════════════════════════════"
read your_domain
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
if [ $real_addr == $local_addr ] ; then
	green "══════════════════════════════"
	green "    Comience a instalar Trojan"
	green "══════════════════════════════"
	sleep 1s
cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    server {
        listen       80;
        server_name  $your_domain;
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    }
}
EOF
	#设置伪装站
	rm -rf /usr/share/nginx/html/*
	cd /usr/share/nginx/html/
	wget https://github.com/atrandys/v2ray-ws-tls/raw/master/web.zip
    	unzip web.zip
	systemctl start nginx
	sleep 5
	#申请https证书
	mkdir /usr/src/trojan-cert /usr/src/trojan-temp
	curl https://get.acme.sh | sh
	~/.acme.sh/acme.sh  --issue  -d $your_domain  --nginx
    	~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /usr/src/trojan-cert/private.key \
        --fullchain-file /usr/src/trojan-cert/fullchain.cer
	if test -s /usr/src/trojan-cert/fullchain.cer; then
        cd /usr/src
	#wget https://github.com/trojan-gfw/trojan/releases/download/v1.13.0/trojan-1.13.0-linux-amd64.tar.xz
	wget https://api.github.com/repos/trojan-gfw/trojan/releases/latest
	latest_version=`grep tag_name latest| awk -F '[:,"v]' '{print $6}'`
	wget https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-linux-amd64.tar.xz
	tar xf trojan-${latest_version}-linux-amd64.tar.xz
	#下载trojan客户端
	wget https://github.com/atrandys/trojan/raw/master/trojan-cli.zip
	wget -P /usr/src/trojan-temp https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-win.zip
	unzip trojan-cli.zip
	unzip /usr/src/trojan-temp/trojan-${latest_version}-win.zip -d /usr/src/trojan-temp/
	cp /usr/src/trojan-cert/fullchain.cer /usr/src/trojan-cli/fullchain.cer
	mv -f /usr/src/trojan-temp/trojan/trojan.exe /usr/src/trojan-cli/ 
	trojan_passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
	cat > /usr/src/trojan-cli/config.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$your_domain",
    "remote_port": 443,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "fullchain.cer",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF
	rm -rf /usr/src/trojan/server.conf
	cat > /usr/src/trojan/server.conf <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/usr/src/trojan-cert/fullchain.cer",
        "key": "/usr/src/trojan-cert/private.key",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF
	cd /usr/src/trojan-cli/
	zip -q -r trojan-cli.zip /usr/src/trojan-cli/
	trojan_path=$(cat /dev/urandom | head -1 | md5sum | head -c 16)
	mkdir /usr/share/nginx/html/${trojan_path}
	mv /usr/src/trojan-cli/trojan-cli.zip /usr/share/nginx/html/${trojan_path}/
	#增加启动脚本
	
cat > ${systempwd}trojan.service <<-EOF
[Unit]  
Description=trojan  
After=network.target  
   
[Service]  
Type=simple  
PIDFile=/usr/src/trojan/trojan/trojan.pid
ExecStart=/usr/src/trojan/trojan -c "/usr/src/trojan/server.conf"  
ExecReload=  
ExecStop=/usr/src/trojan/trojan  
PrivateTmp=true  
   
[Install]  
WantedBy=multi-user.target
EOF

	chmod +x ${systempwd}trojan.service
	systemctl start trojan.service
	systemctl enable trojan.service
	green "══════════════════════════════════════════════════════════════════════════════════"
	green "Trojan se ha instalado,utilice el enlace a continuación para descargar su servidor"
	green "1. Copie el enlace a continuación"
	blue "http://${your_domain}/$trojan_path/trojan-cli.zip"
	green "══════════════════════════════════════════════════════════════════════════════════"
	else
        red "══════════════════════════════════════════════════════════════════════════════════"
	red "No hay resultado de aplicación para el certificado https y falla la instalación automática"
	green "No se preocupe, puede corregir la solicitud de certificado manualmente"
	green "1. Reiniciar VPS"
	green "2. Vuelva a ejecutar el script y use la función de certificado de reparación"
	red "══════════════════════════════════════════════════════════════════════════════════"
	fi
	
else
	red "════════════════════════════════"
	red "SU DOMINIO NO COINCIDE CON LA IP"
	red "ASEGURESE QUE LA IP APUNTA A SU DOMINIO"
	red "════════════════════════════════"
fi
}

function repair_cert(){
green "══════════════════════════════"
blue "INGRESE EL NOMBRE DE SU DOMINIO"
blue "ASEGURESE QUE ES CORRECTO"
green "══════════════════════════════"
read your_domain
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
if [ $real_addr == $local_addr ] ; then
    ~/.acme.sh/acme.sh  --issue  -d $your_domain  --nginx
    ~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /usr/src/trojan-cert/private.key \
        --fullchain-file /usr/src/trojan-cert/fullchain.cer
    if test -s /usr/src/trojan-cert/fullchain.cer; then
        green "Solicitud de certificado exitosa"
	green "/usr/src/trojan-cert/fullchain.certrojan-cli"
	systemctl restart trojan
    else
    	red "No se pudo solicitar el certificado"
    fi
else
    red "════════════════════════════════"
    red "SU DOMINIO NO COINCIDE CON LA IP"
    red "ASEGURESE QUE SU IP APUNTA A SU DOMINIO"
    red "════════════════════════════════"
fi	
}

function remove_trojan(){
    red "════════════════════════════════"
    red "se desinstalara Trojan"
    red "desinstalando nginx"
    red "════════════════════════════════"
    systemctl stop trojan
    systemctl disable trojan
    rm -f ${systempwd}trojan.service
    if [ "$release" == "centos" ]; then
        yum remove -y nginx
    else
        apt autoremove -y nginx
    fi
    rm -rf /usr/src/trojan*
    rm -rf /usr/share/nginx/html/*
    green "════════════════"
    green "Trojan eliminado"
    green "════════════════"
}

function update_trojan(){
    green "═════════════"
    green "en desarrollo"
    green "═════════════"
}

start_menu(){
    clear
    green "════════════════════"
    green "    T R O J A N     "
    green "════════════════════"
    echo
    green " 1. INSTALAR Trojan"
    red " 2. DESINSTALAR Trojan"
    blue " 0. REGRESAR"
    echo
    read -p "elija una opcion:" num
    case "$num" in
    1)
    install_trojan
    ;;
    2)
    remove_trojan 
    ;;
    0)
    vpspack
    ;;
    *)
    clear
    red "Ingrese el número correcto"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu
