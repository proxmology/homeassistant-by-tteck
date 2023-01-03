#!/usr/bin/env bash
function header_info {
  cat <<"EOF"
    ___       __                           __
   /   | ____/ /___ ___v5______ __________/ /
  / /| |/ __  / __  / / / / __  / ___/ __  / 
 / ___ / /_/ / /_/ / /_/ / /_/ / /  / /_/ /  
/_/  |_\__,_/\__, /\__,_/\__,_/_/   \__,_/   
            /____/                           
 
EOF
}
echo -e "Loading..."
APP="Adguard"
var_disk="2"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="11"

#bash -c "$(wget -qLO - https://raw.githubusercontent.com/tteck/Proxmox/v5/ct/debian-whip.sh)"

function update_script() {
clear
header_info
msg_info "Stopping AdguardHome"
systemctl stop AdGuardHome
msg_ok "Stopped AdguardHome"

msg_info "Updating AdguardHome"
wget -qL https://static.adguard.com/adguardhome/release/AdGuardHome_linux_amd64.tar.gz
tar -xvf AdGuardHome_linux_amd64.tar.gz &>/dev/null
mkdir -p adguard-backup
cp -r /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome/data adguard-backup/
cp AdGuardHome/AdGuardHome /opt/AdGuardHome/AdGuardHome
cp -r adguard-backup/* /opt/AdGuardHome/
msg_ok "Updated AdguardHome"

msg_info "Starting AdguardHome"
systemctl start AdGuardHome
msg_ok "Started AdguardHome"

msg_info "Cleaning Up"
rm -rf AdGuardHome_linux_amd64.tar.gz AdGuardHome adguard-backup
msg_ok "Cleaned"
msg_ok "Update Successfull"
exit
}

clear
if ! command -v pveversion >/dev/null 2>&1; then update_script; else bash <(curl -fsSL https://raw.githubusercontent.com/tteck/Proxmox/v5/ct/debian-whip.sh); fi
if [ "$VERB" == "yes" ]; then set -x; fi
if [ "$CT_TYPE" == "1" ]; then
  FEATURES="nesting=1,keyctl=1"
else
  FEATURES="nesting=1"
fi
TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null
export VERBOSE=$VERB
export STD=$VERB2
export SSH_ROOT=${SSH}
export CTID=$CT_ID
export PCT_OSTYPE=$var_os
export PCT_OSVERSION=$var_version
export PCT_DISK_SIZE=$DISK_SIZE
export PCT_OPTIONS="
  -features $FEATURES
  -hostname $HN
  $SD
  $NS
  -net0 name=eth0,bridge=$BRG$MAC,ip=$NET$GATE$VLAN
  -onboot 1
  -cores $CORE_COUNT
  -memory $RAM_SIZE
  -unprivileged $CT_TYPE
  $PW
"
bash -c "$(wget -qLO - https://raw.githubusercontent.com/tteck/Proxmox/main/ct/create_lxc.sh)" || exit
msg_info "Starting LXC Container"
pct start $CTID
msg_ok "Started LXC Container"
lxc-attach -n $CTID -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/tteck/Proxmox/v5/install/$var_install.sh)" || exit
IP=$(pct exec $CTID ip a s dev eth0 | sed -n '/inet / s/\// /p' | awk '{print $2}')
pct set $CTID -description "# ${APP} LXC
### https://tteck.github.io/Proxmox/
<a href='https://ko-fi.com/D1D7EP4GF'><img src='https://img.shields.io/badge/☕-Buy me a coffee-red' /></a>"
msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"
