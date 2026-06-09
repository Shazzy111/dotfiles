#!/bin/bash
# healthcheck.sh — System health report

set -euo pipefail

# Colours
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RESET='\033[0m'

# Helper: print coloured status
status() {
    local label="$1" value="$2" threshold="$3"
    if (( $(echo "$value > $threshold" | bc -l) )); then
        echo -e "  ${RED}✗ $label: ${value}% (threshold: ${threshold}%)${RESET}"
    else
        echo -e "  ${GREEN}✓ $label: ${value}%${RESET}"
    fi
}

echo "=============================="
echo " System Health Report"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================="

# CPU usage (1-second average)
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
status "CPU Usage" "$CPU" "80"

# Memory usage
MEM_TOTAL=$(free | awk '/Mem:/ {print $2}')
MEM_USED=$(free | awk '/Mem:/ {print $3}')
MEM_PCT=$(echo "scale=1; $MEM_USED * 100 / $MEM_TOTAL" | bc)
status "Memory Usage" "$MEM_PCT" "85"

# Disk usage on root
DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
status "Disk Usage (/)" "$DISK" "80"

# Top 3 CPU processes
echo ""
echo "  Top processes by CPU:"
ps aux --sort=-%cpu | awk 'NR>1 && NR<=4 {printf "    %-20s %s%%\n", $11, $3}'

echo "=============================="

echo "=============================="
echo "NGINX STATUS REPORT"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================="

#NGINX STATUS
echo ""

if systemctl is-active --quiet nginx; then
    echo -e " ${GREEN}✓ Nginx is running${RESET}"
else 
    echo -e " ${RED}✗ Nginx is NOT running - attempting restart${RESET}"
fi

#Report Generator
access_log_report() {
    echo ""
    echo "Access Log Summary"

    echo "  Total requests: $(wc -l < ~/workspace/logs/access.log)"
    echo "  200 responses: $(grep '" 200 ' ~/workspace/logs/access.log | wc -l)"
    echo "  Error responses: $(grep '" [45]' ~/workspace/logs/access.log | wc -l)"

    echo ""
    echo "  Top IPs:"

    awk '{print $1}' ~/workspace/logs/access.log \
        | sort \
        | uniq -c \
        | sort -rn \
        | head -3
}
access_log_report