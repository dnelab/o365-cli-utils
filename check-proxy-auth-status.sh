#!/bin/bash

show_help() {
  echo "Determine if an URL is accessible through a given proxy without providing authentification credentials.
  
Usage:

    $0 [-v] [-h] [-p http://proxy] <fqdn>

  Options:

    -p proxy
      Proxy full FQDN to use

    -v
      Verbose output.

    -h
      Show this help.

Examples:

    $0 -p http://proxy.acme.com:8080 http://www.google.fr
    $0 -p http://proxy.acme.com:8080 http://www.google.fr https://www.yahoo.fr

" >&2
}

## arguments parsing #########

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
ip=""
verbose=0
proxy=""

while getopts "h?vp:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  verbose=1
        ;;
    p)  proxy="$OPTARG"
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#######################################

fqdns="$*"

[[ $proxy == "" ]] && show_help && exit 1

for fqdn in $fqdns; do

  http_code=`curl --proxy "$proxy" -o /dev/null --silent --head --write-out '%{http_code}\n' "$fqdn"`
  ok="OK"
  [[ $http_code == 407 ]] && ok="KO";
  echo "$fqdn : $http_code - $ok"
  
#  if [[ $http_code == 407 ]]; then
 # fi
done
