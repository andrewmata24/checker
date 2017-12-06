#!/bin/sh
#
#simple script used to monitor node connectivity to neighboring nodes and net
#Device will raise treshhold by +1 for each unavilable service at that time
#if score is greater than 20, device will reboot once.
#This will mark the device as rebooted once. If the device reboots a second time.
#the mesh will be rebuilt (May extend this further as we test)
#
#
#Load current score, script start timestamp and check if device has rebooted before.
REBOOT_FILE="/etc/netcheck/rbtscore";
TIME_START_FILE="/etc/netcheck/time-start";
REBOOTED_FILE="/etc/netcheck/has-rebooted";

addrs=" 10.0.0.1 127.0.0.1 8.8.8.8";
current_time=`date '+%s'`;

read reboot_score < $REBOOT_FILE;
read init_time < $TIME_START_FILE;
read has_rebooted < $REBOOTED_FILE;

#loop through each address and check if available. If not score raised by +1
for addr in $addrs
  do
    if ! ping -c 1 "$addr" > /dev/null ; then
      reboot_score=$((reboot_score + 1));
      echo $reboot_score > $REBOOT_FILE;
    fi
  done

#Check if we should reboot and if the device has rebooted previously. Either
#simple or requires mesh rebuild.
if [ $reboot_score -gt 20 ]; then
  if [ $has_rebooted -eq 1 ]; then
    echo "mesh rebuild incoming";
    rm -f /etc/mesh-setup-done;
    echo `date '+%s'` > $TIME_START_FILE;
    echo 0 > $REBOOTED_FILE;
    echo 0 > $REBOOT_FILE;
    sh /bin/mesh.sh;
    exit 0;
  fi
  echo `date '+%s'` > $TIME_START_FILE;
  echo 1 > $REBOOTED_FILE;
  echo 0 > $REBOOT_FILE;
  reboot;
  exit 0;
fi

#If device has experienced no major issue in 2 hours. Reset score to 0 to avoid
#pointless reboots.
time_since=$(($current_time-$init_time));
echo $time_since;
if [ $time_since -gt 7200 ]; then
  echo 0 > $REBOOT_FILE;
  echo `date '+%s'` > $TIME_START_FILE;
fi
