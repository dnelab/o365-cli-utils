#!/usr/local/bin/bash
## ^^ v4 ...

restO365Endpoints="https://endpoints.office.com/endpoints/o365worldwide?clientrequestid=09a38806-ef8b-454a-be25-7e01f129b4a2&TenantName=lfdj"

debug() {
  [[ $verbose == 1 ]] && echo $1
}

show_requirements() {
  echo "$1 is missing."
  echo 'Please install it with `brew install '.$1.'`' >&2
}

show_help() {
  echo "Show O365 endpoints description in unix parsable format.
Load source data from here : $restO365Endpoints

Doc is here : https://support.office.com/en-us/article/Managing-Office-365-endpoints-99cab9d4-ef59-4207-9f2b-3728eb46bf9a#ID0EACAAA=4._Web_service
Category are here : https://blogs.technet.microsoft.com/onthewire/2018/04/06/new-office-365-url-categories-to-help-you-optimize-the-traffic-which-really-matters/

- Optimize for a small number of endpoints that require low latency unimpeded connectivity which should bypass proxy servers, network SSL break and inspect devices, and network hairpins.
- Allow for a larger number of endpoints that benefit from low latency unimpeded connectivity. Although not expected to cause failures, we also recommend bypassing proxy servers, network SSL break and inspect devices, and network hairpins. Good connectivity to these endpoints is required for Office 365 to operate normally.
- Default for other Office 365 endpoints which can be directed to the default internet egress location for the company WAN.
 

Sample output (product ip_range ports_range category):

  o365 23.100.86.91/32 80 optimize
  o365 23.101.14.229/32 80,443 allow
  o365 23.101.30.126/32 100-200 default
  o365 23.101.30.126/32 100-200/UDP default

Todo:

 - arg : type (ip/dns)
 - implement caching

Usage:

    $0 [-h] [-v] -c <categories>

  Options:

    -c
      Category (optimize, default, allow) -- comma separated

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

while getopts "h?vc:" opt; do
    case "$opt" in
    c)  
        categories="$OPTARG"
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

wget="$(which wget)"
jq="$(which jq)"

[[ $wget == "" ]] && show_requirements 'wget' && exit 1
[[ $jq == "" ]] && show_requirements 'jq' && exit 1
[[ $categories == "" ]] && show_help && exit 1

json_cache="/tmp/o365endpoints-ng-`date "+%Y%m%d"`.txt"


#if [[ -f $json_cache ]] 
#then
#	cat $json_cache
#	exit 0	
#fi


### retrieve REST source
json=$($wget --timeout 3 -t1 -q -O- $restO365Endpoints)
wget_error=$?
[[ $wget_error != 0 ]] && echo "Error while retrieving endpoints (wget err_code=$wget_error)" && exit 1

## dev only : cache fetch result
echo $json > $json_cache


### parse REST

# expr to list services
expr_services="unique_by(.serviceArea)|.[].serviceArea"
services=`echo $json | jq -r "$expr_services"`

categories=`echo $categories | tr -s "," " "` 
for category in $categories; do 


  # expr to list keys word specific to a category level
  expr_json_cat_keys="[.[] | keys | .[]] | unique | map(select(. | startswith(\"$category\"))) | join(\" \")"
  # "optimizeTcpPorts",
  # "optimizeUdpPorts",
  # "optimizeUrls"

  category_keys=`echo $json | jq -r "$expr_json_cat_keys"`

  ## build select categories filter
  expr_json_cat_select_filter=""
  expr_json_cat_bash_out=""
  for category_key in $category_keys; do
    expr_json_cat_select_filter+=" select(.$category_key) ,"
  done;

  # remove last comma
  expr_json_cat_select_filter=${expr_json_cat_select_filter%?}

  for service in $services; do

    ### la on a pour un service(ex Skype) les regles de la categorie(optimize)
    service_ressources=`echo $json | jq -r "[.[] | $expr_json_cat_select_filter | select(.serviceArea==\"$service\") ] | unique"`

      # split as bash arrays
      nb_ressources=`echo $service_ressources | jq -r length`
      # for each bash array, retrieve key
      while [ $nb_ressources -gt 0 ] ; do
        ((nb_ressources--))

        ressource=`echo $service_ressources | jq -r .[$nb_ressources]`

        debug "-------------------"
        debug $ressource

        # check if ips rules or domains rules
        has_ip=`echo $ressource | jq -r "has(\"ips\")"`   

        debug "has_ip"

        # maps json to shell variable
        if $has_ip; then
          ## add ips and filter out IPv6
          expr_json_cat_net='[.ips | .[] | select(test("::")==false)]'
        else 
        # $nets = `echo $service_ressources | jq -r "[ $expr_json_cat_ips ]" `
          url_key=$category"Urls"
          expr_json_cat_net="select(.$url_key)|.$url_key"

        fi;

        ## collect net endpoints
        nets=`echo $ressource | jq -r "$expr_json_cat_net" `
        nets=`echo $nets | tr -d "\n"`

        debug "nets"


        ## collect port endpoints
        tport_key=$category"TcpPorts"
        uport_key=$category"UdpPorts"

        ### TODO !!! transform udp ports
        ports=`echo $ressource | jq -r "[ .$tport_key? , (.$uport_key+\"/udp\"| select(test(\"^/udp$\")==false)) | strings ]"`
        ports=`echo $ports | tr -d "\n"`



        debug "ports : [ .$tport_key? , .$uport_key+\"/udp\"| select(test(\"^/udp$\")==false) | strings ]"

        ## summup in online
        echo "[[\"$service\"], $nets, $ports , [\"$category\"]]" | jq -r 'combinations | join(" ")'
        
        debug "combinations"


    ###   echo "$product $address" >> $xml_cache

      done;

  done;

done;

exit 0