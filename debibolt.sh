#!/bin/sh
# RaspiBolt LND Mainnet: systemd unit for getpublicip.sh script
# /etc/systemd/system/20-raspibolt-welcome.sh

# make executable

#############USER VARIABLES##################

# set colors
color_red='\033[0;31m'
color_green='\033[0;32m'
color_yellow='\033[0;33m'
color_gray='\033[0;37m'

# set data locations
bitcoin_dir="/home/XXUSER/bitcoin" #bitcoind working directory. Bitcoind default is /home/YourUsername/.bitcoin  NOTE:Does not work with unix convention of ~/ for home directory. you MUST use an absolute path (/home/USER/.bitcoin)
lnd_dir="/home/XXUSER/.lnd/data/chain/bitcoin/mainnet" #location of readonly.macaroon default: /home/USER/.lnd/data/chain/bitcoin/mainnet NOTE:leave the last '/' off the path
tls_dir="/home/XXUSER/.lnd" #location of tls.cert default: /home/USER/.lnd  NOTE:leave the last '/' off the path

#Set RPC username and password here. uses Username/PW pair generated by rpcauth.py in the bitcoin core respository
rpc_user="JOEBLOW"
rpc_pw="SuperSecretPasswordbyRPAUTH.py"

#Misc  
system_name="DebiBolt"
network_adapter="eth0" #often eth0, but may also be enp0sXX or other name if you have Debian 'predictable network naming' enabled. You can check with ifconfig 
second_hdd="/mnt/hdd" #mount point of second physical volume (in the form /mount/point) if applicable. Us this if your bitcoin data is stored on a different physical volume than root (/)

###########################SCRIPT START#################

# get uptime & load
load=$(w | grep "load average:" | cut -c11-)

# get CPU temp
cpu=$(cat /sys/class/thermal/thermal_zone0/temp)
cpu_c=$((cpu/555))
temp=$((cpu_c+32))

# get memory
ram_avail=$(free -m | grep Mem | awk '{ print $7 }')
ram=$(printf "%sM / %sM" "${ram_avail}" "$(free -m | grep Mem | awk '{ print $2 }')")

if [ ${ram_avail} -lt 100 ]; then
  color_ram="${color_red}\e[7m"
else
  color_ram=${color_green}
fi

# get SD card storage OLD SECTION USED ON RASPiBOLT TO CHECK SD CARD
#sd_free_ratio=$(printf "%d" "$(df -h | grep "/$" | awk '{ print $4/$2*100 }')") 2>/dev/null
#sd=$(printf "%s (%s%%)" "$(df -h | grep '/$' | awk '{ print $4 }')" "${sd_free_ratio}")
#if [ ${sd_free_ratio} -lt 10 ]; then
#  color_sd="${color_red}"
#else
#  color_sd=${color_green}
#fi

#primary HDD
hd1_free_ratio=$(printf "%d" "$(df -h | grep "/$" | awk '{ print $4/$2*100 }')") 2>/dev/null
hd1=$(printf "%s (%s%%)" "$(df -h | grep '/$' | awk '{ print $4 }')" "${hd1_free_ratio}")

if [ ${hd1_free_ratio} -lt 10 ]; then
  color_hd1="${color_red}\e[7m"
else
  color_hd1=${color_green}
fi

#2nd HDD
hd2_free_ratio=$(printf "%d" "$(df -h | grep "${second_hdd}$" | awk '{ print $4/$2*100 }')") 2>/dev/null
hd2=$(printf "%s (%s%%)" "$(df -h | grep "${second_hdd}$" | awk '{ print $4 }')" "${hd2_free_ratio}")

if [ ${hd2_free_ratio} -lt 10 ]; then
  color_hd2="${color_red}\e[7m"
else
  color_hd2=${color_green}
fi



# get network traffic
network_rx=$(ifconfig ${network_adapter} | grep 'RX packets' | awk '{ print $6$7 }' | sed 's/[()]//g')
network_tx=$(ifconfig ${network_adapter} | grep 'TX packets' | awk '{ print $6$7 }' | sed 's/[()]//g')

# Bitcoin blockchain
btc_path=$(command -v bitcoin-cli)
if [ -n ${btc_path} ]; then
  btc_title="Bitcoin"
  chain="$(bitcoin-cli -datadir=${bitcoin_dir} -rpcuser=${rpc_user} -rpcpassword=${rpc_pw} getblockchaininfo | jq -r '.chain')"
  if [ -n $chain ]; then
    btc_title="${btc_title} (${chain}net)"

    # get sync status
    block_chain="$(bitcoin-cli -datadir=${bitcoin_dir} -rpcuser=${rpc_user} -rpcpassword=${rpc_pw} getblockchaininfo | jq -r '.headers')"
    block_verified="$(bitcoin-cli -datadir=${bitcoin_dir} -rpcuser=${rpc_user} -rpcpassword=${rpc_pw} getblockchaininfo | jq -r '.blocks')"
    block_diff=$(expr ${block_chain} - ${block_verified})

    progress="$(bitcoin-cli -datadir=${bitcoin_dir} -rpcuser=${rpc_user} -rpcpassword=${rpc_pw} getblockchaininfo | jq -r '.verificationprogress')"
    sync_percentage=$(printf "%.2f%%" "$(echo $progress | awk '{print 100 * $1}')")

    if [ ${block_diff} -eq 0 ]; then    # fully synced
      sync="OK"
      sync_color="${color_green}"
      sync_behind=" "
    elif [ ${block_diff} -eq 1 ]; then          # fully synced
      sync="OK"
      sync_color="${color_green}"
      sync_behind="-1 block"
    elif [ ${block_diff} -le 10 ]; then    # <= 2 blocks behind
      sync="Catching up"
      sync_color="${color_red}"
      sync_behind="-${block_diff} blocks"
    else
      sync="In progress"
      sync_color="${color_red}"
      sync_behind="${sync_percentage}"
    fi

    # get last known block
    last_block="$(bitcoin-cli -datadir=${bitcoin_dir} -rpcuser=${rpc_user} -rpcpassword=${rpc_pw} getblockcount)"
    if [ ! -z "${last_block}" ]; then
      btc_line2="${btc_line2} ${color_gray}(block ${last_block})"
    fi

   # get mem pool transactions
    mempool="$(bitcoin-cli -datadir=${bitcoin_dir} -rpcuser=${rpc_user} -rpcpassword=${rpc_pw} getmempoolinfo | jq -r '.size')"

   # get number of peers
    peers="$(bitcoin-cli -datadir=${bitcoin_dir} -rpcuser=${rpc_user} -rpcpassword=${rpc_pw} getconnectioncount)"

  else
    btc_line2="${color_red}NOT RUNNING\t\t"
  fi
fi


# get public IP address & port
public_ip=$(curl -s ipinfo.io/ip)
#public_port=$(cat ${bitcoin_dir}/bitcoin.conf 2>/dev/null | grep port= | awk -F"=" '{print $2}')
if [ "${public_port}" = "" ]; then
  if [ $chain  = "test" ]; then
    public_port=18333
  else
    public_port=8333
  fi
fi

public_check=$(timeout 2s nc -z ${public_ip} ${public_port}; echo $?)
if [ $public_check = "0" ]; then
  public="Yes"
  public_color="${color_green}"
else
  public="Not reachable"
  public_color="${color_red}"
fi
public_addr="${public_ip}:${public_port}"

# get LND info

/usr/local/bin/lncli --macaroonpath=${lnd_dir}/readonly.macaroon --tlscertpath=${tls_dir}/tls.cert getinfo 2>&1 | grep "Please unlock" >/dev/null
wallet_unlocked=$?
if [ "$wallet_unlocked" -eq 0 ] ; then
 alias_color="${color_red}"
 ln_alias="Wallet Locked"
else
 alias_color="${color_grey}"
 ln_alias="$(/usr/local/bin/lncli --macaroonpath=${lnd_dir}/readonly.macaroon --tlscertpath=${tls_dir}/tls.cert getinfo | jq -r '.alias')" 2>/dev/null
 ln_walletbalance="$(/usr/local/bin/lncli --macaroonpath=${lnd_dir}/readonly.macaroon --tlscertpath=${tls_dir}/tls.cert walletbalance | jq -r '.confirmed_balance')" #2>/dev/null
 ln_channelbalance="$(/usr/local/bin/lncli --macaroonpath=${lnd_dir}/readonly.macaroon --tlscertpath=${tls_dir}/tls.cert channelbalance | jq -r '.balance')" 2>/dev/null
	
fi

ln_channels_online="$(/usr/local/bin/lncli --macaroonpath=${lnd_dir}/readonly.macaroon --tlscertpath=${tls_dir}/tls.cert getinfo | jq -r '.num_active_channels')" 2>/dev/null
ln_channels_total="$(/usr/local/bin/lncli --macaroonpath=${lnd_dir}/readonly.macaroon --tlscertpath=${tls_dir}/tls.cert listchannels | jq '.[] | length')" 2>/dev/null
ln_external="$(/usr/local/bin/lncli --macaroonpath=${lnd_dir}/readonly.macaroon --tlscertpath=${tls_dir}/tls.cert getinfo | jq -r '.uris[0]' | tr "@" " " |  awk '{ print $2 }')" 2>/dev/null
ln_external_ip="$(echo $ln_external | tr ":" " " | awk '{ print $1 }' )" 2>/dev/null
if [ "$ln_external_ip" = "$public_ip" ]; then
  external_color="${color_grey}"
else
  external_color="${color_red}"
fi


printf "
${color_red}   _assSSSSSssa,     ${color_yellow}%s: ${color_gray}Bitcoin Core & LND
${color_red} ,SP           SS.   ${color_yellow}%s
${color_red},SP    ,ggs.    SS   ${color_gray}%s, CPU Temp %s°F
${color_red}dS   ,SP '      SP
${color_red}SD    YSb._    dP    ${color_yellow}%-24s   %-22s %-20s
${color_red} YS.    YSSSPaa      ${color_gray}Memory     ${color_ram}%-16s${color_gray}Sync    ${sync_color}%-14s${color_gray} ${alias_color}%s
${color_red}   Sb                ${color_gray}/          ${color_hd1}%-16s${color_gray}	      %-9s${external_color}%s
${color_red}     YS.             ${color_gray}%-11s${color_hd2}%-16s${color_gray}Public  ${public_color}%-14s ${color_gray}%s/%s Channels
${color_red}       Sb.           ${color_gray}Traffic    ▲ %-12s  %-20s   ฿ %12s sat
${color_red}         YSb.        ${color_gray}           ▼ %-12s  Mempool %-14s ฿ %12s sat
${color_red}                     ${color_gray}	  	  	        Last Block...%-7s
${color_gray}					        Peers........%s
%s %s
" \
${system_name} \
"-------------------------------------------------------------------" \
"${load}" "${temp}" \
"Resources free" "${btc_title}" "Lightning (LND)" \
"${ram}" "${sync}" "${ln_alias}" \
"${hd1}" "${sync_behind}" "${ln_external}" \
"${second_hdd}" "${hd2}" "${public}" "${ln_channels_online}" "${ln_channels_total}" \
"${network_tx}" "${public_addr}" "${ln_walletbalance}" \
"${network_rx}" "${mempool} tx" "${ln_channelbalance}" \
"${last_block}" \
"${peers}" \
""

echo "$(tput -T xterm sgr0)"
