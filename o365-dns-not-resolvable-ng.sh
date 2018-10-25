#!/bin/bash

show_requirements() {
  echo "$1 is missing." >&2
}

show_help() {
  echo "List domains zone and traversal zone not actually resolvable

Sample output :

domain1.tld
domain2.tld
  
Usage:

    $0 [-h] [-v] -c <optimize,allow,default> <product>

  Options:
    -c
      Category (optimize, default, allow) -- comma separated

    -w
      Wildcards replacements (corp, contoso) -- comma separated

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
verbose=0
categories=""
wildcards=""

while getopts "h?vc:w:" opt; do
    case "$opt" in
    c)
        categories="$OPTARG"
        ;;
    w)
        wildcards="$OPTARG"
        ;;
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

o365endpoints="$(which getO365Endpoints-ng.sh)"
dnsCheck="$(which dns-resolution-check.sh)"
webDnsCheck="$(which web-google-dns-resolve.sh)"

[[ $o365endpoints == "" ]] && show_requirements "getO365Endpoints-ng.sh" && exit 1
[[ $dnsCheck == "" ]] && show_requirements "dns-resolution-check.sh" && exit 1
[[ $webDnsCheck == "" ]] && show_requirements "web-google-dns-resolve.sh" && exit 1

[[ $categories == "" ]] && show_help && exit 1

components="$*"

[[ $components == "" ]] && show_help && exit 1


all_domains=""

for component in $components; do
  
  domains=$($o365endpoints -c $categories | grep -i $component | grep -v '/' | cut -d" " -f2 | sort | uniq )

  [[ $verbose == 1 ]] && echo "$component $domains"

  for domain in $domains; do

    resolvable=$($dnsCheck "$domain" | grep "OK")
    if [[ $? == 1 ]]; then
      all_domains+=" $domain"
    fi    
  done
done

#### traversal zone resolution with domains not resolvable
###

all_uniq=`echo $all_domains | sort | uniq`

all_w_uniq=""
wildcards=$(echo ${wildcards/,/ })
for domain in $all_uniq; do

  all_w_uniq+=" $($webDnsCheck -v $domain 2>&1)"

  for w in $wildcards; do

    wdomain=" $(echo ${domain/\*/$w})"
    all_w_uniq+=" $($webDnsCheck -v $wdomain 2>&1)"

  done
done

all=$(echo $all_w_uniq | tr -s " " "\n" | cut -d ":" -f1)
all+=" $(echo $all_w_uniq | tr -s " " "\n" | cut -d ":" -f2)"

echo $all | tr -s " " "\n" | sort | uniq | grep "\.$"

  

exit 0
