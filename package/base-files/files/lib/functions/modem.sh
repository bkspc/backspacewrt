. /lib/functions.sh
. /lib/functions/network.sh

cdr2mask() {
  set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
  [ $1 -gt 1 ] && shift $1 || shift
  echo ${1-0}.${2-0}.${3-0}.${4-0}
}

ip_sum() {
  IFS='.' read -r a b c d << EOF
$1
EOF
  echo "$(($a + $b + $c + $d + 100))"
}

setup_ip_passthrough() {
  local dev=$1
  local dnsmasq_config_file="/tmp/dnsmasq.d/ippassthrough${dev}"

  config_load network
  config_get bridge_type ${dev} bridge_type
  config_get bridge_device ${dev} bridge_device
  config_get bridge_device_mac ${dev} bridge_device_mac
  config_get_bool bridge_p2p ${dev} bridge_p2p
  config_get bridge_table ${dev} bridge_table

  network_flush_cache
  network_get_device wan_device ${dev}
  network_get_ipaddr wan_ipaddr ${dev}
  network_get_gateway wan_gateway ${dev}
  network_get_subnets wan_subnet ${dev}
  network_get_dnsserver wan_dnsserver ${dev}
  local wan_dns1=$(echo ${wan_dnsserver} | cut -d' ' -f1)
  local wan_dns2=$(echo ${wan_dnsserver} | cut -d' ' -f2)
  local wan_mask=$(echo ${wan_subnet} | cut -d'/' -f2)
  local wan_networkaddr=$(ipcalc.sh ${wan_ipaddr}/${wan_mask} | grep NETWORK | cut -d= -f2)
  local wan_table=${bridge_table:-$(ip_sum ${wan_ipaddr})}
  local wan_subnetmask
  if [ "${bridge_p2p}" = '1' ]; then
    wan_subnetmask=255.255.255.255
  else
    wan_subnetmask=$(cdr2mask ${wan_mask})
  fi

  ip link set ${bridge_device} up

  ip route del default via ${wan_gateway} dev ${wan_device}
  ip route del ${wan_networkaddr}/${wan_mask} dev ${wan_device}
  ip addr del ${wan_subnet} dev ${wan_device}

  ip addr add ${wan_gateway}/${wan_mask} dev ${bridge_device}
  ip route add ${wan_networkaddr}/${wan_mask} dev ${bridge_device}
  ip route add default dev ${wan_device} table ${wan_table}
  ip rule add iif ${bridge_device} lookup ${wan_table} pref 10000
  sysctl net.ipv4.conf.${bridge_device}.proxy_arp=1

  # POSTROUTING is not overriden by the nft chain so lets keep using iptables
  iptables -t nat -I POSTROUTING -o ${wan_device} -j ACCEPT

  if [ "${bridge_type}" = "passthrough" ]; then
    iptables -w -tnat -I POSTROUTING -o ${wan_device} -j SNAT --to ${wan_ipaddr}
    ip route add default dev ${wan_device}
  fi

  echo "dhcp-range=tag:${wan_device}_bridge,${wan_ipaddr},static,${wan_subnetmask},2m" > ${dnsmasq_config_file}
  echo "shared-network=${bridge_device},${wan_ipaddr}" >> ${dnsmasq_config_file}
  echo "dhcp-host=*:*:*:*:*:*,set:${wan_device}_bridge,${wan_ipaddr}" >> ${dnsmasq_config_file}
  echo "dhcp-option=tag:${wan_device}_bridge,${bridge_device},3,${wan_gateway}" >> ${dnsmasq_config_file}

  if [ -n "$wan_dns1" ] || [ -n "$wan_dns2" ]; then
    echo "dhcp-option=tag:${wan_device}_bridge,${bridge_device},6${wan_dns1:+,$wan_dns1}${wan_dns2:+,$wan_dns2}" >> ${dnsmasq_config_file}
    echo "server=$wan_dns1" >> ${dnsmasq_config_file}
    echo "server=$wan_dns2" >> ${dnsmasq_config_file}
  fi

  /etc/init.d/dnsmasq restart
}

teardown_ip_passthrough() {
  local dev=$1

  rm "/tmp/dnsmasq.d/ippassthrough${dev}"

  config_load network
  config_get bridge_type ${dev} bridge_type
  config_get bridge_device ${dev} bridge_device
  config_get bridge_table ${dev} bridge_table

  network_flush_cache
  network_get_device wan_device ${dev}
  network_get_ipaddr wan_ipaddr ${dev}
  network_get_gateway wan_gateway ${dev}
  network_get_subnets wan_subnet ${dev}
  local wan_mask=$(echo ${wan_subnet} | cut -d'/' -f2)
  local wan_networkaddr=$(ipcalc.sh ${wan_ipaddr}/${wan_mask} | grep NETWORK | cut -d= -f2)
  local wan_table=${bridge_table:-$(ip_sum ${wan_ipaddr})}

  ip rule del iif ${bridge_device} lookup ${wan_table} pref 10000
  ip route del default dev ${wan_device} table ${wan_table}
  ip route del ${wan_networkaddr}/${wan_mask} dev ${bridge_device}
  ip addr del ${wan_gateway}/${wan_mask} dev ${bridge_device}

  handle=$(nft -a list chain inet fw4 forward | grep "iifname \"${wan_device}\" oifname \"${bridge_device}\"" | awk -F' ' '{ print $NF }')
  nft delete rule inet fw4 forward handle ${handle}
  handle=$(nft -a list chain inet fw4 forward | grep "iifname \"${bridge_device}\" oifname \"${wan_device}\"" | awk -F' ' '{ print $NF }')
  nft delete rule inet fw4 forward handle ${handle}

  handle=$(nft -a list chain inet fw4 input | grep "iifname \"${wan_device}\" accept" | awk -F' ' '{ print $NF }')
  nft delete rule inet fw4 input handle ${handle}
  handle=$(nft -a list chain inet fw4 input | grep "iifname \"${bridge_device}\" accept" | awk -F' ' '{ print $NF }')
  nft delete rule inet fw4 input handle ${handle}

  # POSTROUTING is not overriden by the nft chain so lets keep using iptables
  iptables -D POSTROUTING -tnat -o ${wan_device} -j ACCEPT

  if [ "${bridge_type}" = "passthrough" ]; then
    iptables -D POSTROUTING -tnat -o ${wan_device} -j SNAT --to ${wan_ipaddr}
    ip route del default dev ${wan_device}
  fi

  /etc/init.d/dnsmasq restart
}
