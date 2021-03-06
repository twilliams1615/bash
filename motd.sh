#!/bin/bash

# Used to set a standard MOTD. Can be used on most Linux Distros

########################################################################
# Color esthetics
########################################################################
C0='\033[1;37m' # White
C1='\033[0;35m' # Purple
C3='\033[0;37m' # Light Gray
C4='\033[1;32m' # Light Green

########################################################################
# Commands configuration
########################################################################

# Get the current user's name
USER=$(whoami)
NAME=$(grep "$USER" /etc/passwd |awk -F ":" '{print $5}' |sed -e "s/[^ a-zA-Z']//g" -e 's/ \+/ /')
# Check all local interfaces
INTERFACE=$(route | grep '^default' | grep -o '[^ ]*$')

# Check if the system has a thermo sensor
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    # Get the tempurature from the probe
    cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    cpu_temp="$(echo "$cpu_temp / 1000" | bc -l | xargs printf "%1.0f")°C"

else
    # If no sensor then just print N/A
    cpu_temp="No temp sensor found"
fi

# Check and format the open ports on the machine
OPEN_PORTS_IPV4=$(netstat -lnt | awk 'NR>2{print $4}' | grep -E '0.0.0.0:' | sed 's/.*://' | sort -n | uniq | awk -vORS=, '{print $1}' | sed 's/,$/\n/')
OPEN_PORTS_IPV6=$(netstat -lnt | awk 'NR>2{print $4}' | grep -E ':::' | sed 's/.*://' | sort -n | uniq | awk -vORS=, '{print $1}' | sed 's/,$/\n/')

# Get the list of processes and sort them by most mem usage and most cpu usage
ps_output="$(ps aux)"
mem_top_processes="$(printf "%s\\n" "${ps_output}" | awk '{print "\033[1;37m"$2, $4"%", "\033[1;32m"$11}' | sort -k2rn | head -3 | awk '{print " \033[0;35m+\t\033[1;32mID: "$1, $3, $2}')"
cpu_top_processes="$(printf "%s\\n" "${ps_output}" | awk '{print "\033[1;37m"$2, $3"%", "\033[1;32m"$11}' | sort -k2rn | head -3 | awk '{print " \033[0;35m+\t\033[1;32mID: "$1, $3, $2}')"

# Get your remote IP address using external resource ipinfo.io
remote_ip="$(wget http://ipinfo.io/ip -qO -)"
# Get your local IP address
local_ip="$(ip addr list "$INTERFACE" | grep "inet " | cut -d' ' -f6| cut -d/ -f1)"
# Get the total machine uptime in specific dynamic format 0 days, 0 hours, 0 minutes
machine_uptime="$(uptime | sed -E 's/^[^,]*up *//; s/, *[[:digit:]]* user.*//; s/min/minutes/; s/([[:digit:]]+):0?([[:digit:]]+)/\1 hours, \2 minutes/')"
# Get your linux distro name
distro_pretty_name="$(grep "PRETTY_NAME" /etc/*release | cut -d "=" -f 2- | sed 's/"//g')"
# Get the brand and model of your CPU
cpu_model_name="$(grep "model name" /proc/cpuinfo | cut -d ' ' -f3- | awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}' | head -1)"

# Get memory usage to be displayed
memory_percent="$(free -m | awk '/Mem/ { if($2 ~ /^[1-9]+/) memm=$3/$2*100; else memm=0; printf("%3.1f%%", memm) }')"
memory_free_mb="$(free -t -m | grep "Mem" | awk '{print $4}')"
memory_used_mb="$(free -t -m | grep "Mem" | awk '{print $3}')"
memory_available_mb="$(free -t -m | grep "Mem" | awk '{print $2}')"

# Get SWAP usage to be displayed
swap_percent="$(free -m | awk '/Swap/ { if($2 ~ /^[1-9]+/) swapm=$3/$2*100; else swapm=0; printf("%3.1f%%", swapm) }')"
swap_free_mb="$(free -t -m | grep "Swap" | awk '{print $4}')"
swap_used_mb="$(free -t -m | grep "Swap" | awk '{print $3}')"
swap_available_mb="$(free -t -m | grep "Swap" | awk '{print $2}')"

# Get HDD usage to be displayed
hdd_percent="$(df -H | grep "/$" | awk '{ print $5 }')"
hdd_free="$(df -hT | grep "/$" | awk '{print $5}')"
hdd_used="$(df -hT | grep "/$" | awk '{print $4}')"
hdd_available="$(df -hT | grep "/$" | awk '{print $3}')"

#Get last login information
last_login_user="$(last -a "$USER" | head -2 | awk 'NR==2{print $3,$4,$5,$6}')"


# Get load averages
read -r loadavg_one loadavg_five loadavg_fifteen rest < /proc/loadavg

# Clear the screen and reset the scrollback
clear #&& printf '\e[3J'

# Print out all of the information collected using the script
echo -e "${C1} ++++++++++++++++++++++++: ${C3}System Data${C1} :+++++++++++++++++++++++++++
${C1} + ${C3}Hostname       ${C1}=  ${C4}$(hostname) ${C0}($(hostname --fqdn))
${C1} + ${C3}IPv4 Address   ${C1}=  ${C4}$remote_ip ${C0}($local_ip)
${C1} + ${C3}Uptime         ${C1}=  ${C4}$machine_uptime
${C1} + ${C3}Time           ${C1}=  ${C0}$(date)
${C1} + ${C3}CPU Temp       ${C1}=  ${C0}$cpu_temp
${C1} + ${C3}Load Averages  ${C1}=  ${C4}${loadavg_one}, ${loadavg_five}, ${loadavg_fifteen} ${C0}
${C1} + ${C3}Distro         ${C1}=  ${C4}$distro_pretty_name ${C0}($(uname -r))
${C1} + ${C3}CPU            ${C1}=  ${C4}$cpu_model_name
${C1} + ${C3}Memory         ${C1}=  ${C4}$memory_percent ${C0}(${memory_free_mb}MB Free, ${memory_used_mb}MB/${memory_available_mb}MB Used)
${C1} + ${C3}Swap           ${C1}=  ${C4}$swap_percent ${C0}(${swap_free_mb}MB Free, ${swap_used_mb}MB/${swap_available_mb}MB Used)
${C1} + ${C3}Main HDD Drive ${C1}=  ${C4}$hdd_percent ${C0}(${hdd_free}B Free, ${hdd_used}B/${hdd_available}B Used)
${C1} ++++++++++++++++++++: ${C3}Top CPU Processes${C1} :+++++++++++++++++++++++++
$cpu_top_processes${C0}
${C1} ++++++++++++++++++++: ${C3}Top Mem Processes${C1} :+++++++++++++++++++++++++
$mem_top_processes${C0}
${C1} ++++++++++++++++++++++++: ${C3}User Data${C1} :+++++++++++++++++++++++++++++
${C1} + ${C3}Username       ${C1}=  ${C4}$NAME ${C0}($USER)
${C1} + ${C3}Last Login     ${C1}=  ${C4}$last_login_user
${C1} + ${C3}Sessions       ${C1}=  ${C4}$(who | grep -c "$USER")
${C1} ++++++++++++++++++++: ${C3}Helpful Information${C1} :+++++++++++++++++++++++
${C1} + ${C3}OpenPorts IPv4 ${C1}=  ${C4}$OPEN_PORTS_IPV4
${C1} + ${C3}OpenPorts IPv6 ${C1}=  ${C4}$OPEN_PORTS_IPV6
${C1} ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"
