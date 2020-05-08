#!/bin/ash

if [ "$(netstat -plnt | grep -c 4040)" -ne 1 ]; then
   echo "Airsonic HTTP port 4040 is not responding"
   exit 1
fi

echo "Airsonic ports 4040 responding OK"
exit 0