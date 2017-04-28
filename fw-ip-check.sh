#!/bin/bash

show_requirements() {
  echo 'ipcalc is missing.
Please install it with `brew install ipcalc`
  ' >&2
}

show_help() {
  echo "Determine if an <ip>:<port> is directly reachable.
If a network range is given it test the first IP of the range  
  
Usage:

    $0 [-v] [-h] [-p <port>] <ip>

  Options:
  
    -p
      Port to test (optionnal, default to 443)

    -v
      Verbose output.

    -h
      Show this help.

Examples:
    
    $0 192.168.0.1
    $0 -p 22 192.168.0.1/24
    $0 192.168.0.1 192.168.0.2

      
" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
ip=""
port=443
verbose=0

while getopts "h?vp:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
     v)  verbose=1
         ;;
     p)  port="$OPTARG"
         ;;
     esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#######################################

ips="$*"
ipcalc="$(which ipcalc)"
nc="$(which nc)"


[[ $ips == "" ]] && show_help && exit 1
[[ $ipcalc == "" ]] && show_requirements && exit 1


function firstIp() {
  set $(echo "$1" | tr '/' ' ' )
  net=$1;shift
  mask=$1;shift
  [[ $mask == "" ]] && mask=32 ## default mask to 32 if not found
  
  pattern="HostMin"
  [[ $mask == 32 ]] && pattern="Hostroute"

  match=$($ipcalc -nb $net $mask | grep "^$pattern" | cut -d' '  -f2- | tr -d ' ')
  echo "$match"
  return 0
}

function isOpen() {
  an_ip=$1
  a_port=$2

  $nc -w1 -G1 $an_ip $a_port < /dev/null
  return $?
}


for ip in $ips; do
  first_ip_found=$(firstIp $ip)
  isOpen $first_ip_found $port 
  close=$?
  [[ $close == 1 ]] && status="close" || status="open"
  echo "$an_ip:$a_port = $status" 

done;
