#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_action() {
	local action="$1"

	mkdir -p "$LOGS_DIR"

	echo "$(date '+%Y-%m-%d %H:%M:%S') | $(whoami) | $action" >>"$LOGS_DIR/monitor.log"
}

system_information() {
	log_action "System Information"
	echo "==============================="
	echo "          System Information "
	echo "==============================="

	echo "Hostname : $(hostname)"
	echo "User     : $(whoami)"
	echo "Date     : $(date)"
	echo "Uptime   : $(uptime -p)"
	echo "OS       : $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
	echo "Kernel   : $(uname -r)"
	echo "CPU      : $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
	echo "Total Memory  : $(free -h | awk '/Mem:/ {print $2}')"
	echo
	echo "=============================="
}

cpu_monitor() {
	local model
	local architecture
	local cores
	local usage

	model=$(lscpu | awk -F: '/Model name/ {print $2}' | xargs)
	architecture=$(uname -m)
	cores=$(nproc)

	usage=$(top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8}')

	echo
	echo -e "${CYAN}======================================${NC}"
	echo -e "${BLUE}           CPU Monitor${NC}"
	echo -e "${CYAN}======================================${NC}"

	echo "Model        : $model"
	echo "Architecture : $architecture"
	echo "CPU Cores    : $cores"
	printf "CPU Usage    : %.1f%%\n" "$usage"

	if (($(echo "$usage >= $CPU_THRESHOLD" | bc -l))); then
		echo -e "Status       : ${YELLOW}WARNING${NC}"
		log_action "CPU WARNING (${usage}%)"
	else
		echo -e "Status       : ${GREEN}NORMAL${NC}"
		log_action "CPU NORMAL (${usage}%)"
	fi

	echo "======================================"
}

memory_monitor() {
	local total
	local used
	local free
	local percent

	total=$(free -h | awk '/^Mem:/ {print $2}')
	used=$(free -h | awk '/^Mem:/ {print $3}')
	free=$(free -h | awk '/^Mem:/ {print $4}')

	percent=$(free | awk '/^Mem:/ {printf "%.0f", ($3/$2)*100}')

	echo
	echo -e "${CYAN}======================================${NC}"
	echo -e "${BLUE}           Memory Monitor${NC}"
	echo -e "${CYAN}======================================${NC}"

	echo "Total Memory : $total"
	echo "Used Memory  : $used"
	echo "Free Memory  : $free"
	echo "Usage        : ${percent}%"

	if ((percent >= MEMORY_THRESHOLD)); then
		echo -e "Status       : ${YELLOW}WARNING${NC}"
		log_action "Memory WARNING (${percent}%)"
	else
		echo -e "Status       : ${GREEN}NORMAL${NC}"
		log_action "Memory NORMAL (${percent}%)"
	fi

	echo "======================================"
}

disk_monitor() {
	local total
	local used
	local available
	local percent

	total=$(df -h / | awk 'NR==2 {print $2}')
	used=$(df -h / | awk 'NR==2 {print $3}')
	available=$(df -h / | awk 'NR==2 {print $4}')
	percent=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

	echo
	echo -e "${CYAN}======================================${NC}"
	echo -e "${BLUE}           Disk Monitor${NC}"
	echo -e "${CYAN}======================================${NC}"

	echo "Total Disk     : $total"
	echo "Used Disk      : $used"
	echo "Available Disk : $available"
	echo "Usage          : ${percent}%"

	if ((percent >= DISK_THRESHOLD)); then
		echo -e "Status       : ${YELLOW}WARNING${NC}"
		log_action "Disk WARNING (${percent}%)"
	else
		echo -e "Status       : ${GREEN}NORMAL${NC}"
		log_action "Disk NORMAL (${percent}%)"
	fi

	echo "======================================"
}

network_information() {
	local ip
	local gateway

	ip=$(hostname -I | awk '{print $1}')
	gateway=$(ip route | awk '/default/ {print $3}')

	echo
	echo "=============================="
	echo "     Network Information"
	echo "=============================="

	echo "Hostname : $(hostname)"
	echo "IP Address : $ip"
	echo "Gateway : $gateway"

	if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
		echo "Internet : Connected"
		log_action "Internet Connected"
	else
		echo "Internet : Disconnected"
		log_action "Internet Disconnected"
	fi

	echo "=============================="
}

show_thresholds() {
	log_action "Thresholds Information"
	echo
	echo "=============================="
	echo "      Threshold Settings"
	echo "=============================="

	echo "CPU Threshold    : $CPU_THRESHOLD%"
	echo "Memory Threshold : $MEMORY_THRESHOLD%"
	echo "Disk Threshold   : $DISK_THRESHOLD%"

	echo "=============================="
}

check_disk_usage() {
	log_action "Disk usage Information"
	local usage

	usage=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

	echo
	echo "=============================="
	echo "      Disk Usage Check"
	echo "=============================="

	echo "Current Disk Usage : ${usage}%"
	echo "Threshold          : ${DISK_THRESHOLD}%"

	if ((usage >= DISK_THRESHOLD)); then
		echo "WARNING: Disk usage is above threshold!"
		log_action "WARNING: Disk usage ${usage}%"
	else
		echo "Disk usage is normal."
		log_action "Disk usage normal ${usage}%"
	fi

	echo "=============================="
}

generate_report() {

	local report_file
	report_file="$REPORTS_DIR/report_$(date +%Y%m%d_%H%M%S).txt"

	mkdir -p "$REPORTS_DIR"

	{
		echo "======================================"
		echo "      Linux System Report"
		echo "======================================"
		echo

		echo "Date      : $(date)"
		echo "Hostname  : $(hostname)"
		echo "User      : $(whoami)"
		echo

		echo "--------------- CPU -----------------"

		local cpu_model cpu_usage cpu_status

		cpu_model=$(lscpu | awk -F: '/Model name/ {print $2}' | xargs)
		cpu_usage=$(top -bn1 | awk -F',' '/Cpu/ {gsub("%id","",$4); print int(100-$4)}')

		if ((cpu_usage >= CPU_THRESHOLD)); then
			cpu_status="WARNING"
		else
			cpu_status="NORMAL"
		fi

		echo "Model     : $cpu_model"
		echo "Usage     : ${cpu_usage}%"
		echo "Status    : $cpu_status"
		echo

		echo "------------- Memory ----------------"

		local mem_total mem_used mem_free mem_usage mem_status

		read mem_total mem_used mem_free mem_usage <<<"$(free -h | awk '/^Mem:/ {
            printf "%s %s %s %.0f", $2, $3, $4, ($3/$2)*100
        }')"

		if ((mem_usage >= MEMORY_THRESHOLD)); then
			mem_status="WARNING"
		else
			mem_status="NORMAL"
		fi

		echo "Total     : $mem_total"
		echo "Used      : $mem_used"
		echo "Free      : $mem_free"
		echo "Usage     : ${mem_usage}%"
		echo "Status    : $mem_status"
		echo

		echo "-------------- Disk -----------------"

		local disk_total disk_used disk_avail disk_usage disk_status

		read disk_total disk_used disk_avail disk_usage <<<"$(df -h / | awk 'NR==2{
            gsub("%","",$5)
            print $2,$3,$4,$5
        }')"

		if ((disk_usage >= DISK_THRESHOLD)); then
			disk_status="WARNING"
		else
			disk_status="NORMAL"
		fi

		echo "Total     : $disk_total"
		echo "Used      : $disk_used"
		echo "Available : $disk_avail"
		echo "Usage     : ${disk_usage}%"
		echo "Status    : $disk_status"
		echo

		echo "------------ Network ----------------"

		local ip gateway internet

		ip=$(hostname -I | awk '{print $1}')
		gateway=$(ip route | awk '/default/ {print $3}')

		if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
			internet="Connected"
		else
			internet="Disconnected"
		fi

		echo "IP        : $ip"
		echo "Gateway   : $gateway"
		echo "Internet  : $internet"
		echo

		echo "======================================"
		printf "Execution Time : %.3f seconds\n" "$EXECUTION_TIME"
		echo "Generated by Linux System Monitor"
		echo "======================================"

	} >"$report_file"

	echo
	echo "Report generated successfully."
	echo "Location: $report_file"

	log_action "Report generated: $report_file"
}
