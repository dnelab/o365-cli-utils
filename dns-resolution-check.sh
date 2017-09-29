#!/bin/bash

show_requirements() {
  echo 'nslookup is missing.
Please install it with `brew install nslookup`
  ' >&2
}

show_help() {
  echo "Determine if an <fqdn> is resolvable. 
  
Usage:

    $0 [-v] [-h] [<fqdns...>] <fqdn>

  Options:
  
    -v
      Verbose output.

    -h
      Show this help.

Examples:
    
    $0 www.fqdn.tld
    $0 www.fqdn.tld www.fqdn2.tld
      
" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
fqdns=""
verbose=0

while getopts "h?vp:" opt; do
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

fqdns="$*"
nslookup="$(which nslookup)"

[[ $fqdns == "" ]] && show_help && exit 1
[[ $nslookup == "" ]] && show_requirements && exit 1

function isResolvable() {
  an_fqdn=$1

  $nslookup $an_fqdn | grep -q NXDOMAIN
  return $?
}


for fqdn in $fqdns; do
  isResolvable $fqdn 
  resolvable=$?
  [[ $resolvable == 1 ]] && status="OK" || status="KO"
  echo "$fqdn = $status" 
done;