#!/bin/bash

# 提示用户备份数据库
echo "操作前建议备份数据库"
# 提示用户输入路径
echo "请输入一个或多个搜索路径，用空格分隔，输入完成后按Enter，例如：/mnt/webdav /home/user/docs /var/log"
read -r -a search_paths

# 检查是否提供了至少一个路径
if [ ${#search_paths[@]} -eq 0 ]; then
    echo "请提供至少一个路径。"
    exit 1
fi

# 提示用户是否执行自动剔除无效路径
echo "是否执行自动剔除无效路径？默认为Y（确认），输入N（不执行）"
read -r auto_exclude

# 如果用户不输入，默认为Y
if [ -z "$auto_exclude" ];then
    auto_exclude="Y"
fi

# 提示用户设置操作间隔时间范围（毫秒）
echo "请输入索引操作的间隔时间范围（毫秒），例如：100-300"
read -r interval_range

# 如果用户不输入，默认为100-300毫秒
if [ -z "$interval_range" ];then
    interval_range="100-300"
fi

# 解析用户输入的间隔时间范围
if [[ "$interval_range" == *-* ]]; then
    IFS='-' read -r min_interval max_interval <<< "$interval_range"
else
    min_interval="$interval_range"
    max_interval="$interval_range"
fi

# 如果解析失败，设置默认值
if [ -z "$min_interval" ] || [ -z "$max_interval" ];then
    min_interval=100
    max_interval=200
fi

# 提示用户设置暂停时间范围（秒）
echo "请输入暂停时间范围（秒），例如：30-60"
read -r pause_time_range

# 如果用户不输入，默认为30-60秒
if [ -z "$pause_time_range" ];then
    pause_time_range="30-60"
fi

# 解析用户输入的暂停时间范围
if [[ "$pause_time_range" == *-* ]]; then
    IFS='-' read -r min_pause_time max_pause_time <<< "$pause_time_range"
else
    min_pause_time="$pause_time_range"
    max_pause_time="$pause_time范围"
fi

# 如果解析失败，设置默认值
if [ -z "$min_pause_time" ] || [ -z "$max_pause_time" ];then
    min_pause_time=30
    max_pause_time=60
fi

# 提示用户设置操作次数范围
echo "请输入操作次数范围，例如：500-1000"
read -r operation_count_range

# 如果用户不输入，默认为500-1000次
if [ -z "$operation_count_range" ];then
    operation_count_range="500-1000"
fi

# 解析用户输入的操作次数范围
if [[ "$operation_count_range" == *-* ]]; then
    IFS='-' read -r min_operation_count max_operation_count <<< "$operation_count_range"
else
    min_operation_count="$operation_count_range"
    max_operation_count="$operation_count范围"
fi

# 如果解析失败，设置默认值
if [ -z "$min_operation_count" ] || [ -z "$max_operation_count" ];then
    min_operation_count=500
    max_operation_count=1000
fi

# 随机生成操作次数和暂停时间
operation_count=$(shuf -i "$min_operation_count"-"$max_operation_count" -n 1)
pause_time=$(shuf -i "$min_pause_time"-"$max_pause_time" -n 1)

# 定义输出文件
OUTPUT_FILE="files_list.txt"
FIND_DB_FILE="find-data.db"
DATA_DB_FILE="data.db"
LOG_FILE="script_log.txt"

# 清空输出文件和日志文件（如果存在）
> "$OUTPUT_FILE"
> "$LOG_FILE"

# 用于存储要剔除的目录名
exclude_names=()

# 用于计数操作次数
count_operations=0

# 遍历用户输入的每个路径
for SEARCH_PATH in "${search_paths[@]}"; do
    echo "处理搜索路径: $SEARCH_PATH" | tee -a "$LOG_FILE"
    
    # 提取路径的最后一个部分并存储到 exclude_names 数组中
    exclude_name=$(basename "$SEARCH_PATH")
    exclude_names+=("$exclude_name")
    
    # 检查路径是否存在
    if [ -d "$SEARCH_PATH" ]; then
        # 查找文件并记录
        find "$SEARCH_PATH" -type f -print | while read -r file; do
            parent=$(dirname "$file")
            name=$(basename "$file")
            
            trimmed_parent="${parent#$SEARCH_PATH}"
            size=$(stat -c%s "$file")

            # 过滤 name 为 lost+found 的记录
            if [[ "$name" == "lost+found" ]]; then
                continue
            fi

            # 当 trimmed_parent 为空时，自动补上 "/"
            if [[ -z "$trimmed_parent" ]];then
                trimmed_parent="/"
            fi

            echo "$trimmed_parent|$name|0|$size" >> "$OUTPUT_FILE"
            echo "文件: $file, 修剪后的父路径: $trimmed_parent, 名称: $name, 大小: $size" | tee -a "$LOG_FILE"
            
            # 增加操作计数
            count_operations=$((count_operations + 1))

            # 随机生成间隔时间，避免频繁访问引起风控
            sleep_time=$(shuf -i "$min_interval"-"$max_interval" -n 1)
            sleep $(echo "$sleep_time/1000" | bc -l)

            # 检查是否需要暂停
            if [ "$count_operations" -ge "$operation_count" ];then
                echo "操作次数已达 $operation_count 次，暂停 $pause_time 秒" | tee -a "$LOG_FILE"
                sleep "$pause_time"
                # 重置计数器和重新生成操作次数和暂停时间
                count_operations=0
                operation_count=$(shuf -i "$min_operation_count"-"$max_operation_count" -n 1)
                pause_time=$(shuf -i "$min_pause_time"-"$max_pause_time" -n 1)
            fi
        done

        # 查找目录并记录
        find "$SEARCH_PATH" -type d -print | while read -r dir; do
            parent=$(dirname "$dir")
            name=$(basename "$dir")
            
            trimmed_parent="${parent#$SEARCH_PATH}"

            # 过滤 name 为 lost+found 的记录
            if [[ "$name" == "lost+found" ]]; then
                continue
            fi

            # 当 trimmed_parent 为空时，自动补上 "/"
            if [[ -z "$trimmed_parent" ]];then
                trimmed_parent="/"
            fi

            echo "$trimmed_parent|$name|1|0" >> "$OUTPUT_FILE"
            echo "目录: $dir, 修剪后的父路径: $trimmed_parent, 名称: $name" | tee -a "$LOG_FILE"
            
            # 增加操作计数
            count_operations=$((count_operations + 1))

            # 随机生成间隔时间，避免频繁访问引起风控
            sleep_time=$(shuf -i "$min_interval"-"$max_interval" -n 1)
            sleep $(echo "$sleep_time/1000" | bc -l)

            # 检查是否需要暂停
            if [ "$count_operations" -ge "$operation_count" ];then
                echo "操作次数已达 $operation_count 次，暂停 $pause_time 秒" | tee -a "$LOG_FILE"
                sleep "$pause_time"
                # 重置计数器和重新生成操作次数和暂停时间
                count_operations=0
                operation_count=$(shuf -i "$min_operation_count"-"$max_operation_count" -n 1)
                pause_time=$(shuf -i "$min_pause_time"-"$max_pause_time" -n 1)
            fi
        done
    else
        echo "路径 $SEARCH_PATH 不存在或不是目录。" | tee -a "$LOG_FILE"
    fi
done

# 如果输出文件为空则退出
if [ ! -s "$OUTPUT_FILE" ];then
    echo "没有找到任何文件或目录，退出。" | tee -a "$LOG_FILE"
    exit 1
fi

# 创建 SQLite 数据库并创建表
sqlite3 "$FIND_DB_FILE" <<EOF
DROP TABLE IF EXISTS "x_search_nodes";
CREATE TABLE "x_search_nodes" (
	"parent"	text,
	"name"	text,
	"is_dir"	numeric,
	"size"	integer
);
EOF

# 确认表已创建
table_exists=$(sqlite3 "$FIND_DB_FILE" "SELECT name FROM sqlite_master WHERE type='table' AND name='x_search_nodes';")
if [ -z "$table_exists" ];then
    echo "表 x_search_nodes 创建失败。" | tee -a "$LOG_FILE"
    exit 1
fi

# 导入文本文件中的数据到 SQLite 数据库
sqlite3 "$FIND_DB_FILE" <<EOF
.mode csv
.separator "|"
.import $OUTPUT_FILE x_search_nodes
EOF

# 确认数据是否导入成功
imported_count=$(sqlite3 "$FIND_DB_FILE" "SELECT COUNT(*) FROM x_search_nodes;")
echo "数据记录数: $imported_count" | tee -a "$LOG_FILE"
if [ "$imported_count" -eq 0 ];then
    echo "数据导入失败。" | tee -a "$LOG_FILE"
    exit 1
fi

# 删除中间文本文件
rm "$OUTPUT_FILE"

# 确认数据库文件存在并等待其稳定
while [ ! -f "$FIND_DB_FILE" ];do
    echo "等待数据库文件创建..." | tee -a "$LOG_FILE"
    sleep 1
done

echo "数据库文件已创建。" | tee -a "$LOG_FILE"

# 如果用户选择执行自动剔除无效路径
if [[ "$auto_exclude" =~ ^[Yy]$ ]]; then
    echo "开始剔除路径操作..." | tee -a "$LOG_FILE"

    # 删除剔除路径的数据并记录日志
    for exclude_name in "${exclude_names[@]}"; do
        echo "即将剔除 name 为: $exclude_name 的数据行" | tee -a "$LOG_FILE"
        
        # 打印将要剔除的数据
        matched_entries=$(sqlite3 "$FIND_DB_FILE" "SELECT * FROM x_search_nodes WHERE name = '$exclude_name';")
        if [ -n "$matched_entries" ];then
            echo "以下数据将被剔除:" | tee -a "$LOG_FILE"
            echo "$matched_entries" | tee -a "$LOG_FILE"
            SQL="DELETE FROM x_search_nodes WHERE name = '$exclude_name';"
            echo "执行 SQL: $SQL" | tee -a "$LOG_FILE"
            result=$(sqlite3 "$FIND_DB_FILE" "$SQL")
            echo "SQL 结果: $result" | tee -a "$LOG_FILE"

            # 检查是否有删除记录
            count=$(sqlite3 "$FIND_DB_FILE" "SELECT COUNT(*) FROM x_search_nodes WHERE name = '$exclude_name';")
            if [ "$count" -eq 0 ];then
                echo "所有 name 为 '$exclude_name' 的记录已被删除。" | tee -a "$LOG_FILE"
            else
                echo "无法删除某些 name 为 '$exclude_name' 的记录。剩余数量: $count" | tee -a "$LOG_FILE"
            fi
        else
            echo "没有找到匹配 name 为: $exclude_name 的数据行" | tee -a "$LOG_FILE"
        fi
    done
else
    echo "用户选择不剔除无效路径。" | tee -a "$LOG_FILE"
fi

echo "数据已导出到 $FIND_DB_FILE" | tee -a "$LOG_FILE"

# 提示用户选择替换或新增到 data.db
echo "请选择替换或新增 find-data.db 中的表到 data.db。输入 R 替换，A 新增，默认为 A"
read -r action_choice

# 如果用户不输入，默认为 A
if [ -z "$action_choice" ];then
    action_choice="A"
fi

# 根据用户选择执行替换或新增操作
if [[ "$action_choice" =~ ^[Rr]$ ]]; then
    echo "替换 data.db 中的 x_search_nodes 表。" | tee -a "$LOG_FILE"
    sqlite3 "$DATA_DB_FILE" <<EOF
DROP TABLE IF EXISTS "x_search_nodes";
ATTACH DATABASE '$FIND_DB_FILE' AS find_db;
CREATE TABLE "x_search_nodes" (
	"parent"	text,
	"name"	text,
	"is_dir"	numeric,
	"size"	integer
);
INSERT INTO "x_search_nodes" SELECT * FROM find_db."x_search_nodes";
DETACH DATABASE find_db;
EOF
else
    echo "新增 find-data.db 中的数据到 data.db 的 x_search_nodes 表。" | tee -a "$LOG_FILE"
    sqlite3 "$DATA_DB_FILE" <<EOF
ATTACH DATABASE '$FIND_DB_FILE' AS find_db;
INSERT INTO "x_search_nodes" SELECT * FROM find_db."x_search_nodes";
DETACH DATABASE find_db;
EOF
fi

echo "操作完成。" | tee -a "$LOG_FILE"
