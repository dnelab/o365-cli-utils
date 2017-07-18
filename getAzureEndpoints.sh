#!/bin/bash

date=$(date +"%Y%m")$[$(date +"%d") -1]
xmlAzurEndpoints="https://download.microsoft.com/download/0/1/8/018E208D-54F8-44CD-AA26-CD7BC9524A8C/PublicIPs_${date}.xml"

show_requirements() {
  echo 'wget is missing.
Please install it with `brew install wget`
  ' >&2
}

show_help() {
  echo "Show Azure endpoints description in unix parsable format.
Load source data from here : $xmlAzurEndpoints

Sample output (zone ip_range):

  europewest 23.100.86.91/32
  europewest 23.101.14.229/32
  europewest 23.101.30.126/32
  europewest 23.102.4.253/32
  
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

xml_cache="/tmp/oAzureendpoints-`date "+%Y%m%d"`.txt"

if [[ -f $xml_cache ]] 
then
	cat $xml_cache
	exit 0	
fi
	
### retrieve XML source
xml=$($wget --timeout 3 -t1 -q -O- $xmlAzurEndpoints)
wget_error=$?
[[ $wget_error != 0 ]] && echo "Error while retrieving endpoints (wget err_code=$wget_error)" && exit 1

### parse XML
product=""
address=""
OLD_IFS=$IFS
IFS="<" ### loop XML line by line
for line in $(echo "$xml" | grep -v -e 'addresslist' -e '::'); do 
  
#echo "### $line"
  
  if [[ "$line" == Region\ Name* ]]
  then
    region="$(echo $line | cut -d'"' -f2 | cut -f1 -d' ')"
  else 
      if [[ "$line" == IpRange\ Subnet* ]]
      then
	address="$(echo $line | cut -d'"' -f2 | cut -f1 -d' ')"
        echo "$region $address"
	echo "$region $address" >> $xml_cache
      fi
  fi
done
IFS=$OLD_IFS

exit 0
