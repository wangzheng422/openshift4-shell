#!/usr/bin/env bash

set -e
set -x

parm_local_reg=$1
parm_file=$2



cat pull.image.ok.list ${parm_file} mapping-*.txt | sed 's/\/.*$//g' | egrep "^.*\.(io|com|org|net)$"  | sort | uniq > mirror.domain.list
# cat pull.image.ok.list ${parm_file} mapping-*.txt | sed 's/\/.*$//g' | sort | uniq > mirror.domain.list

cat << EOF > ./image.registries.conf
EOF

yaml_docker_image(){

    docker_image=$1
    local_reg=$2

cat << EOF >> ./image.registries.conf

[[registry]]
  location = "${docker_image}"
  insecure = false
  blocked = false
  mirror-by-digest-only = false
  prefix = "${docker_image}"

  [[registry.mirror]]
    location = "${local_reg}"
    insecure = true

EOF

}

# declare -i num=1

while read -r line; do


    docker_image=$line

    echo $docker_image

    local_reg=$parm_local_reg/cache_${line//./_}
    
    echo $local_reg

    yaml_docker_image $docker_image $local_reg


done < mirror.domain.list


cat << EOF >> ./image.registries.conf

[[registry]]
  location = "${parm_local_reg}"
  insecure = true
  blocked = false
  mirror-by-digest-only = false
  prefix = ""

EOF


config_source=$( cat ./image.registries.conf | python3 -c "import sys, base64; sys.stdout.buffer.write(base64.urlsafe_b64encode(bytes(''.join(sys.stdin.readlines()), 'utf-8') ) ) "  )

cat <<EOF > 99-worker-container-registries.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-container-registries
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
          # source: data:text/plain,
          source: data:text/plain;charset=utf-8;base64,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/custom-registries.conf
EOF

cat <<EOF > 99-master-container-registries.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-container-registries
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
          # source: data:text/plain,
          source: data:text/plain;charset=utf-8;base64,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/custom-registries.conf
EOF