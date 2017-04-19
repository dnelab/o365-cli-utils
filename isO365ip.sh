#!/bin/bash

show_requirements() {
  echo 'ipcalc is missing.
Please install it with `brew install ipcalc`
  ' >&2
}

show_help() {
  echo "Determine if an <ip> is O365 related. If so it prints outs the range and the products associated with.
  
Usage:

    $0 [-v] [-h] <ip>

  Options:

    -v
      Verbose output.

    -h
      Show this help.
" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
ip=""
verbose=0

while getopts "h?v" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  verbose=1
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#######################################

ip="$1"
ipcalc="$(which ipcalc)"
o365endpoints="./getO365Endpoints.sh"


[[ $ip == "" ]] && show_help && exit 1
[[ $ipcalc == "" ]] && show_requirements && exit 1

ip_ranges=$($o365endpoints | grep '/' | grep -v 'http')
[[ $? != 0 ]] && echo "error while fetching o365 endpoints"  && exit 1

function isInSubnet() {
	ip=$1;shift
	set $(echo "$1" | tr '/' ' ' )
	net=$1;shift
	mask=$1;shift
	[[ $verbose == 1 ]] && echo "Searching $ip in $net/$mask"
  
  [[ $mask == 32 ]] && [[ $ip == $net ]] && return 1 
  
	match=$($ipcalc -nb $ip $mask | grep '^Network' | tr -s '/' ' ' | cut -d' '  -f 2)
	[ "$match" = "$net" ] && return 1 || return 0
}


OLD_IFS=$IFS
IFS=$'\n'
for product_iprange in $ip_ranges; do
  
  [[ $verbose == 1 ]] && echo "Searching against $product_iprange"
  
  iprange=$(echo $product_iprange | cut -f2 -d' ')

  IFS=$OLD_IFS
  isInSubnet "$ip" "$iprange"
  
  if [[ $? == 1 ]]; then
      product=$(echo $product_iprange | cut -f1 -d' ')
      echo "IP=$ip belongs to product $product (range=$iprange)"
  fi
  IFS=$'\n'  
done

IFS=$OLD_IFS

#isInSubnet '40.101.122.123' '40.96.0.0/13'
#isInSubnet '40.106.122.123' '40.96.0.0/13'
#isInSubnet $1 $2
