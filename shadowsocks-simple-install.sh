#!/bin/bash
export PORT=8000
export PASSWORD=$( cat /dev/urandom | tr --delete --complement 'a-z0-9' | head --bytes=16 )
export IP=$(hostname -I)
export ENCRYPTION=chacha20-ietf-poly1305
function config() {
cat > "$1" <<EOF
{
    "server":"0.0.0.0",
    "server_port":$2,
    "local_port":1080,
    "password":"$3",
    "timeout":60,
    "method":"$ENCRYPTION"
}
EOF
}

function generate_hash() {
	echo -n "$1":"$2" | base64
}

function config_info() {
	echo
	echo "---------------------------------------"
	echo "GitHub : https://github.com/unixhostpro/shadowsocks-simple-install"
	echo "web: https://unixhost.pro"
	echo "--------------------------------------- "
	echo "Your shadowsocks proxy configuration:"
	echo "URL: ss://$(generate_hash chacha20-ietf-poly1305 $PASSWORD)@$IP:$PORT"
	echo "---------------------------------------"
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
config /etc/shadowsocks-libev/config.json "$PORT" "$PASSWORD"
systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev
config_info "$PORT" "$PASSWORD"
