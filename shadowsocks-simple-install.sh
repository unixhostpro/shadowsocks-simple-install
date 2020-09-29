#!/bin/bash
function config() {
cat > "$1" <<EOF
{
    "server":"0.0.0.0",
    "server_port":$2,
    "local_port":1080,
    "password":"$3",
    "timeout":60,
    "method":"chacha20-ietf-poly1305"
}
EOF
}

function ufw_port() {
	if type ufw > /dev/null; then
	        ufw allow "$2"/tcp
	fi
}

function generate_hash() {
	echo -n "$1":"$2" | base64
}

function config() {
	echo
	echo "---------------------------------------"
	echo "Your shadowsocks proxy configuration:"
	echo "URL: ss://$( generate_hash chacha20-ietf-poly1305 $1 )@$( get_external_address ):$2"
	echo "---------------------------------------"
#	echo "Android client: https://play.google.com/store/apps/details?id=com.github.shadowsocks"
#	echo "Clients for other devices: https://shadowsocks.org/en/download/clients.html"
}

apt update
apt install -y shadowsocks-libev # install shadowsocks
mkdir -p /etc/shadowsocks-libev # ceate config directory
config /etc/shadowsocks-libev/config.json $2 $3
ufw_port $2
systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev
