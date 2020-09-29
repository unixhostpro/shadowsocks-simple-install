#!/bin/bash
export PORT=8000
export PASSWORD=$( cat /dev/urandom | tr --delete --complement 'a-z0-9' | head --bytes=16 )
export IP=$(hostname -I)

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

function config_info() {
	echo
	echo "---------------------------------------"
	echo "Your shadowsocks proxy configuration:"
	echo "URL: ss://$(generate_hash chacha20-ietf-poly1305 $PASSWORD)@$IP:$PORT"
	echo "---------------------------------------"
#	echo "Android client: https://play.google.com/store/apps/details?id=com.github.shadowsocks"
#	echo "Clients for other devices: https://shadowsocks.org/en/download/clients.html"
}


apt update
apt install -y shadowsocks-libev # install shadowsocks
mkdir -p /etc/shadowsocks-libev # ceate config directory
config /etc/shadowsocks-libev/config.json "$PORT" "$PASSWORD"
ufw_port $PORT
systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev
config_info "$PORT" "$PASSWORD"
