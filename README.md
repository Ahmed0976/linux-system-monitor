# Linux System Monitor

A Bash-based Linux monitoring tool that provides real-time system information, resource usage, and report generation.

---

## Features

- System Information
- CPU Monitoring
- Memory Monitoring
- Disk Monitoring
- Network Information
- Threshold Configuration
- Disk Usage Check
- Report Generation
- Logging System
- Colored Terminal Output

---

## Technologies Used

- Bash Scripting
- Linux
- AWK
- grep
- sed
- df
- free
- top
- hostname
- ping

---

## Project Structure

```
linux-system-monitor/
│
├── monitor.sh
├── functions.sh
├── config.conf
├── README.md
├── LICENSE
├── logs/
│   └── monitor.log
└── reports/
```

---

## Configuration

Edit the configuration file:

```bash
nano config.conf
```

Example:

```bash
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80

LOGS_DIR="logs"
REPORTS_DIR="reports"

PING_HOST="8.8.8.8"
```

---

## Installation

Clone the repository

```bash
git clone https://github.com/Ahmed0976/linux-system-monitor.git
```

Go to the project

```bash
cd linux-system-monitor
```

Make executable

```bash
chmod +x monitor.sh
```

Run

```bash
./monitor.sh --all
```

---

## Usage

Show all information

```bash
./monitor.sh --all
```

CPU Monitoring

```bash
./monitor.sh --cpu
```

Memory Monitoring

```bash
./monitor.sh --memory
```

Disk Monitoring

```bash
./monitor.sh --disk
```

Network Information

```bash
./monitor.sh --network
```

Generate Report

```bash
./monitor.sh --report
```

---

## Generated Report

Reports are automatically stored inside:

```
reports/
```

Example

```
report_20260705_181200.txt
```

---

## Log File

Logs are stored in

```
logs/monitor.log
```

---

## Future Improvements

- Email Alerts
- Telegram Notifications
- JSON Report Export
- Multi-Disk Monitoring
- Process Monitoring
- Service Monitoring
- Docker Monitoring

---

## Author

Ahmed Saied Ahmed

Cybersecurity Student

Interested in Linux, DevOps and Cloud Computing

GitHub

https://github.com/Ahmed0976
