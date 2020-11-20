#!/bin/bash
export PORT=8000 # Если порт 8000 заблокирован в вашей сети, измените на любой бругой 
export PASSWORD=$( cat /dev/urandom | tr --delete --complement 'a-z0-9' | head --bytes=16 )
export IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
export ENCRYPTION=chacha20-ietf-poly1305
export V2RAY=$1

#colors for bash
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Off='\033[0m'       # Text Reset


function config() {
cat > "$1" <<EOF
{
    "server":"0.0.0.0",
    "server_port":$2,
    "local_port":1080,
    "password":"$3",
    "timeout":300,
    "method":"$ENCRYPTION"
}
EOF
}
function config_v2ray() {
cat > "$1" <<EOF
{
    "server":"0.0.0.0",
    "server_port":$2,
    "local_port":1080,
    "password":"$3",
    "plugin":"/etc/shadowsocks-libev/v2ray-plugin",
    "timeout":3000,
    "method":"$ENCRYPTION"
}
EOF
}

function generate_hash() {
	echo -n "$1":"$2" | base64
}

function config_info() {
	echo
	echo -e "${Yellow}---------------------------------------"
	echo -e "${Yellow}GitHub:${Off} https://github.com/unixhostpro/shadowsocks-simple-install"
	echo -e "${Yellow}Web:${Off}    ${Red}https://unixhost.pro${Off}"
	echo
	echo -e "${Yellow}---------------------------------------${Off}"
	echo 
	echo -e "${Green}Your shadowsocks proxy configuration:${Off}"
	echo -e "${Yellow}URL:${Off} ss://$(generate_hash chacha20-ietf-poly1305 $PASSWORD)@$IP:$PORT"
	echo
	echo -e "${Yellow}Windows Client :${Off} https://github.com/shadowsocks/shadowsocks-windows/releases"
	echo -e "${Yellow}Android Client :${Off} https://play.google.com/store/apps/details?id=com.github.shadowsocks"
	echo -e "${Yellow}iOS Client     :${Off} https://itunes.apple.com/app/outline-app/id1356177741"
	echo -e "${Yellow}Other Clients  :${Off} https://shadowsocks.org/en/download/clients.html"
	echo -e "${Yellow}---------------------------------------${Off}"
	echo
	echo -e "${Yellow}IP      :${Off} $IP "
	echo -e "${Yellow}Port    :${Off} $PORT "
	echo -e "${Yellow}Password:${Off} $PASSWORD "
	echo -e "${Yellow}---------------------------------------${Off}"
}
if [ -f "/etc/debian_version" ]; then
	DEBIAN_FRONTEND=noninteractive apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install -y shadowsocks-libev # install shadowsocks
	ufw allow "$PORT"/tcp
elif [ -f "/etc/redhat-release" ]; then
	yum install -y epel-release
	curl --location --output "/etc/yum.repos.d/librehat-shadowsocks-epel-7.repo" "https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo"
	yum makecache
	yum install -y bind-utils mbedtls
	ln -sf /usr/lib64/libmbedcrypto.so.1 /usr/lib64/libmbedcrypto.so.0
	yum install -y shadowsocks-libev
	systemctl daemon-reload
	systemctl enable shadowsocks-libev
	systemctl restart shadowsocks-libev
	firewall-cmd --zone=public --permanent --add-port="$PORT"/tcp
	firewall-cmd --reload
else
  echo "Your OS not supported"
  echo "Supported OS :"
  echo "	Ubuntu 18.04"
  echo "	Ubuntu 20.04"
  echo "	Centos 7.0"
fi

mkdir -p /etc/shadowsocks-libev # ceate config directory
if [ "$V2RAY" == "v2ray" ]; then
	wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.1/v2ray-plugin-linux-amd64-v1.3.1.tar.gz
	tar -xf v2ray-plugin-linux-amd64-v1.3.1.tar.gz
	sudo mv v2ray-plugin_linux_amd64 /etc/shadowsocks-libev/v2ray-plugin
	sudo chmod +x  /etc/shadowsocks-libev/v2ray-plugin
	sudo setcap 'cap_net_bind_service=+ep' /etc/shadowsocks-libev/v2ray-plugin
	sudo setcap 'cap_net_bind_service=+ep' /usr/bin/ss-server
	config_v2ray /etc/shadowsocks-libev/config.json "$PORT" "$PASSWORD"

elif [ -z "$V2RAY" ]; then
	config /etc/shadowsocks-libev/config.json "$PORT" "$PASSWORD"
else
echo -e  "${Red}v2ray plugin installed${Off}"
fi
systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev
config_info "$PORT" "$PASSWORD"
