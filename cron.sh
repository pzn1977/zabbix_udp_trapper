#! /bin/bash

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export LC_ALL=C

while [ ! -e /tmp/zabbix_trapper_simpleudp.stop ]; do
  DEBUG=0
  test -e /tmp/zabbix_trapper_simpleudp.debug && DEBUG=1
  ./zabbix_trapper_simpleudp $DEBUG >> /var/log/zabbix_trapper_simpleudp.log 2>&1
  sleep 3
done
