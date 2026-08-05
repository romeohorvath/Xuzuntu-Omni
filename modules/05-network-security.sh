#!/bin/bash
# Module: network & security tooling — analysis, auditing, firewall, VPN.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/xuzuntu.conf"
source "$ROOT/scripts/common.sh"

log "Modul: network-security"
install_packages \
    nmap net-tools tcpdump traceroute whois dnsutils iperf3 \
    wireshark aircrack-ng \
    firewalld openvpn wireguard-tools ufw

# Real firewall defaults: deny incoming, allow outgoing (ufw).
cat > "$ROOTFS/etc/ufw/ufw.conf" <<'CFG'
ENABLED=no
DEFAULT_INPUT_POLICY="DENY"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="DROP"
DEFAULT_APPLICATION_POLICY="SKIP"
MANAGE_BUILTINS=no
CFG

log "Modul: network-security kész"
