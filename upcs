#!/bin/bash
# Author: Chmouel Boudjnah <chmouel.boudjnah@rackspace.co.uk>
# Not officially supported by Rackspace only as a best effort basis :)

# Define yes to make it to copy to url to clipboard (via a shortened url
# service) You need to have the software xclip installed in your system.
COPY_URL_TO_CLIPBOARD=yes

# Containers to ignore in the list
CONTAINERS_TO_IGNORE=".CDN_ACCESS_LOGS"

# Default GUI Type
GUI_TYPE="text"

# Auth Server (change it if you have a custom swift install)
AUTH_SERVER_LON=https://lon.auth.api.rackspacecloud.com/v1.0
AUTH_SERVER_US=https://auth.api.rackspacecloud.com/v1.0
DEFAULT_AUTH_SERVER=${AUTH_SERVER_US}

# Specify here something different than by default google
# Choice are :
# isgd  for http://is.gd
# google for http://goo.gl (default)
SHORT_URL_SERVICE="google"

# Set it to true if you want to use servicenet to upload.
SERVICENET=false

if [[ -z ${DISPLAY}} ]];then
    GUI_TYPE="text"
elif [[ ${DISPLAY} == "localhost:10" ]];then
    GUI_TYPE="text"
elif ! which zentiy >/dev/null;then
    GUI_TYPE="text"
fi

if [[ $GUI_TYPE == "gui" ]];then
    function ask_question {
        question=$1
        title=$2
        width=$3
        height=$4
        zenity --title "$title" --entry \
            --text "$question: " --width $width --height $height
    }
    function msg() {
        msg=$1
        title=$2
        width=$3
        height=$4             

        zenity --title "$title" --error --text \
            "$msg" \
            --width ${width} --height ${height};
    }

else
    function ask_question {
        question=$1
        read -p "$question: "
        echo $REPLY
    }

    function msg {
        echo $1
    }
fi


function get_api_key {
    RCLOUD_API_USER=$(ask_question "Rackspace Cloud Username" "Enter Username"  200 50)
    [[ -z $RCLOUD_API_USER ]] && exit 1 #press cancel
    RCLOUD_API_KEY=$(ask_question "Rackspace Cloud API Key" "Enter API Key"  200 50)

    LOCATION=$(ask_question "Location US/UK (default: US)" "Enter Location" 200 50)
    
    if [[ $LOCATION == "uk" || $LOCATION == "UK" ]];then
        AUTH_SERVER=$AUTH_SERVER_LON
    else 
        AUTH_SERVER=$AUTH_SERVER_US
    fi

    [[ -n ${RCLOUD_API_KEY} && -n ${RCLOUD_API_USER} ]] || {
        msg "You have not specified a Rackspace Cloud username or API key" "Missing Username/API Key" 200 25
        exit 1;
    }
    check_api_key
    mkdir -p ${HOME}/.config/rackspace-cloud
    echo "RCLOUD_API_USER=${RCLOUD_API_USER}" > ${HOME}/.config/rackspace-cloud/config
    echo "RCLOUD_API_KEY=${RCLOUD_API_KEY}" >> ${HOME}/.config/rackspace-cloud/config
    echo "AUTH_SERVER=${AUTH_SERVER}" >> ${HOME}/.config/rackspace-cloud/config
}

function check_api_key {
    temp_file=$(mktemp /tmp/.rackspace-cloud.XXXXXX)
    local good_key=
    [[ -z ${AUTH_SERVER} ]] && AUTH_SERVER=${DEFAULT_AUTH_SERVER}

    curl -s -f -D - \
        -H "X-Auth-Key: ${RCLOUD_API_KEY}" \
        -H "X-Auth-User: ${RCLOUD_API_USER}" \
        ${AUTH_SERVER} >${temp_file} && good_key=1

    if [[ -z $good_key ]];then
        msg "You have a bad username or api/key." "Bad Username/API Key" 200 25
        exit 1;
    fi

    while read line;do
        [[ $line != X-* ]] && continue
        line=${line#X-}
        key=${line%: *};key=${key//-/}
        value=${line#*: }
        value=$(echo ${value}|tr -d '\r')
        eval "export $key=$value"
    done < ${temp_file}

    if [[ -z ${StorageUrl} ]];then
        echo "Invalid auth url."
        exit 1
    fi

    
    if [[ ${SERVICENET} == true || ${SERVICENET} == True || ${SERVICENET} == TRUE ]];then
        StorageUrl=${StorageUrl/https:\/\//https://snet-}
        StorageUrl=${StorageUrl/http:\/\//http://snet-}
    fi

    rm -f ${temp_file}
}

function create_container {
    local container=$1

    if [[ -z $container ]];then
        msg "You need to specify a container name" "Need a container name" 200 25
        exit 1;
    fi

    created=
    curl -f -k -X PUT -D - \
        -H "X-Auth-Token: ${AuthToken}" \
        ${StorageUrl}/${container} && created=1

    if [[ -z $created ]];then
        msg "Cannot create container name ${container}" "Cannot create container" 200 25
        exit 1;
    fi
}

function shorten_url() {
    url=$1

    if [[ ${SHORT_URL_SERVICE} == isgd  ]];then
        _surl=$(curl -s "http://is.gd/api.php?longurl=${url}")
    else
        api_key="AIzaSyDmzsxlzULxBpJJmg5wEUuPQY9g_afwcuk"
        _surl=$(curl -s \
            "https://www.googleapis.com/urlshortener/v1/url?key=${api_key}" \
            -H 'Content-Type: application/json' \
            -d "{\"longUrl\": \"${url}\"}" | sed -n '/id/ { s/.*: .//;s/".*//;p;q;}'
            )
    fi

    if [[ -n ${_surl} ]];then
        echo ${_surl}|tr -d '\r'|tr -d '\n'
    fi
}

function put_object {
    local container=$1
    local file=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $2)
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
        msg "Cannot find file ${file}" "Cannot find file" 200 25
        exit 1
    fi
    
    #MaxOSX
    if [[ -e /sbin/md5 ]];then
        local etag=$(md5 ${file});etag=${etag##* }
        local ctype=$(file -bI ${file});ctype=${ctype%%;*}
    else
        local etag=$(md5sum ${file});etag=${etag%% *} #TODO progress
        local ctype=$(file -bi ${file});ctype=${ctype%%;*}
    fi
    if [[ -z ${ctype} || ${ctype} == *corrupt* ]];then
        ctype="application/octet-stream"
    fi
    
    uploaded=

    if [[ ${GUI_TYPE} != "gui" ]];then
        echo "Uploading ${file}"
        curl -o/dev/null -f -X PUT -T ${file} -H "ETag: ${etag}" -H "Content-type: ${ctype}" -H "X-Auth-Token: ${StorageToken}" ${StorageUrl}/${container}/${object}
        echo
    else
        curl -o /dev/null -f -X PUT -T ${file} -H "ETag: ${etag}" -H "Content-type: ${ctype}" -H "X-Auth-Token: ${StorageToken}" ${StorageUrl}/${container}/${object} 2>&1|zenity --text "Uploading ${object}"  --title "Uploading" \
            --width 500 --height 50 \
            --progress --pulsate --auto-kill --auto-close
    fi

    PUBLIC_URL=$(container_public ${container})
    if [[ -n $PUBLIC_URL ]];then
        short_url=$(shorten_url "${PUBLIC_URL}/$object")
        echo "$short_url | $file"
        [[ -x /usr/bin/xclip ]] && echo $short_url|xclip -selection clipboard
        [[ -x /usr/bin/pbcopy ]] && echo $short_url|pbcopy
    fi
}

function container_public {
    local cont=$@
    curl -s -f -k -I -H "X-Auth-Token: ${AuthToken}" $CDNManagementUrl/$cont|grep "X-CDN-URI"|sed -e 's/\r$//;s/X-CDN-URI: //'|tr -d '\r'
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

        if [[ $GUI_TYPE == "gui" ]];then
            args="$args ${v} ${cont}"
        else
            args="$args ${cont}"
        fi
    done


    if [[ $GUI_TYPE == gui ]];then
        container=$(zenity  --height=500 --list --title "Which Container"  --text "Which Container you want to upload?" --radiolist  \
            --column "Pick" --column "Container" $args
        )
    else
        PS3="Select Container: "
        select container in $args;do
            break
        done
    fi

    [[ -z ${container} ]] && return
    
    mkdir -p ${HOME}/.config/rackspace-cloud
    echo ${container} > ${HOME}/.config/rackspace-cloud/last-container
    echo $container
}

function help() {
cat<<EOF
upload-to-rackspace-cloud-file.sh OPTIONS FILES1 FILE2...

Use curl on the backup to upload files to rackspace Cloud Files.

Options are :

-s - Use Servicenet to upload.
-u=Username - specify an alternate username than the one stored in config
-k=Api_Key - specify an alternate apikey.
-a=Auth_URL - specify an alternate auth server.
-c=Container - specify the container to upload.
-d - Use the last chosen container to upload.

Config is inside ~/.config/rackspace-cloud/config.

EOF
}

set -e
[[  -e ${HOME}/.config/rackspace-cloud/config ]] && \
    source ${HOME}/.config/rackspace-cloud/config

choose_default=
while getopts ":c:dsu:k:a:" opt; do
  case $opt in
    s)
    SERVICENET=true
    ;;
    u)
    RCLOUD_API_USER=$OPTARG
    ;;
    k)
    RCLOUD_API_KEY=$OPTARG
    ;;
    a)
    AUTH_SERVER=$OPTARG
    ;;
    c)
    container=$OPTARG
    ;;
    d)
    choose_default=True
    ;;
    h)
    help
    exit 0
    ;;
    \?)
    echo "Invalid option: -$OPTARG" >&2
    help
    exit 1
    ;;
  esac
done
shift $((OPTIND-1))

ARGS=$@
if [[ -z ${ARGS} ]];then
    msg "No files specified." "No files specified." 200 50
    exit 1
fi

[[ -n ${RCLOUD_API_KEY} && -n ${RCLOUD_API_USER} ]] && check_api_key || get_api_key

[[ -z ${container} ]] && container=$(choose_container)
[[ -z ${container} ]] && exit 1
[[ -n ${choose_default} ]] &&   echo "Uploading to container: $container."

for arg in $ARGS;do
    tarname=
    file=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' ${arg})
    dest_name=
    
    [[ -e ${file} ]] || {
        echo "$file does not seem to exist."
        continue
    }
    [[ -f ${file} || -d ${file} ]] || {
        echo "$file does not seem a file or directory."
        continue
    }
    if [[ -d ${file} ]];then
        if [[ -w ./ ]];then
            tardir="."
        else
            tardir=/tmp
        fi
        tarname=${tardir}/${arg}-cf-tarball.tar.gz #in case if already exist we don't destruct it
        dest_name=${arg}.tar.gz

        if [[ $GUI_TYPE == "gui" ]];then
            tar cvzf $tarname ${arg}|zenity --text "Making tarball of ${file}"  --title "Compressing" \
                --width 500 --height 50 \
                --progress --pulsate --auto-kill --auto-close
        else
            tar cvzf $tarname ${arg}
        fi
        file=${tarname}
    fi

    put_object ${container} ${file} ${dest_name}
    [[ -n ${tarname} ]] && rm -f ${tarname}
done
