#!/bin/bash

# Variables
ARCH="$(uname -a)"
PHYS_CPU="$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)"
VCPU="$(grep "processor" /proc/cpuinfo | wc -l)"
MEM_PCT="$(free -m | grep "Mem:" | awk '{printf("%d/%dMB (%.2f%%)", $3, $2, $3/$2*100)}')"
DISK="$(df -BM / | awk 'NR==2 {printf("%d/%dMB (%d%%)", $3, $2, $5)}')"
CPU_LOAD="$(vmstat 1 2 | tail -1 | awk '{printf("%.1f%%", 100-$15)}')"
LAST_BOOT="$(who -b | awk '{print $3 " " $4}')"
LVM_checker="$(lsblk | grep -q "lvm" && echo "yes" || echo "no")"
TCP_CONN="$(ss -ta | grep -c "ESTAB")"
USER_COUNT="$(who | awk '{print $1}' | sort -u | wc -l)"
IP_MAC="$(hostname -I | awk '{print $1}') ($(ip link | awk '/link\/ether/ {print $2}'))"
SUDO_COUNT="$(journalctl -q _COMM=sudo --no-pager | grep -c COMMAND)"

# Output
echo "#Architecture: $ARCH"
echo "#CPU physical: $PHYS_CPU"
echo "#vCPU: $VCPU"
echo "#Memory Usage: $MEM_PCT"
echo "#Disk Usage: $DISK"
echo "#CPU load: $CPU_LOAD"
echo "#Last boot: $LAST_BOOT"
echo "#LVM use: $LVM_checker"
echo "#Connections TCP: $TCP_CONN ESTABLISHED"
echo "#User log: $USER_COUNT"
echo "#Network: $IP_MAC"
echo "#Sudo: $SUDO_COUNT cmd"
