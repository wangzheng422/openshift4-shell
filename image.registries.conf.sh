#!/usr/bin/env bash

set -e
set -x

parm_local_reg=$1
parm_file=$2

#export LOCAL_REG='registry.redhat.ren:5443'
# export MID_REG="registry.redhat.ren"

# export OCP_RELEASE=${BUILDNUMBER}
# export LOCAL_REG='registry.redhat.ren'
# export LOCAL_REPO='ocp4/openshift4'
# export UPSTREAM_REPO='openshift-release-dev'
# export LOCAL_SECRET_JSON="pull-secret.json"
# export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
# export RELEASE_NAME="ocp-release"

# /bin/rm -rf ./operator/yaml/
# mkdir -p ./operator/yaml/

cat pull.image.ok.list ${parm_file} mapping-*.txt | sed 's/\/.*$//g' | egrep "^.*\.(io|com|org|net)$"  | sort | uniq > mirror.domain.list
# cat pull.image.ok.list ${parm_file} mapping-*.txt | sed 's/\/.*$//g' | sort | uniq > mirror.domain.list

cat << EOF > ./image.registries.conf
EOF

yaml_docker_image(){

    docker_image=$1
    # local_image=$(echo $2 | sed "s/${MID_REG}/${LOCAL_REG}/")
    num=$2
    # echo $docker_image

cat << EOF >> ./image.registries.conf

[[registry]]
  location = "${docker_image}"
  insecure = false
  blocked = false
  mirror-by-digest-only = false
  prefix = "${docker_image}"

  [[registry.mirror]]
    location = "${parm_local_reg}"
    insecure = true

EOF

}

declare -i num=1

while read -r line; do

    # docker_image=$(echo $line | awk  '{split($0,a,"\t"); print a[1]}')
    # local_image=$(echo $line | awk  '{split($0,a,"\t"); print a[2]}')

    docker_image=$line

    echo $docker_image
    # echo $local_image

    # yaml_docker_image $docker_image $local_image $num
    yaml_docker_image $docker_image $num
    num=${num}+1;

done < mirror.domain.list


cat << EOF >> ./image.registries.conf

[[registry]]
  location = "${parm_local_reg}"
  insecure = true
  blocked = false
  mirror-by-digest-only = false
  prefix = ""

EOF

# config_source=$(cat ./image.registries.conf | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(''.join(sys.stdin.readlines())))"  )
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