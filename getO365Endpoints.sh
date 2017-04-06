#!/bin/bash

xmlO365Endpoints="https://support.content.office.net/en-us/static/O365IPAddresses.xml"

show_requirements() {
  echo 'wget is missing.
Please install it with `brew install wget`
  ' >&2
}

show_help() {
  echo "Show O365 endpoints description in unix parsable format.
Load source data from here : $xmlO365Endpoints

Sample output (product ip_range):

  o365 23.100.86.91/32
  o365 23.101.14.229/32
  o365 23.101.30.126/32
  o365 23.102.4.253/32
  o365 40.71.88.196/32
  o365 40.76.1.176/32
  o365 40.76.8.142/32
  
Usage:

    $0 [-h] [-v]

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

wget="$(which wget)"


[[ $wget == "" ]] && show_requirements && exit 1

### retrieve XML source
xml=$($wget -t1 -q -O- $xmlO365Endpoints)
wget_error=$?
[[ $wget_error != 0 ]] && echo "Error while retrieving endpoints (wget err_code=$wget_error)" && exit 1

### parse XML
product=""
address=""
OLD_IFS=$IFS
IFS="<" ### loop XML line by line
for line in $(echo "$xml" | grep -v -e 'addresslist' -e '::'); do 
  
#echo "### $line"
  
  if [[ "$line" == product\ name* ]]
  then
    product="$(echo $line | cut -d'"' -f2 | cut -f1 -d' ')"
  else 
      if [[ "$line" == address\>* ]]
      then
        address="$(echo $line | cut -d\> -f 2)"
        echo "$product $address"
      fi
  fi
done
IFS=$OLD_IFS

exit 0