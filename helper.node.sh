#!/usr/bin/env bash

set -e
set -x

usage() { 
  echo "
Usage: $0 [-v <list of ocp version, seperated by ','>] [-m <ocp major version for operator hub, like '4.6'>] [-f file <use this if want to use file director instead of docker resitry>]
Example: $0 -v 4.6.15,4.6.16
  " 1>&2
  exit 1 
}

var_download_registry='registry'

while getopts ":v:m:h:f:" o; do
    case "${o}" in
        v)
            build_number=${OPTARG}
            ;;
        m)
            var_major_version=${OPTARG}
            ;;
        h)
            var_date=${OPTARG}
            ;;
        f)
            var_download_registry='file'
            ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

if [ -z "${build_number}" ] ; then
    usage
fi

echo "build_number = ${build_number}"
echo "var_major_version = ${var_major_version}"

build_number_list=($(echo $build_number | tr "," "\n"))

# build_number_list=$(cat << EOF
# 4.6.12
# EOF
# )

# params for operator hub images
# export var_date='2021.01.18.1338'
# echo $var_date
# export var_major_version='4.6'
# echo ${var_major_version}

mkdir -p /data/file.registry/
# /bin/rm -rf /data/file.registry/*

/bin/rm -rf /data/ocp4/tmp/
mkdir -p /data/ocp4/tmp/
cd /data/ocp4/tmp/
export http_proxy="http://127.0.0.1:18801"
export https_proxy=${http_proxy}
git clone https://github.com/wangzheng422/openshift4-shell
unset http_proxy
unset https_proxy

cd /data/ocp4/tmp/openshift4-shell
git checkout ocp-${var_major_version}
# git pull origin ocp-${var_major_version}
/bin/cp -rf /data/ocp4/tmp/openshift4-shell/* /data/ocp4/

cd /data/ocp4/

mkdir -p /data/ocp4
/bin/rm -f /data/finished
cd /data/ocp4

install_build() {
    BUILDNUMBER=$1
    echo ${BUILDNUMBER}

    rm -rf /data/ocp-${BUILDNUMBER}
    mkdir -p /data/ocp-${BUILDNUMBER}
    cd /data/ocp-${BUILDNUMBER}

    wget -O release.txt https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/release.txt

    wget -O openshift-client-linux-${BUILDNUMBER}.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/openshift-client-linux-${BUILDNUMBER}.tar.gz
    wget -O openshift-install-linux-${BUILDNUMBER}.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/openshift-install-linux-${BUILDNUMBER}.tar.gz
    wget -O opm-linux-${BUILDNUMBER}.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/opm-linux-${BUILDNUMBER}.tar.gz
    wget -O oc-mirror.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/oc-mirror.tar.gz

    tar -xzf openshift-client-linux-${BUILDNUMBER}.tar.gz -C /usr/local/bin/
    tar -xzf openshift-install-linux-${BUILDNUMBER}.tar.gz -C /usr/local/bin/
    tar -xzf oc-mirror.tar.gz -C /usr/local/bin/
    chmod +x /usr/local/bin/oc-mirror

    export OCP_RELEASE=${BUILDNUMBER}
    export LOCAL_REG='registry.redhat.ren:5443'
    export LOCAL_REPO='ocp4/openshift4'
    export LOCAL_RELEASE='ocp4/release'
    export UPSTREAM_REPO='openshift-release-dev'
    export LOCAL_SECRET_JSON="/data/pull-secret.json"
    export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
    export RELEASE_NAME="ocp-release"

    # oc adm release mirror -a ${LOCAL_SECRET_JSON} \
    #   --from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-x86_64 \
    #   --to-release-image=${LOCAL_REG}/${LOCAL_RELEASE}:${OCP_RELEASE}-x86_64 \
    #   --to=${LOCAL_REG}/${LOCAL_REPO}

    if [[ $var_download_registry == 'registry' ]]; then
      oc adm release mirror -a ${LOCAL_SECRET_JSON} \
        --from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-x86_64 \
        --to=${LOCAL_REG}/${LOCAL_REPO}
    fi

    if [[ $var_download_registry == 'file' ]]; then
      oc adm release mirror -a ${LOCAL_SECRET_JSON} \
        --from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-x86_64 \
        --to-dir=/data/file.registry/
    fi

    export RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${BUILDNUMBER}/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}')

    oc adm release extract --registry-config ${LOCAL_SECRET_JSON} --command='openshift-baremetal-install' ${RELEASE_IMAGE}

    wget -O rhcos-live.x86_64.iso  https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/${BUILDNUMBER%.*}/latest/rhcos-live.x86_64.iso

}

for i in "${build_number_list[@]}"
do
    install_build $i
done
# while read -r line; do
#     install_build $line
# done <<< "$build_number_list"

cd /data/ocp4

# wget --recursive --no-directories --no-parent -e robots=off --accept="rhcos-live*,rhcos-metal.x86_64.raw.gz,rhcos-installer-kernel-*,rhcos-qemu.x86_64.qcow2.gz,rhcos-openstack.x86_64.qcow2.gz"  https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/${var_major_version}/latest/

# wget -O ocp-deps-sha256sum.txt https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/${var_major_version}/latest/sha256sum.txt

# podman pull docker.io/sonatype/nexus3:3.33.1
# podman save docker.io/sonatype/nexus3:3.33.1 | pigz -c > nexus.3.33.1.tgz

# podman pull quay.io/wangzheng422/qimgs:nexus-fs-image-2022-01-14-2155
# podman save quay.io/wangzheng422/qimgs:nexus-fs-image-2022-01-14-2155 | pigz -c > nexus-fs-image.tgz

install /data/ocp4/clients/butane-amd64 /usr/local/bin/butane

/bin/rm -f index.html*
/bin/rm -rf operator-catalog-manifests
/bin/rm -f sha256sum.txt*
/bin/rm -f clients/sha256sum.txt*
/bin/rm -rf /data/ocp4/tmp
/bin/rm -rf operator-catalog-manifests
/bin/rm -f index.db index.db.tar

cd /data
