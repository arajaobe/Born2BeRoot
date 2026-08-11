#!/bin/bash
# monitoring.sh - system snapshot and broadcast
# /usr/local/bin/monitoring.sh:

ARCH="$(uname -a)"
PHYS_CPU="$(lscpu | awk -F: '/Socket\\(s\\)/{print $2}' | xargs || echo unknown)"
VCPU="$(nproc || echo unknown)"
MEM_TOTAL_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo || echo 0)
MEM_AVAIL_KB=$(awk '/MemAvailable/ {print $2}' /proc/meminfo || echo 0)
MEM_USED_KB=$(( MEM_TOTAL_KB - MEM_AVAIL_KB ))
MEM_PCT=$(awk "BEGIN{ if($MEM_TOTAL_KB>0) printf \"%.2f\", ($MEM_USED_KB/$MEM_TOTAL_KB)*100; else print \"0.00\" }")
DISK_INFO=$(df -h / | awk 'NR==2 {print $3\"/\"$2\" (\"$5\")\"}' || echo unknown)
CPU_LOAD=$(top -bn1 | awk '/Cpu\\(s\\)/{print $2+$4\"%\"}' || echo unknown)
LAST_BOOT=$(who -b | awk '{print $3\" \"$4}' || echo unknown)
LVM_USE=$(lsblk -o TYPE | grep -q lvm && echo yes || echo no)
TCP_CONN=$(ss -tun state established | tail -n +2 | wc -l || echo 0)
USERS_LOG=$(who | wc -l || echo 0)
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}' || echo unknown)
MAC_ADDR=$(ip link show 2>/dev/null | awk '/ether/ {print $2; exit}' || echo unknown)
SUDO_COUNT=$(journalctl _COMM=sudo --no-pager 2>/dev/null | grep -c COMMAND || echo 0)

cat <<EOF | wall -n
#Architecture: $ARCH
#Physical CPU: $PHYS_CPU
#vCPU: $VCPU
#Memory Usage: ${MEM_USED_KB}/${MEM_TOTAL_KB} kB (${MEM_PCT}%)
#Disk Usage: $DISK_INFO
#CPU load: $CPU_LOAD
#Last boot : $LAST_BOOT
#LVM use: $LVM_USE
#TCP Connections: $TCP_CONN ESTABLISHED
#User log: $USERS_LOG
#Network: IP $IP_ADDR ($MAC_ADDR)
#Sudo: $SUDO_COUNT cmd
EOF
