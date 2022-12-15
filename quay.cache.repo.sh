#!/usr/bin/env bash

set -e
set -x

parm_action=$1
parm_local_reg=$2
parm_token=$3
parm_file=$4



cat pull.image.ok.list ${parm_file} mapping-*.txt | sed 's/\/.*$//g' | egrep "^.*\.(io|com|org|net)$"  | sort | uniq > mirror.domain.list
# cat pull.image.ok.list ${parm_file} mapping-*.txt | sed 's/\/.*$//g' | sort | uniq > mirror.domain.list

while read -r line; do

    docker_image=$line

    echo $docker_image

    local_reg=$parm_local_reg/cache_${line//./_}
    
    echo $local_reg

    # yaml_docker_image $docker_image

    if [ $parm_action == "create" ]; then
      curl -X 'POST' \
        "https://$parm_local_reg/api/v1/organization/" \
        -H "Authorization: Bearer $parm_token" \
        -H 'Content-Type: application/json' \
        -d "{ \"name\":\"cache_${line//./_}\"}" | jq

      curl -X 'POST' \
        "https://$parm_local_reg/api/v1/organization/cache_${line//./_}/proxycache" \
        -H "Authorization: Bearer $parm_token" \
        -H 'Content-Type: application/json' \
        -d "{
            \"org_name\": \"cache_${line//./_}\",
            \"upstream_registry\": \"$docker_image\"
          }" | jq

    elif [ $parm_action == "delete" ]; then
      curl -X 'DELETE' \
        "https://$parm_local_reg/api/v1/organization/cache_${line//./_}" \
        -H "Authorization: Bearer $parm_token" \
        -H 'accept: application/json' | jq

    fi


done < mirror.domain.list

