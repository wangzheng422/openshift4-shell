#!/usr/bin/env bash

set -e
set -x

usage() { 
  echo "
Usage: $0 [-v <list of ocp version, seperated by ','>] [-m <ocp major version for operator hub, like '4.6'>] [-h <operator hub version, like '2021.01.18.1338'> ] [-f file <use this if want to use file director instead of docker resitry>]
Example: $0 -v 4.6.15,4.6.16, -m 4.6 -h 2021.01.18.1338 -f file
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

if [ -z "${build_number}" ] || [ -z "${var_major_version}" ] || [ -z "${var_date}" ]; then
    usage
fi

echo "build_number = ${build_number}"
echo "var_major_version = ${var_major_version}"
echo "var_date = ${var_date}"

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
git clone https://github.com/wangzheng422/openshift4-shell

cd /data/ocp4/tmp/openshift4-shell
git checkout ocp-${var_major_version}
git pull origin ocp-${var_major_version}
/bin/cp -f /data/ocp4/tmp/openshift4-shell/* /data/ocp4/

cd /data/ocp4/

mkdir -p /data/ocp4/clients

# mirror-registry
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients -r -A "mirror-registry.tar.gz" https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/mirror-registry/1.1.0/mirror-registry.tar.gz

# coreos-installer
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients -r -A "coreos-installer_amd64" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/coreos-installer/latest/

# client for camle-k
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients -r -A "*linux*tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/camel-k/latest/

# client for helm
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive -A "helm-linux-amd64.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/

# client for pipeline
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive -A "*linux-amd64-*.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/pipeline/latest/

# client for butane
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive -A "butane-amd64" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/butane/latest/

# client for serverless
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive -A "kn-linux-amd64.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/serverless/latest/

# kam
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive -A "kam-linux-amd64.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/kam/latest/

# operator-sdk
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive -A "operator-sdk-linux-x86_64.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/operator-sdk/latest/

# rhacs
wget -O /data/ocp4/clients/roxctl https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Linux/roxctl

mkdir -p /data/ocp4/rhacs-chart/
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/rhacs-chart --recursive https://mirror.openshift.com/pub/rhacs/charts/


mkdir -p /data/ocp4
/bin/rm -f /data/finished
cd /data/ocp4

install_build() {
    BUILDNUMBER=$1
    echo ${BUILDNUMBER}

    rm -rf /data/ocp4/${BUILDNUMBER}
    mkdir -p /data/ocp4/${BUILDNUMBER}
    cd /data/ocp4/${BUILDNUMBER}

    wget -O release.txt https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/release.txt

    wget -O openshift-client-linux-${BUILDNUMBER}.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/openshift-client-linux-${BUILDNUMBER}.tar.gz
    wget -O openshift-install-linux-${BUILDNUMBER}.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/openshift-install-linux-${BUILDNUMBER}.tar.gz
    wget -O opm-linux-${BUILDNUMBER}.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/opm-linux-${BUILDNUMBER}.tar.gz
    wget -O oc-mirror.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${BUILDNUMBER}/oc-mirror.tar.gz

    tar -xzf openshift-client-linux-${BUILDNUMBER}.tar.gz -C /usr/local/sbin/
    tar -xzf openshift-install-linux-${BUILDNUMBER}.tar.gz -C /usr/local/sbin/
    tar -xzf oc-mirror.tar.gz -C /usr/local/sbin/

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

}

for i in "${build_number_list[@]}"
do
    install_build $i
done
# while read -r line; do
#     install_build $line
# done <<< "$build_number_list"

cd /data/ocp4

wget --recursive --no-directories --no-parent -e robots=off --accept="rhcos-live*,rhcos-metal.x86_64.raw.gz,rhcos-installer-kernel-*,rhcos-qemu.x86_64.qcow2.gz,rhcos-openstack.x86_64.qcow2.gz"  https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/${var_major_version}/latest/

wget -O ocp-deps-sha256sum.txt https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/${var_major_version}/latest/sha256sum.txt

wget -O ocp4-upi-helpernode.zip https://github.com/wangzheng422/ocp4-upi-helpernode/archive/master.zip

# wget -O hostpath-operator.yaml https://raw.githubusercontent.com/kubevirt/hostpath-provisioner-operator/main/deploy/operator.yaml
# wget -O hostpath-webhook.yaml https://raw.githubusercontent.com/kubevirt/hostpath-provisioner-operator/main/deploy/webhook.yaml

# wget -O docker_env.zip https://github.com/wangzheng422/docker_env/archive/dev.zip

# wget -O agnosticd.zip https://github.com/wangzheng422/agnosticd/archive/wzh-ccn-ocp-4.6.zip

# podman pull quay.io/wangzheng422/filetranspiler
# podman save quay.io/wangzheng422/filetranspiler | pigz -c > filetranspiler.tgz

podman pull docker.io/library/registry:2
podman save docker.io/library/registry:2 | pigz -c > registry.tgz

# podman pull docker.io/sonatype/nexus3:3.30.1
# podman save docker.io/sonatype/nexus3:3.30.1 | pigz -c > nexus.3.30.1.tgz

podman pull docker.io/sonatype/nexus3:3.33.1
podman save docker.io/sonatype/nexus3:3.33.1 | pigz -c > nexus.3.33.1.tgz

podman pull quay.io/wangzheng422/qimgs:nexus-fs-image-2022-01-14-2155
podman save quay.io/wangzheng422/qimgs:nexus-fs-image-2022-01-14-2155 | pigz -c > nexus-fs-image.tgz

podman pull registry.redhat.io/rhel8/postgresql-10:1
podman save registry.redhat.io/rhel8/postgresql-10:1 | pigz -c > postgresql-10.tgz

podman pull registry.redhat.io/rhel8/redis-5:1
podman save registry.redhat.io/rhel8/redis-5:1 | pigz -c > redis-5.tgz

podman pull registry.redhat.io/quay/quay-rhel8:v3.6.2
podman save registry.redhat.io/quay/quay-rhel8:v3.6.2 | pigz -c > quay-rhel8.tgz

# oc image mirror --filter-by-os='linux/amd64' quay.io/wangzheng422/operator-catalog:redhat-${var_major_version}-${var_date} ${LOCAL_REG}/ocp4/operator-catalog:redhat-${var_major_version}-${var_date}
# oc image mirror --filter-by-os='linux/amd64' quay.io/wangzheng422/operator-catalog:certified-${var_major_version}-${var_date} ${LOCAL_REG}/ocp4/operator-catalog:certified-${var_major_version}-${var_date}
# oc image mirror --filter-by-os='linux/amd64' quay.io/wangzheng422/operator-catalog:community-${var_major_version}-${var_date} ${LOCAL_REG}/ocp4/operator-catalog:community-${var_major_version}-${var_date}
# oc image mirror --filter-by-os='linux/amd64' quay.io/wangzheng422/operator-catalog:redhat-marketplace-${var_major_version}-${var_date} ${LOCAL_REG}/ocp4/operator-catalog:redhat-marketplace-${var_major_version}-${var_date}

cd /data/ocp4

echo "quay.io/wangzheng422/operator-catalog:redhat-${var_major_version}-${var_date}" >> operator-catalog.list
echo "quay.io/wangzheng422/operator-catalog:certified-${var_major_version}-${var_date}" >> operator-catalog.list
echo "quay.io/wangzheng422/operator-catalog:community-${var_major_version}-${var_date}" >> operator-catalog.list
echo "quay.io/wangzheng422/operator-catalog:redhat-marketplace-${var_major_version}-${var_date}" >> operator-catalog.list

# 以下命令要运行 2-3个小时，耐心等待。。。
# bash image.mirror.install.sh

# some github, and so on
bash demos.sh

# build operator catalog
# find /tmp -type d -regex '^/tmp/[0-9]+$' -exec rm -rf {} + 

oc adm catalog mirror  --index-filter-by-os='linux/amd64' \
    quay.io/wangzheng422/operator-catalog:redhat-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp4 \
    --manifests-only 
/bin/cp -f manifests-operator-catalog-*/mapping.txt mapping-redhat.txt
sed -i 's/=.*//g' mapping-redhat.txt
/bin/rm -rf manifests-operator-catalog-*

podman create --name swap quay.io/wangzheng422/operator-catalog:redhat-${var_major_version}-$var_date  ls
podman cp swap:/database/index.db - > ./index.db.tar
podman rm -fv swap
tar vxf index.db.tar

echo "select * from related_image ;" \
  | sqlite3 -line index.db \
  | paste -d " " - - - | sed 's/ *image = //g' \
  | sed 's/operatorbundle_name =//g' \
  | sort | uniq > redhat-operator-image.list

# find /tmp -type d -regex '^/tmp/[0-9]+$' -exec rm -rf {} + 

oc adm catalog mirror  --index-filter-by-os='linux/amd64' \
    quay.io/wangzheng422/operator-catalog:certified-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp4 \
    --manifests-only 
/bin/cp -f manifests-operator-catalog-*/mapping.txt mapping-certified.txt
sed -i 's/=.*//g' mapping-certified.txt
/bin/rm -rf manifests-operator-catalog-*

# VAR_DIR=`find /tmp -type d -regex '^/tmp/[0-9]+$' `
podman create --name swap quay.io/wangzheng422/operator-catalog:certified-${var_major_version}-$var_date  ls
podman cp swap:/database/index.db - > ./index.db.tar
podman rm -fv swap
tar vxf index.db.tar

echo "select * from related_image ;" \
  | sqlite3 -line index.db \
  | paste -d " " - - - | sed 's/ *image = //g' \
  | sed 's/operatorbundle_name =//g' \
  | sort | uniq > certified-operator-image.list

# find /tmp -type d -regex '^/tmp/[0-9]+$' -exec rm -rf {} + 

oc adm catalog mirror  --index-filter-by-os='linux/amd64' \
    quay.io/wangzheng422/operator-catalog:community-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp4 \
    --manifests-only 
/bin/cp -f manifests-operator-catalog-*/mapping.txt mapping-community.txt
sed -i 's/=.*//g' mapping-community.txt
/bin/rm -rf manifests-operator-catalog-*

# VAR_DIR=`find /tmp -type d -regex '^/tmp/[0-9]+$' `
podman create --name swap quay.io/wangzheng422/operator-catalog:community-${var_major_version}-$var_date  ls
podman cp swap:/database/index.db - > ./index.db.tar
podman rm -fv swap
tar vxf index.db.tar

echo "select * from related_image ;" \
  | sqlite3 -line index.db \
  | paste -d " " - - - | sed 's/ *image = //g' \
  | sed 's/operatorbundle_name =//g' \
  | sort | uniq > community-operator-image.list

# find /tmp -type d -regex '^/tmp/[0-9]+$' -exec rm -rf {} + 

oc adm catalog mirror  --index-filter-by-os='linux/amd64' \
    quay.io/wangzheng422/operator-catalog:redhat-marketplace-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp4 \
    --manifests-only
/bin/cp -f manifests-operator-catalog-*/mapping.txt mapping-redhat-marketplace.txt
sed -i 's/=.*//g' mapping-redhat-marketplace.txt
/bin/rm -rf manifests-operator-catalog-*

# VAR_DIR=`find /tmp -type d -regex '^/tmp/[0-9]+$' `
podman create --name swap quay.io/wangzheng422/operator-catalog:redhat-marketplace-${var_major_version}-$var_date  ls
podman cp swap:/database/index.db - > ./index.db.tar
podman rm -fv swap
tar vxf index.db.tar

echo "select * from related_image ;" \
  | sqlite3 -line index.db \
  | paste -d " " - - - | sed 's/ *image = //g' \
  | sed 's/operatorbundle_name =//g' \
  | sort | uniq > redhat-marketplace-image.list

bash image.registries.conf.sh nexus.ocp4.redhat.ren:8083

/bin/rm -f index.html*
/bin/rm -rf operator-catalog-manifests
/bin/rm -f sha256sum.txt*
/bin/rm -f clients/sha256sum.txt*
/bin/rm -rf /data/ocp4/tmp
/bin/rm -rf operator-catalog-manifests
/bin/rm -f index.db index.db.tar

cd /data

var_finish_date=$(date '+%Y-%m-%d-%H%M')
echo $var_finish_date > /data/finished

