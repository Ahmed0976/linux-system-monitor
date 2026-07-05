#!/usr/bin/env bash


# Colors


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'


# Logging


log_action() {
    local action="$1"

    echo "$(date '+%Y-%m-%d %H:%M:%S') | $(whoami) | $action" >> "$LOGS_DIR/monitor.log"
}


# Header


print_header() {
    local title="$1"

    echo
    echo -e "${CYAN}======================================${NC}"
    printf "${BLUE}%-38s${NC}\n" "$title"
    echo -e "${CYAN}======================================${NC}"
}


# System Information


system_information() {

    log_action "System Information"

    local hostname
    local username
    local current_date
    local uptime_info
    local os
    local kernel
    local cpu
    local memory

    hostname=$(hostname)
    username=$(whoami)
    current_date=$(date)
    uptime_info=$(uptime -p)
    os=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    kernel=$(uname -r)
    cpu=$(lscpu | awk -F: '/Model name/ {print $2}' | xargs)
    memory=$(free -h | awk '/^Mem:/ {print $2}')

    print_header "System Information"

    printf "%-18s %s\n" "Hostname:" "$hostname"
    printf "%-18s %s\n" "User:" "$username"
    printf "%-18s %s\n" "Date:" "$current_date"
    printf "%-18s %s\n" "Uptime:" "$uptime_info"
    printf "%-18s %s\n" "OS:" "$os"
    printf "%-18s %s\n" "Kernel:" "$kernel"
    printf "%-18s %s\n" "CPU:" "$cpu"
    printf "%-18s %s\n" "Total Memory:" "$memory"
}


# CPU Monitor


cpu_monitor() {

    local model
    local architecture
    local cores
    local usage
    local status

    model=$(lscpu | awk -F: '/Model name/ {print $2}' | xargs)
    architecture=$(uname -m)
    cores=$(nproc)

    usage=$(top -bn1 | awk -F',' '/Cpu/ {
        gsub("%id","",$4)
        printf "%.1f",100-$4
    }')

    if (($(echo "$usage >= $CPU_THRESHOLD" | bc -l))); then
        status="WARNING"
    else
        status="NORMAL"
    fi

    print_header "CPU Monitor"

    printf "%-18s %s\n" "Model:" "$model"
    printf "%-18s %s\n" "Architecture:" "$architecture"
    printf "%-18s %s\n" "CPU Cores:" "$cores"
    printf "%-18s %.1f%%\n" "CPU Usage:" "$usage"

    if [[ "$status" == "WARNING" ]]; then
        printf "%-18s ${YELLOW}%s${NC}\n" "Status:" "$status"
    else
        printf "%-18s ${GREEN}%s${NC}\n" "Status:" "$status"
    fi

    log_action "CPU $status (${usage}%)"
}


# Memory Monitor


memory_monitor() {

    local total
    local used
    local free
    local percent
    local status

    read total used free percent <<< "$(free -h | awk '/^Mem:/ {
        printf "%s %s %s %.0f",$2,$3,$4,($3/$2)*100
    }')"

    if (( percent >= MEMORY_THRESHOLD )); then
        status="WARNING"
    else
        status="NORMAL"
    fi

    print_header "Memory Monitor"

    printf "%-18s %s\n" "Total Memory:" "$total"
    printf "%-18s %s\n" "Used Memory:" "$used"
    printf "%-18s %s\n" "Free Memory:" "$free"
    printf "%-18s %s%%\n" "Usage:" "$percent"

    if [[ "$status" == "WARNING" ]]; then
        printf "%-18s ${YELLOW}%s${NC}\n" "Status:" "$status"
    else
        printf "%-18s ${GREEN}%s${NC}\n" "Status:" "$status"
    fi

    log_action "Memory $status (${percent}%)"
}


# Disk Monitor

disk_monitor() {

    local total
    local used
    local available
    local percent
    local status

    read total used available percent <<< "$(df -h / | awk 'NR==2{
        gsub("%","",$5)
        print $2,$3,$4,$5
    }')"

    if (( percent >= DISK_THRESHOLD )); then
        status="WARNING"
    else
        status="NORMAL"
    fi

    print_header "Disk Monitor"

    printf "%-18s %s\n" "Total Disk:" "$total"
    printf "%-18s %s\n" "Used Disk:" "$used"
    printf "%-18s %s\n" "Available:" "$available"
    printf "%-18s %s%%\n" "Current Usage:" "$percent"
    printf "%-18s %s%%\n" "Threshold:" "$DISK_THRESHOLD"

    if [[ "$status" == "WARNING" ]]; then
        echo -e "${YELLOW}Status:${NC} WARNING"
        echo -e "${YELLOW}Disk usage is above threshold!${NC}"
    else
        echo -e "${GREEN}Status:${NC} NORMAL"
        echo -e "${GREEN}Disk usage is normal.${NC}"
    fi

    log_action "Disk $status (${percent}%)"
}

# Network Information

network_information() {

    local ip
    local gateway
    local internet

    ip=$(hostname -I | awk '{print $1}')
    gateway=$(ip route | awk '/default/ {print $3}')

    if ping -c 1 -W 1 "$PING_HOST" >/dev/null 2>&1; then
        internet="Connected"
    else
        internet="Disconnected"
    fi

    print_header "Network Information"

    printf "%-18s %s\n" "Hostname:" "$(hostname)"
    printf "%-18s %s\n" "IP Address:" "$ip"
    printf "%-18s %s\n" "Gateway:" "$gateway"
    printf "%-18s %s\n" "Internet:" "$internet"

    log_action "Network $internet"
}



# Generate Report

generate_report() {

    local report_file

    report_file="$REPORTS_DIR/report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "======================================"
        echo "        Linux System Report"
        echo "======================================"
        echo

        printf "%-15s %s\n" "Date:" "$(date)"
        printf "%-15s %s\n" "Hostname:" "$(hostname)"
        printf "%-15s %s\n" "User:" "$(whoami)"
        echo

        local cpu_model cpu_usage cpu_status

        cpu_model=$(lscpu | awk -F: '/Model name/ {print $2}' | xargs)

        cpu_usage=$(top -bn1 | awk -F',' '/Cpu/{
            gsub("%id","",$4)
            printf "%.1f",100-$4
        }')

        if (($(echo "$cpu_usage >= $CPU_THRESHOLD" | bc -l))); then
            cpu_status="WARNING"
        else
            cpu_status="NORMAL"
        fi

        echo "--------------- CPU -----------------"
        printf "%-15s %s\n" "Model:" "$cpu_model"
        printf "%-15s %.1f%%\n" "Usage:" "$cpu_usage"
        printf "%-15s %s\n" "Status:" "$cpu_status"
        echo

        local mem_total mem_used mem_free mem_usage mem_status

        read mem_total mem_used mem_free mem_usage <<< "$(free -h | awk '/^Mem:/{
            printf "%s %s %s %.0f",$2,$3,$4,($3/$2)*100
        }')"

        if (( mem_usage >= MEMORY_THRESHOLD )); then
            mem_status="WARNING"
        else
            mem_status="NORMAL"
        fi

        echo "------------- Memory ----------------"
        printf "%-15s %s\n" "Total:" "$mem_total"
        printf "%-15s %s\n" "Used:" "$mem_used"
        printf "%-15s %s\n" "Free:" "$mem_free"
        printf "%-15s %s%%\n" "Usage:" "$mem_usage"
        printf "%-15s %s\n" "Status:" "$mem_status"
        echo
		 local disk_total disk_used disk_avail disk_usage disk_status

        read disk_total disk_used disk_avail disk_usage <<< "$(df -h / | awk 'NR==2{
            gsub("%","",$5)
            print $2,$3,$4,$5
        }')"

        if (( disk_usage >= DISK_THRESHOLD )); then
            disk_status="WARNING"
        else
            disk_status="NORMAL"
        fi

        echo "-------------- Disk -----------------"
        printf "%-15s %s\n" "Total:" "$disk_total"
        printf "%-15s %s\n" "Used:" "$disk_used"
        printf "%-15s %s\n" "Available:" "$disk_avail"
        printf "%-15s %s%%\n" "Usage:" "$disk_usage"
        printf "%-15s %s\n" "Status:" "$disk_status"
        echo

        local ip gateway internet

        ip=$(hostname -I | awk '{print $1}')
        gateway=$(ip route | awk '/default/ {print $3}')

        if ping -c 1 -W 1 "$PING_HOST" >/dev/null 2>&1; then
            internet="Connected"
        else
            internet="Disconnected"
        fi

        echo "------------ Network ----------------"
        printf "%-15s %s\n" "IP:" "$ip"
        printf "%-15s %s\n" "Gateway:" "$gateway"
        printf "%-15s %s\n" "Internet:" "$internet"
        echo

        echo "======================================"
        printf "Execution Time : %.3f seconds\n" "$EXECUTION_TIME"
        echo "Generated by Linux System Monitor"
        echo "======================================"

    } > "$report_file"

    echo
    echo -e "${GREEN}Report generated successfully.${NC}"
    echo "Location : $report_file"

    log_action "Report generated ($report_file)"
}


