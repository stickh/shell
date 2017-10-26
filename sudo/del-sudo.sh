#!/bin/bash
# Owner by Only.liu
# date 2012/11/01
HOSTLIST="/opt/qunar/tools/etc/adduser_hosts.cf"
SUDOFILE="/etc/sudoers"
#
for HOST  in `cat ${HOSTLIST}`
do
  ssh only.liu@${HOST} 'sudo grep "'$1'" '${SUDOFILE}'' > /dev/null
  if [ "$?" = 0 ]
  then
    echo "User $1 on ${HOST} have sudo!"
    ssh only.liu@${HOST} 'sudo sed -i '/$1/d' '${SUDOFILE}'' && echo "User $1 o
    n ${HOST} delete success!"
  else
    echo "User $1 on ${HOST} already delete sudo!"
  fi
done
