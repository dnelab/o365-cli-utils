#!/usr/local/bin/bash
. ./throbber.sh
show_requirements() {
  echo 'ipcalc is missing or bash v4 is missing.
Please install it with `brew install ipcalc or brew install bash`
  ' >&2
}

show_help() {
  echo "Determine if an <ip> is azure related. If so it prints outs the range and the region name associated with.
  
Usage:

    $0 [-v] [-h] <ip>

  Options:

    -v
      Verbose output.

    -h
      Show this help.

Examples:

    $0 192.168.0.1 52.174.144.192
    $0 52.174.144.192

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

ips="$*"
ipcalc="$(which ipcalc)"
Azureendpoints="./getAzureEndpoints.sh"

bash_major_version=${BASH_VERSION:0:1}

[[ $ips == "" ]] && show_help && exit 1
[[ $ipcalc == "" ]] && show_requirements && exit 1
[[ $bash_major_version != 4 ]] && show_requirements && exit 1

ip_ranges=$($Azureendpoints | grep '/' | grep -v 'http')
[[ $? != 0 ]] && echo "error while fetching Azure endpoints"  && exit 1

declare -A isInSubnet_ret

function isInSubnet() {
	ip=$1;shift
	set $(echo "$1" | tr '/' ' ' )
	net=$1;shift
	mask=$1;shift
	[[ $verbose == 1 ]] && echo "Searching $ip in $net/$mask"
  
  [[ $mask == 32 ]] && [[ $ip == $net ]] && return 1 
  
	[[ $verbose == 1 ]] && echo "Searching $ip in $net/$mask"
  
	match=$($ipcalc -nb $ip $mask | grep '^Network' | tr -s '/' ' ' | cut -d' '  -f 2)
  [ "$match" = "$net" ] && return 1
  return 0
}

for ip in $ips; do

  OLD_IFS=$IFS
  IFS=$'\n'
  for region_iprange in $ip_ranges; do
  
    [[ $verbose == 1 ]] && echo "Searching against $region_iprange"
  
    iprange=$(echo $region_iprange | cut -f2 -d' ')

    IFS=$OLD_IFS
  
    ## check for cache
    if test "${isInSubnet_ret[$ip$iprange]+isset}"; then
      [[ $verbose == 1 ]] && echo "cache hit ($ip$iprange = ${isInSubnet_ret[$ip$iprange]})"
      ret=${isInSubnet_ret[$ip$iprange]}
    else
      isInSubnet "$ip" "$iprange"
      ret=$?
      isInSubnet_ret[$ip$iprange]=$ret
    fi
  
    if [[ $ret == 1 ]]; then
	spinresult
        region=$(echo $region_iprange | cut -f1 -d' ')
        echo "IP=$ip belongs to product $region (range=$iprange)"
    else 
	spin
    fi
    IFS=$'\n'  
  done
  endspin

  IFS=$OLD_IFS

done

#isInSubnet '40.101.122.123' '40.96.0.0/13'
#isInSubnet '40.106.122.123' '40.96.0.0/13'
#isInSubnet $1 $2
