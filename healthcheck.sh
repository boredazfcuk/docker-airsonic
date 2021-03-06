#!/bin/ash

if [ "$(netstat -plnt | grep -c 4040)" -ne 1 ]; then
   echo "Airsonic HTTP port 4040 is not responding"
   exit 1
fi

if [ "$(hostname -i 2>/dev/null | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | wc -l)" -eq 0 ]; then
   echo "NIC missing"
   exit 1
fi

echo "Airsonic ports 4040 responding OK"
exit 0