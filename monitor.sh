#!/usr/bin/env bash

# Linux System Monitor
# Ahmed Saied

source "$(dirname "$0")/functions.sh"
source "$(dirname "$0")/config.conf"

mkdir -p "$LOGS_DIR"
mkdir -p "$REPORTS_DIR"

START_TIME=$(date +%s.%N)

case "$1" in

    --all)
        system_information
        cpu_monitor
        memory_monitor
        disk_monitor
        network_information
        ;;

    --cpu)
        cpu_monitor
        ;;

    --memory)
        memory_monitor
        ;;

    --disk)
        disk_monitor
        ;;

    --network)
        network_information
        ;;

    --report)
        END_TIME=$(date +%s.%N)
        EXECUTION_TIME=$(awk "BEGIN {print $END_TIME - $START_TIME}")
        generate_report
        ;;

    *)
        echo "Usage:"
        echo "./monitor.sh --all"
        echo "./monitor.sh --cpu"
        echo "./monitor.sh --memory"
        echo "./monitor.sh --disk"
        echo "./monitor.sh --network"
        echo "./monitor.sh --check-disk"
        echo "./monitor.sh --report"
        exit 1
	;;
esac

if [[ "$1" != "--report" ]]; then
    END_TIME=$(date +%s.%N)
    EXECUTION_TIME=$(awk "BEGIN {print $END_TIME - $START_TIME}")
fi

END_TIME=$(date +%s.%N)

EXECUTION_TIME=$(awk "BEGIN {print $END_TIME - $START_TIME}")

printf "\n======================================\n"
printf "Execution Time : %.3f seconds\n" "$EXECUTION_TIME"
printf "======================================\n"
