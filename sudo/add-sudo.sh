#!/bin/bash
HOSTLIST="/opt/qunar/tools/etc/adduser_hosts.cf"
SUDOFILE="/etc/sudoers"
#
for HOST  in `cat ${HOSTLIST}`
do
  ssh only.liu@${HOST} 'sudo grep "'$1'" '${SUDOFILE}'' > /dev/null
  if [ "$?" != 0 ]
  then
    echo "User $1 on ${HOST} not have sudo!"
    ssh only.liu@${HOST} 'echo "'$1' ALL=(ALL) NOPASSWD:ALL,!/bin/su"' >> ${SUD
    OFILE} && echo "User $1 add sudo success!"
  else
    echo "User $1 already have sudo!"
  fi
done
