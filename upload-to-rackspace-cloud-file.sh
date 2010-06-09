#!/bin/bash
# Author: Chmouel Boudjnah <chmouel@chmouel.com>
# Not officially supported by Rackspace only as a best effort basis :)

# Define yes to make it to copy to url to clipboard (via a shortened url
# service) You need to have the software xclip installed in your system.
COPY_URL_TO_CLIPBOARD=yes

# Containers to ignore in the list
CONTAINERS_TO_IGNORE=".CDN_ACCESS_LOGS"

function get_api_key {
    RCLOUD_API_USER=$(zenity --title "Enter Username" --entry \
        --text "Rackspace Cloud Username:" --width 200 --height 50)
    [[ -z $RCLOUD_API_USER ]] && exit 1 #press cancel
    RCLOUD_API_KEY=$(zenity --title "Enter Username" --entry \
        --text "Rackspace Cloud API Key:" --width 200 --height 50)
    [[ -n ${RCLOUD_API_KEY} && -n ${RCLOUD_API_USER} ]] || {
        zenity --title "Missing Username/API Key" --error --text \
            "You have not specified a Rackspace Cloud username or API key" \
            --width 200 --height 25;
        exit 1;
    }
    check_api_key
    mkdir -p ${HOME}/.config/rackspace-cloud
    echo "RCLOUD_API_USER=${RCLOUD_API_USER}" > ${HOME}/.config/rackspace-cloud/config
    echo "RCLOUD_API_KEY=${RCLOUD_API_KEY}" >> ${HOME}/.config/rackspace-cloud/config
}

function check_api_key {
    temp_file=$(mktemp /tmp/.rackspace-cloud.XXXXXX)
    local good_key=
    curl -s -f -D - \
      -H "X-Auth-Key: ${RCLOUD_API_KEY}" \
      -H "X-Auth-User: ${RCLOUD_API_USER}" \
      https://auth.api.rackspacecloud.com/v1.0 >${temp_file} && good_key=1

    if [[ -z $good_key ]];then
        zenity --title "Bad Username/API Key" --error --text \
            "Cannot identify with your Rackspace Cloud username or API key" \
            --width 200 --height 25;
        exit 1;
    fi

    while read line;do
        [[ $line != X-* ]] && continue
        line=${line#X-}
        key=${line%: *};key=${key//-/}
        value=${line#*: }
        value=$(echo ${value}|sed 's/\r$//')
        eval "export $key=$value"
    done < ${temp_file}

    rm -f ${temp_file}
}

function create_container {
    local container=$1

    if [[ -z $container ]];then
        zenity --title "Need a container name" --error --text \
            "You need to specify a container name" \
            --width 200 --height 25;
        exit 1;
    fi

    created=
    curl -f -k -X PUT -D - \
      -H "X-Auth-Token: ${AuthToken}" \
      ${StorageUrl}/${container} && created=1

    if [[ -z $created ]];then
        zenity --title "Cannot create container" --error --text \
            "Cannot create container name ${container}" \
            --width 200 --height 25;
        exit 1;
    fi
}

function put_object {
    local container=$1
    local file=$(readlink -f $2)
    local dest_name=$3
    if [[ -n $3 ]];then
        object=$3
    else
        object=${file}
    fi
    object=$(basename ${object})
    #url encode in sed yeah i am not insane i have googled that
    object=$(echo $object|sed -e 's/%/%25/g;s/ /%20/g;s/ /%09/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/\*/%2a/g;s/+/%2b/g; s/,/%2c/g; s/-/%2d/g; s/\./%2e/g; s/:/%3a/g; s/;/%3b/g; s//%3e/g; s/?/%3f/g; s/@/%40/g; s/\[/%5b/g; s/\\/%5c/g; s/\]/%5d/g; s/\^/%5e/g; s/_/%5f/g; s/`/%60/g; s/{/%7b/g; s/|/%7c/g; s/}/%7d/g; s/~/%7e/g; s/      /%09/g;')
    
    if [[ ! -e ${file} ]];then
        zenity --title "Cannot find file" --error --text \
            "Cannot find file ${file}" \
            --width 200 --height 25;
        exit 1
    fi

    local etag=$(md5sum ${file});etag=${etag%% *} #TODO progress
    local ctype=$(file -bi ${file});ctype=${ctype%%;*}
    if [[ -z ${ctype} || ${ctype} == *corrupt* ]];then
        ctype="application/octet-stream"
    fi
    
    uploaded=

    curl -o/dev/null -f -X PUT -T ${file} \
        -H "ETag: ${etag}" \
        -H "Content-type: ${ctype}" \
        -H "X-Auth-Token: ${StorageToken}" \
        ${StorageUrl}/${container}/${object} 2>&1|zenity --text "Uploading ${object}"  --title "Uploading" \
        --width 500 --height 50 \
        --progress --pulsate --auto-kill --auto-close

    if [[ $COPY_URL_TO_CLIPBOARD == "yes" || $COPY_URL_TO_CLIPBOARD == "YES" || $COPY_URL_TO_CLIPBOARD == "Yes" ]];then
        if [[ -x /usr/bin/xclip ]];then
            PUBLIC_URL=$(container_public ${container})
            if [[ -n $PUBLIC_URL ]];then
                short_url=$(curl -s "http://ggl-shortener.appspot.com/?url=${PUBLIC_URL}/$object" | sed 's/.*http/http/;s/"}//')
                echo $short_url|xclip -selection clipboard
            fi
        fi
    fi
    echo $short_url
}

function container_public {
    local cont=$@
    curl -s -f -k -I -H "X-Auth-Token: ${AuthToken}" $CDNManagementUrl/$cont|grep "X-CDN-URI"|sed -e 's/\r$//;s/X-CDN-URI: //'
}

function choose_container {
    local lastcontainer args 

    if [[ -e ${HOME}/.config/rackspace-cloud/last-container ]];then
        lastcontainer=$(cat ${HOME}/.config/rackspace-cloud/last-container)
    fi

    if [[ -n ${choose_default} ]];then
        echo ${lastcontainer}
        return
    fi  
    
    CONTAINERS_LIST=$(curl -s -f -k -X GET \
      -H "X-Auth-Token: ${AuthToken}" \
      ${StorageUrl}|sort -n
    )
    
    for cont in ${CONTAINERS_LIST};do
        v=FALSE
        skip=
        for ignore_cont in $CONTAINERS_TO_IGNORE;do
            if [[ $ignore_cont == $cont ]];then
                skip="1"
            fi
        done
        [[ -n ${skip} ]] && continue

        if [[ $cont == ${lastcontainer} ]];then
            v=TRUE
        fi
        args="$args ${v} ${cont}"
    done
    
    container=$(zenity  --height=500 --list --title "Which Container"  --text "Which Container you want to upload?" --radiolist  \
        --column "Pick" --column "Container" $args
    )
    
    [[ -z ${container} ]] && return
    
    mkdir -p ${HOME}/.config/rackspace-cloud
    echo ${container} > ${HOME}/.config/rackspace-cloud/last-container
    echo $container
}

set -e
[[  -e ${HOME}/.config/rackspace-cloud/config ]] && \
    source ${HOME}/.config/rackspace-cloud/config
[[ -n ${RCLOUD_API_KEY} && -n ${RCLOUD_API_USER} ]] && check_api_key || get_api_key

if [[ $1 == "-d" ]];then
    choose_default=true
    shift 
fi

container=$(choose_container)
if [[ -z ${container} ]];then
    exit
fi
if [[ -n ${choose_default} ]];then
    echo "Upload to container $container."
fi

ARGS=$@
IFS=""
for arg in $ARGS;do
    tarname=
    file=$(readlink -f ${arg})
    dest_name=
    
    [[ -e ${file} ]] || continue
    [[ -f ${file} || -d ${file} ]] || continue
    
    if [[ -d ${file} ]];then
        if [[ -w ./ ]];then
            tardir="."
        else
            tardir=/tmp
        fi
        tarname=${tardir}/${arg}-cf-tarball.tar.gz #in case if already exist we don't destruct it
        dest_name=${arg}.tar.gz
        tar cvzf $tarname ${arg}|zenity --text "Making tarball of ${file}"  --title "Compressing" \
        --width 500 --height 50 \
        --progress --pulsate --auto-kill --auto-close
        file=${tarname}
    fi

    put_object ${container} ${file} ${dest_name}
    [[ -n ${tarname} ]] && rm -f ${tarname}
done
