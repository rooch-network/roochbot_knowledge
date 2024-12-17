# 检查是否提供了配置文件参数
if [ $# -eq 0 ]; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

# 使用第一个命令行参数作为配置文件路径
CONFIG_FILE="$1"

# Parse config and execute sync
CONFIG=$(cat "$CONFIG_FILE" | yq -o json)
echo "$CONFIG" | jq -c '.repositories[]' | while read -r repo; do
source_repo=$(echo $repo | jq -r '.source_repo')
source_branch=$(echo $repo | jq -r '.source_branch')
target_path=$(echo $repo | jq -r '.target_path')
patterns=$(echo $repo | jq -r '.patterns[]')

# Create temporary directory
TEMP_DIR=$(mktemp -d)

# Clone source repository
git clone --depth 1 -b $source_branch $source_repo $TEMP_DIR

# Create filter rules file
echo "$patterns" > $TEMP_DIR/filter-rules.txt

# Use rsync for sync
rsync -av --delete \
    --include-from=$TEMP_DIR/filter-rules.txt \
    --exclude='*' \
    $TEMP_DIR/ $target_path/

# Clean temporary directory
rm -rf $TEMP_DIR
done