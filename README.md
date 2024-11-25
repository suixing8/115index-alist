# 115index-alist

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/suixing8/115index-alist/main/script.sh)"
```
## 使用说明
1.alist挂载网盘后安全进行索引，测试服务器为Ubuntu24.04，测试网盘为115，其他网盘应该也是可以的

2.将115添加到alsit，用davfs2通过webdav的方式挂载到本地，停止alist，将alist的data.db，复制到脚本同目录下，建议data.db先备份一份，有问题可以恢复

3.运行脚本，输入挂载的目录，例如：/mnt/webdav1 /mnt/webdav2

是否执行自动剔除无效路径？

默认就可以，因为find生成的部分信息是alist索引不需要的，比如你挂载的系统路劲

请输入索引操作的间隔时间范围（毫秒）--每一次检索间隔时间，可以默认

请输入暂停时间范围（秒）--设置暂停索引间隔的大时间，因为我并不知道风控的红线在哪，所以增加这个功能，可以默认

请输入操作次数范围 --索引多少次后，进行长一点时间的间隔，此功能是和上面的功能搭配的


请选择替换或新增 find-data.db 中的表到 data.db --可以选择新增或者直接替换原来alist的数据库，只会替换索引的那个数据表

当数据库没有索引表的时候会自动创建

将代码目录下data.db数据库替换alist的data.db，开启alist，测试搜索功能即可


2.设置权限（如有必要）：
bash
chmod +x export_ to_db.sh

运行脚本：
bash

./script.sh

## 示例运行

以下是运行脚本的示例：

bash
操作前建议备份数据库
请输入一个或多个搜索路径，用空格分隔，输入完成后按Enter，例如：/mnt/webdav /home/user/docs /var/log

/mnt/webdav /home/user/docs /var/log

是否执行自动剔除无效路径？默认为Y（确认），输入N（不执行）

Y

请输入索引操作的间隔时间范围（毫秒），例如：100-300

100-300

请输入暂停时间范围（秒），例如：30-60

30-60

请输入操作次数范围，例如：500-1000

500-1000

日志文件

脚本会生成一个 script_log.txt 文件，用于记录脚本运行过程中的详细日志。


## 4.常见问题

数据库连接失败：确保 SQLite3 已安装并且路径正确
。
路径不存在：确保输入的路径是有效的目录路径。



## 贡献

欢迎通过提交 issue 和 pull request 来贡献代码和改进脚本。


## 许可

该项目采用 MIT 许可。
