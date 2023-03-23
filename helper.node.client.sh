#!/usr/bin/env bash

set -e
set -x

rm -rf /data/ocp4/clients/
mkdir -p /data/ocp4/clients
cd /data/ocp4/clients

# oc-mirror


# mirror-registry
wget  -O mirror-registry.tar.gz https://developers.redhat.com/content-gateway/rest/mirror2/pub/openshift-v4/clients/mirror-registry/latest/mirror-registry.tar.gz

# coreos-installer
wget  -O coreos-installer_amd64 https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/coreos-installer/latest/coreos-installer_amd64

# client for camle-k
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients -r -A "*linux*tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/camel-k/latest/

# client for helm
wget  -O "helm-linux-amd64.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64.tar.gz

# client for pipeline
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive -A "*linux-amd64-*.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/pipeline/latest/

# client for butane
wget  -O "butane-amd64" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/butane/latest/butane-amd64

# client for serverless
wget  -O "kn-linux-amd64.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/serverless/latest/kn-linux-amd64.tar.gz

# kam
wget  -O "kam-linux-amd64.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/kam/latest/kam-linux-amd64.tar.gz

# operator-sdk
wget  -O "operator-sdk-linux-x86_64.tar.gz" https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/operator-sdk/latest/operator-sdk-linux-x86_64.tar.gz

# rhacs
wget -O /data/ocp4/clients/roxctl https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Linux/roxctl

# mkdir -p /data/ocp4/rhacs-chart/
# wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/rhacs-chart --recursive https://mirror.openshift.com/pub/rhacs/charts/


cd /data/ocp4

# wget --recursive --no-directories --no-parent -e robots=off --accept="rhcos-live*,rhcos-metal.x86_64.raw.gz,rhcos-installer-kernel-*,rhcos-qemu.x86_64.qcow2.gz,rhcos-openstack.x86_64.qcow2.gz"  https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/${var_major_version}/latest/

# wget -O ocp-deps-sha256sum.txt https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/${var_major_version}/latest/sha256sum.txt

# podman pull docker.io/sonatype/nexus3:3.33.1
# podman save docker.io/sonatype/nexus3:3.33.1 | pigz -c > nexus.3.33.1.tgz

# podman pull quay.io/wangzheng422/qimgs:nexus-fs-image-2022-01-14-2155
# podman save quay.io/wangzheng422/qimgs:nexus-fs-image-2022-01-14-2155 | pigz -c > nexus-fs-image.tgz

# install /data/ocp4/clients/butane-amd64 /usr/local/bin/butane

/bin/rm -f index.html*
/bin/rm -rf operator-catalog-manifests
/bin/rm -f sha256sum.txt*
/bin/rm -f clients/sha256sum.txt*
/bin/rm -rf /data/ocp4/tmp
/bin/rm -rf operator-catalog-manifests
/bin/rm -f index.db index.db.tar

cd /data
