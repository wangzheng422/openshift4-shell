#!/usr/bin/env bash

# 这个函数用在assisted install service的ignition文件制作中
# 我们要向coreos注入配置文件，主要是静态ip配置，镜像仓库证书，以及crio的registry配置
# assisted install service制作的 coreos iso , 会重启1次，也就是一共有2次启动，每次启动调用的配置文件位置不一样
# 所以，我们就用标准的ocp machine config配置yaml 作为输入，输出2个ignition配置文件，对应2次启动。
# 第一次的coreos启动，assisted install service会把静态配置文件，其实是一些脚本，做为initrd放到pxe的image里面，而其他的配置，会放到另外一个ignition image里面，也就是ignition file
# 第二次coreos启动，会在第一次启动的时候，从/opt/openshift/openshift/ 读取
# 这个函数有2个参数，第一个参数，是第二次启动读取的目标文件名
# 第一个参数，是注入文件内容的源文件
get_file_content_for_ignition () {
  VAR_FILE_NAME=$1
  VAR_FILE_CONTENT_IN_FILE=$2

  tmppath=$(mktemp)

cat << EOF > $tmppath
      {
        "overwrite": true,
        "path": "$VAR_FILE_NAME",
        "user": {
          "name": "root"
        },
        "contents": {
          "source": "data:text/plain,$(cat $VAR_FILE_CONTENT_IN_FILE | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(''.join(sys.stdin.readlines())))"  )"
        }
      }
EOF

  RET_VAL=$(cat $tmppath | jq -c .)

  FILE_JSON=$(cat $VAR_FILE_CONTENT_IN_FILE | python3 -c 'import json, yaml, sys; print(json.dumps(yaml.safe_load(sys.stdin)))')

cat << EOF > $tmppath
      {
        "overwrite": true,
        "path": "$(echo $FILE_JSON | jq -r .spec.config.storage.files[0].path )",
        "user": {
          "name": "root"
        },
        "contents": {
          "source": "$( echo $FILE_JSON | jq -r .spec.config.storage.files[0].contents.source )"
        }
      }
EOF
  # cat $tmppath

  RET_VAL_2=$(cat $tmppath | jq -c .)

  /bin/rm -f $tmppath
}

# declare -fx get_file_content_for_ignition
export -f get_file_content_for_ignition
