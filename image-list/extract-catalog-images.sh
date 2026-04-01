#!/bin/bash
# 从 operator-catalogs 目录下所有 catalog.json 中提取 relatedImages 的 image 列表
# 按 catalog index 类型分别输出三份镜像文件，并附带域名统计文件
# 用法: ./extract-catalog-images.sh [输出目录]

BASE_DIR="/home/sno/data/mirror/working-dir/operator-catalogs"
OUT_DIR="${1:-/home/sno}"

CATALOGS=(
    "certified-operator-index"
    "community-operator-index"
    "redhat-operator-index"
)

# 从镜像名称提取域名，规则：
#   第一段含 .              -> 正常外部镜像仓库域名
#   第一段为 hostname:port  -> 带端口的镜像仓库（port 为纯数字）
#   第一段含 : 但不是端口   -> oci:/controller:latest 等无效条目，跳过
#   无任何域名前缀           -> docker.io
extract_domain() {
    awk -F'/' '{
        first = $1
        if (first ~ /\./) {
            print first
        } else if (first ~ /^[^:]+:[0-9]+$/) {
            print first
        } else if (first ~ /:/) {
            next
        } else {
            print "docker.io"
        }
    }'
}

for catalog in "${CATALOGS[@]}"; do
    catalog_dir="${BASE_DIR}/${catalog}"
    img_file="${OUT_DIR}/${catalog}-images.txt"
    domain_file="${OUT_DIR}/${catalog}-domains.txt"

    if [ ! -d "$catalog_dir" ]; then
        echo "[WARN] 目录不存在，跳过: $catalog_dir"
        continue
    fi

    echo "[INFO] === 处理: $catalog ==="

    # 提取所有镜像（去重排序）
    find "$catalog_dir" -name 'catalog.json' -type f | while read -r f; do
        echo "[INFO]   -> $f" >&2
        jq -r 'select(.relatedImages != null) | .relatedImages[].image' "$f" 2>/dev/null
    done | sort -u > "$img_file"

    img_count=$(wc -l < "$img_file")
    echo "[INFO] 镜像列表: $img_count 个唯一镜像 -> $img_file"

    # 提取域名统计（数量 域名，按数量降序）
    extract_domain < "$img_file" | sort | uniq -c | sort -rn > "$domain_file"

    domain_count=$(wc -l < "$domain_file")
    echo "[INFO] 域名统计: $domain_count 个域名 -> $domain_file"
    echo "[INFO] 域名明细:"
    cat "$domain_file" | awk '{printf "  %6s  %s\n", $1, $2}'
    echo ""
done

echo "[INFO] ========== 汇总 =========="
for catalog in "${CATALOGS[@]}"; do
    img_f="${OUT_DIR}/${catalog}-images.txt"
    dom_f="${OUT_DIR}/${catalog}-domains.txt"
    [ -f "$img_f" ] && printf "  %-30s %5d 个镜像  %d 个域名\n"         "$catalog" "$(wc -l < "$img_f")" "$(wc -l < "$dom_f")"
done
