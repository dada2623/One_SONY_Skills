---
name: media-organizer
description: 管理家庭影音流水线：PT 下载、经阿里云盘转待看并取回本地、TrueNAS 整理归档。Use when 用户要管理 PT 下载任务、把影视转为待看、上传或取回阿里云盘、归档已看影视（归档前先提醒确认）、或清理已归档副本。
---

# Media Organizer

## 环境

主机与账号见 `~/.ssh/config`，设备与站点命名以 `~/.dsh/network/devices.md` 为准。不要在 skill 或脚本中写死密码。

- **SandY**（`192.168.50.0/24`）：`sandy-nas-fnos` 跑 Transmission、保存待看备份；`sandy-nas-truenas` 保存归档，仅经 CIFS 访问。
- **租房**（`192.168.5.0/24`）：`sony-memini-fnos` 接收待看；`vaio-deskstation-2024` 是当前 Mac 执行端。

| 用途 | 执行主机 | 路径 |
|---|---|---|
| 下载与永久做种源 | `sandy-nas-fnos` | `/vol2/1000/Downloads` |
| SandY 待看备份 | `sandy-nas-fnos` | `/vol2/1000/Backup/Film and TV (aDrive)` |
| 租房本地待看 | `sony-memini-fnos` | `/vol1/1000/Backup/Film and TV (aDrive)` |
| 租房下载临时目录 | `sony-memini-fnos` | `/vol1/1000/Temp` |
| TrueNAS 归档目标（CIFS） | `sandy-nas-fnos` | `/vol02/1000-0-8eb8a616/Film and TV` |

`/vol02/1002-0-ba62e9a2`（FAT 共享根）也指向同一个 TrueNAS 归档目录，不是另一份副本。

### 工具与账号

- **Transmission**：`http://192.168.50.87:9091/transmission/rpc`，用户 `One_SONY`。密码从 `TR_PASS` 或 macOS 钥匙串 `transmission-rpc` 读取。
- **阿里云盘**：两台飞牛均已安装 `aliyunpan`，账号 `One_SONY`。二进制 `/usr/local/bin/aliyunpan`，`/usr/bin/aliyunpan` 为软链；配置在 `~/.config/aliyunpan/aliyunpan_config.json`（权限 600）。
- 云盘操作统一 SSH 到 NAS 执行 `aliyunpan`，使用**备份盘**，根目录为 `/Film and TV (aDrive)`；不操作资源库。运行前确认当前网盘，必要时用 `aliyunpan drive` 切换。
- `aliyunpan download` 落盘到 `<savedir>/<账号uid>/`；当前 uid 为 `0ffece242926461289eb6640d49f6fdc`。

```bash
# 云盘配额与待看清单
ssh -o BatchMode=yes sandy-nas-fnos 'aliyunpan quota'
ssh -o BatchMode=yes sandy-nas-fnos 'aliyunpan ls "/Film and TV (aDrive)"'
```

### 执行约定

- NAS 操作走 `ssh -o BatchMode=yes <别名>`；路径含空格和括号，必须正确引用。
- **待看只经阿里云盘中转**。SandY → 租房直传会因家宽上传量过大触发运营商风控，不用跨站 rsync 代替中转。
- `Downloads` 与 Transmission 任务永久保留：不删、不移、不改名。从下载目录转出时只复制，归档清理不碰做种源。
- 删除前列出目标路径与计划，先预演并取得用户确认；目标必须存在，保留副本的普通文件总字节与文件数必须一致。删除命令须检查 `$NAME` 非空，并核对完整目标路径。
- 大文件传输前查本地剩余空间和云盘配额；长任务放后台并定期读取日志，汇报进度、速度及秒传或实传结果。
- 不改 `devices.md`、Transmission 或飞牛配置。

## 下载工作流

人工部分：浏览器里用 PTPP 搜种、挑上传数/体积/编码合适的资源，拿到磁力链接或种子文件。
自动化部分：提交 → 跟踪 → 完成汇报。

```bash
# 提交（磁力或 .torrent 均可）
python3 scripts/transmission.py add "magnet:?xt=urn:btih:..."
python3 scripts/transmission.py add /path/to/file.torrent --dir "/vol2/1000/Downloads"

# 查看全部任务（进度/速度/ETA/状态）
python3 scripts/transmission.py list

# 只看某个任务
python3 scripts/transmission.py info <id>
```

密码来源优先级：`TR_PASS` 环境变量 → macOS 钥匙串（`security find-generic-password -s transmission-rpc -w`）。

汇报格式：`名称 | 进度% | 速度 | 剩余时间 | 状态`；完成后给出实际落地路径（`downloadDir + name`），供下一步使用。

任务完成后不要 `remove`，也不要在 `Downloads` 里做任何删除或移动。下一步只是把它复制出去。

## 转待看工作流

完整流程：SandY 下载源 → SandY 待看备份 → 阿里云盘 → 租房本地待看。**取回租房并校验通过才算完成待看**。

以下变量在执行端定义；`sum` 校验函数见「完成标准」。

```bash
NAME="Some.Show.S01.1080p"
SRC="/vol2/1000/Downloads/$NAME"
BAK="/vol2/1000/Backup/Film and TV (aDrive)/$NAME"
CLOUD="/Film and TV (aDrive)/$NAME"
TMP="/vol1/1000/Temp"
DST="/vol1/1000/Backup/Film and TV (aDrive)"
```

### 1. 预检与 SandY 本地备份

确认 Transmission 已完成、源文件存在，检查云盘同名条目和租房空间。租房可用空间须大于待取回大小 × 1.1，且预计落盘后仍剩余 >100G；不足时先报告，让用户决定清理哪些旧片。

```bash
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"$CLOUD\""
ssh -o BatchMode=yes sony-memini-fnos 'df -h /vol1'
ssh -o BatchMode=yes sandy-nas-fnos "rsync -rlt --no-perms --no-owner --no-group --info=progress2 \"$SRC\" \"/vol2/1000/Backup/Film and TV (aDrive)/\""
```

核对源与备份的普通文件总字节和文件数。云端已有同名内容且校验一致时跳过上传；不一致先报告，不覆盖；仅在明确不存在时新建上传，查询失败不能当成不存在。

### 2. 上传并校验云盘

```bash
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan upload \"$BAK\" \"/Film and TV (aDrive)\""
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"$CLOUD\""
```

以 `aliyunpan` 输出核对云端与 SandY 备份的普通文件总字节和文件数；有子目录时核对全部文件。秒传或实传以日志为准，上传成功后仍须完成上述核对。

### 3. 取回租房并落盘

```bash
ssh -o BatchMode=yes sony-memini-fnos "aliyunpan config set -savedir \"$TMP\" && aliyunpan download \"$CLOUD\""
# 下载成功并确认目标无冲突后，将账号 uid 目录里的条目移到待看目录
ssh -o BatchMode=yes sony-memini-fnos "mv \"$TMP/0ffece242926461289eb6640d49f6fdc/$NAME\" \"$DST/\""
```

核对租房本地与云盘的普通文件总字节和文件数，确认剩余空间仍 >100G，再汇报本地待看路径。只有云端副本或临时下载完成，都不能算转待看完成。

## 整理归档工作流

顺序固定：SandY 待看备份搬到 TrueNAS → 校验 → 删阿里云盘副本 → 删租房副本。前一步验证通过才做下一步。

### 1. 归档前提醒并确认

动文件前，发给用户并等待明确确认：

- 主标识截图是否已全部完成？截图由用户自己做，agent 不抽帧。
- 本次条目清单：名称、大小、当前位置及将删除的副本路径。
- 计划执行上述四步；`Downloads` 原件和 Transmission 任务继续保留做种。

未确认前只做查询和预演，不执行写操作。

### 2. SandY 待看备份 → TrueNAS

跨文件系统先拷后删；不要直接移动。

```bash
NAME="Some.Show.S01.1080p"
SRC="/vol2/1000/Backup/Film and TV (aDrive)/$NAME"
DST="/vol02/1000-0-8eb8a616/Film and TV"
CLOUD="/Film and TV (aDrive)/$NAME"

# 预演与拷贝
ssh -o BatchMode=yes sandy-nas-fnos "rsync -rltn --no-perms --no-owner --no-group --itemize-changes \"$SRC/\" \"$DST/$NAME/\""
ssh -o BatchMode=yes sandy-nas-fnos "rsync -rlt --no-perms --no-owner --no-group --info=progress2 \"$SRC\" \"$DST/\""

# 拷贝后复查：应无真实文件差异
ssh -o BatchMode=yes sandy-nas-fnos "rsync -rltn --no-perms --no-owner --no-group --itemize-changes \"$SRC/\" \"$DST/$NAME/\""
```

按「完成标准」核对源与目标的普通文件总字节、文件数。校验一致且无真实文件差异后，才删除 SandY 待看备份，并确认该路径已不存在：

```bash
[ -n "$NAME" ] || exit 1
ssh -o BatchMode=yes sandy-nas-fnos "ls -ld \"$SRC\""
ssh -o BatchMode=yes sandy-nas-fnos "rm -rf \"$SRC\""
```

### 3. 删除阿里云盘副本

```bash
[ -n "$NAME" ] || exit 1
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan rm \"$CLOUD\""
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"$CLOUD\""
```

以 API 明确返回目标不存在为准；有残留或查询报错就暂停，不继续删除租房副本。

### 4. 删除租房副本

删除前先打印目标并让用户确认路径，再执行删除；完成后确认目标不存在。

```bash
[ -n "$NAME" ] || exit 1
ssh -o BatchMode=yes sony-memini-fnos "ls -ld \"/vol1/1000/Backup/Film and TV (aDrive)/$NAME\""
ssh -o BatchMode=yes sony-memini-fnos "rm -rf \"/vol1/1000/Backup/Film and TV (aDrive)/$NAME\""
```

## 故障与边界

- **云盘挂载点不可信**：rclone/WebDAV 有目录缓存和读取错误；上传、下载、删除及存在性判断全部使用 NAS 上的 `aliyunpan`，不用挂载点。
- **云盘查询失败**：先用 `aliyunpan quota` 检查登录态，再核对当前网盘与路径。不能把命令失败或无输出当成已删除。
- **秒传与速度**：云端没有自己的副本也可能秒传，以日志为准；未命中时受上行或接口限速影响，大文件可能耗时很长，不承诺历史实测速度。
- **校验误差**：不用 `du -sb`，它包含跨文件系统不一致的目录大小；只统计普通文件。CIFS 拷贝用 `rsync -rlt --no-perms --no-owner --no-group`，不用 `-a`，不比较权限或属主。
- **磁盘不足**：先报告空间，让用户决定清理哪些副本；不静默删除，不清理做种源。
- **TrueNAS SSH 不通**：文件操作从 SandY 飞牛走现有 CIFS 挂载，不尝试开启 SSH。
- **跨站 SSH 超时**：先报告，再重试一次；不循环重连，不改现有网络配置。

## 完成标准

| 工作流 | 完成条件 |
|---|---|
| 下载 | Transmission 任务 100%，汇报实际落地路径；原件与任务保留做种。 |
| 转待看 | SandY 备份、云盘、租房本地三处的普通文件总字节与文件数一致；租房文件已进入待看目录，剩余空间 >100G。 |
| 整理归档 | TrueNAS 目标校验一致，SandY 待看备份、云盘及租房副本均确认无残留；做种原件与任务保持原样。 |

本地与 CIFS 校验：先确认路径存在且可读，再统计**普通文件总字节和文件数**；命令失败或空输出不能作为一致的证据。云端通过 `aliyunpan` 核对全部文件，不使用挂载点。

```bash
# 在执行端定义，供 SSH 查询 NAS 路径使用
sum() {
  local host="$1" path="$2" q
  q=$(printf '%q' "$path")
  ssh -o BatchMode=yes "$host" "find $q -type f -printf '%s\n' | awk '{s+=\$1} END{printf \"%.0f\n\", s}'"
}

# 普通文件总字节与文件数
sum sandy-nas-fnos "$SRC"
ssh -o BatchMode=yes sandy-nas-fnos "find \"$SRC\" -type f | wc -l"
```
