#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

cleanup() {
    kill TERM "$openvpn_pid"
    exit 0
}

is_enabled() {
    [[ ${1,,} =~ ^(true|t|yes|y|1|on|enable|enabled)$ ]]
}

# Either a specific file name or a pattern.
if [[ "${CONFIG_FILE:-}" != "" ]]; then
    config_file=$(find /config -name "$CONFIG_FILE" 2> /dev/null | sort | shuf -n 1)
else
    config_file=$(find /config -name '*.conf' -o -name '*.ovpn' 2> /dev/null | sort | shuf -n 1)
fi

if [[ -z $config_file ]]; then
    echo "no openvpn configuration file found" >&2
    exit 1
fi

echo "using openvpn configuration file: $config_file"

tmp_config_file="/tmp/openvpn_tmp.conf"

cat "$config_file" >> "$tmp_config_file"

openvpn_args=(
    "--config" "$tmp_config_file"
    "--cd" "/config"
)

if is_enabled "$KILL_SWITCH"; then
    openvpn_args+=("--route-up" "/usr/local/bin/killswitch.sh $ALLOWED_SUBNETS")
fi

if [[ -f "/etc/openvpn/up.sh" && ! -f "/etc/openvpn/update-resolv-conf" ]]; then
    openvpn_args+=("--up" "/etc/openvpn/up.sh")
    sed -i '/^up/s/^/#/' "$tmp_config_file"
fi

if [[ -f "/etc/openvpn/down.sh" && ! -f "/etc/openvpn/update-resolv-conf" ]]; then
    openvpn_args+=("--down" "/etc/openvpn/down.sh")
    sed -i '/^down/s/^/#/' "$tmp_config_file"
fi
# Docker secret that contains the credentials for accessing the VPN.
if [[ $AUTH_SECRET ]]; then
    openvpn_args+=("--auth-user-pass" "/run/secrets/$AUTH_SECRET")
fi

echo "Running with args: ${openvpn_args[@]}"
openvpn "${openvpn_args[@]}" &
openvpn_pid=$!

trap cleanup TERM

wait $openvpn_pid
