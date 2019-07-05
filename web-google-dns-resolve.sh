#!/bin/bash

show_requirements() {
  echo 'wget or jq is missing.
Please install it with `brew install jq`
Please install it with `brew install wget`
  ' >&2
}

show_help() {
  echo "Resolve a <fqdn> via dns google web. 
  
Usage:

    $0 [-v] [-h] [<fqdns...>] <fqdn>

  Options:
  
    -v
      Verbose output (add traversal zones).

    -h
      Show this help.

Examples:
    
    $0 www.fqdn.tld
    $0 www.fqdn.tld www.fqdn2.tld

    $ $0 www.google.fr
    www.google.fr.:216.58.209.227
      
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
wget="$(which wget)"
jq="$(which jq)"


[[ $fqdns == "" ]] && show_help && exit 1
[[ $jq == "" ]] && show_requirements && exit 1
[[ $wget == "" ]] && show_requirements && exit 1


for fqdn in $fqdns; do
  
  if [[ $verbose == 1 ]]; then
    ## traversal zones
    $wget --no-check-certificate -qO- https://dns.google.com/resolve\?name\=$fqdn | jq -r '. as $all | .Answer[]? |  $all.Question[].name+":"+ .data'
  else
    ## only IP
    $wget --no-check-certificate -qO- https://dns.google.com/resolve\?name\=$fqdn | jq -r '. as $all | .Answer[]? |  select(.type==1) | $all.Question[].name+":"+ .data'
  fi
done;
