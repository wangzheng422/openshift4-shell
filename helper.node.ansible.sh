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


cd /data
