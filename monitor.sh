#!/usr/bin/env bash

# Linux System Monitor
# Ahmed Saied

start_time=$(date +%s.%N)
source "$(dirname "$0")/functions.sh"
source "$(dirname "$0")/config.conf"

case "$1" in
--all)
	system_information
	cpu_monitor
	memory_monitor
	disk_monitor
	network_information
	generate_report
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
	generate_report
	;;
*)
	echo "Usage:"
	echo "./monitor.sh --all"
	echo "./monitor.sh --cpu"
	echo "./monitor.sh --memory"
	echo "./monitor.sh --disk"
	echo "./monitor.sh --network"
	echo "./monitor.sh --report"
	;;
esac

end_time=$(date +%s.%N)
execution_time=$(echo "$end_time - $start_time" | bc)

echo
echo "======================================"
printf "Execution Time : %.3f seconds\n" "$execution_time"
echo "======================================"
