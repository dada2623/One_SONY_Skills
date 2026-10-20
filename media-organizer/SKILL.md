---
name: media-organizer
description: 管理跨三台 NAS 的影音流水线：武汉 fnOS 上用 Transmission 下载 PT 资源，经阿里云盘（fnOS rclone 挂载）中转到广州 fnOS 待看，看完后归档到 TrueNAS 并清理各端副本；云盘管理（ls/rm/quota）用两台 NAS 上已安装的 aliyunpan 执行。待看只走阿里云盘中转，不做武汉→广州直传。Use when 用户要添加/查询/暂停 PT 下载任务、把下载完成的影视转进待看目录、上传到阿里云盘、从阿里云盘取到广州 NAS、把待看文件归档到 TrueNAS（归档前必须先提醒用户确认）、或清理阿里云盘/广州 NAS 上的副本。
---

# Media Organizer

## 0. 环境

主机与账号见 `~/.ssh/config`，设备名见 `~/.dsh/network/devices.md`。**不要在 skill 或脚本里写死密码。**

路径（均已核实存在）：

| 用途 | 主机 | 路径 |
|---|---|---|
| 下载目录 | 武汉 fnOS | `/vol2/1000/Downloads` |
| 武汉待看备份 | 武汉 fnOS | `/vol2/1000/Backup/Film and TV (aDrive)` |
| 阿里云盘 · Film and TV (aDrive) | 武汉 fnOS（rclone 挂载，rw） | `/vol02/1000-1-ab449892/备份盘/Film and TV (aDrive)` |
| 阿里云盘 · 同一份（另一挂载点） | 广州 fnOS（rclone 挂载，rw） | `/vol02/1000-1-a5d641f4/备份盘/Film and TV (aDrive)` |
| 广州待看 | 广州 fnOS | `/vol1/1000/Backup/Film and TV (aDrive)` |
| TrueNAS 影音（**归档目标**） | 武汉 fnOS | `/vol02/1000-0-8eb8a616/Film and TV` |
| TrueNAS 影音（同一目标的另一挂载点） | 武汉 fnOS | `/vol02/1002-0-ba62e9a2`（FAT 共享根，挂载到的**就是**上面那个目录，别当成两个地方） |

Transmission：`http://192.168.50.87:9091/transmission/rpc`，用户名 `One_SONY`；密码在 macOS 钥匙串（`transmission-rpc`），脚本自动读取，**不要写进文件**。

阿里云盘管理 CLI（`aliyunpan` v0.4.0，**两台 NAS 均已通过官方 apt 源装好**，同一账号 `One_SONY`）：

| 项 | 值 |
|---|---|
| 二进制 | `/usr/local/bin/aliyunpan`（`/usr/bin/aliyunpan` 是它的软链） |
| 配置 | `~/.config/aliyunpan/aliyunpan_config.json`（600，两台各一份，内容相同） |
| 默认网盘 | 备份盘；`aliyunpan drive` 可切到资源库，不在资源库里进行任何操作 |
| 云盘根 | `/Film and TV (aDrive)` 对应挂载点的 `备份盘/Film and TV (aDrive)` |
| 已用配额 | 757 / 997 GB（76%，2026-10-20） |

## 1. 通用规则

- 全部操作走 `ssh <别名>`，命令加 `-o BatchMode=yes`，失败立刻报错而不是卡住。
- 路径含空格与括号，**每个路径都加双引号**。
- 删除前必须校验：目标存在、且大小/条目数与源一致；默认先 `--dry-run` 打印计划，用户确认后再执行。
- 写阿里云盘挂载点后要回读确认（`ls -l` 比对字节数），rclone 挂载是异步的，必要时 `sleep 5` 再复查。
- 大文件先查剩余空间：广州 NAS 只剩 ~214G，4K 原盘可能放不下，先报数再动手。
- **待看中转只能走阿里云盘**：不要为了省事从武汉 NAS 直接 rsync 到广州 NAS —— 家宽上传量过大会触发运营商风控。
- 云盘管理（列目录、删文件、查配额）一律在 NAS 上执行 `aliyunpan`，不走 Mac、也不在 FUSE 挂载点上做 `rm -rf` 大目录。
- 不改 `devices.md`、不改 Transmission/飞牛的配置文件。

## 2. 下载工作流

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

## 3. 转待看（武汉本地备份 + 上阿里云）

```bash
NAME="Some.Show.S01.1080p"
SRC="/vol2/1000/Downloads/$NAME"
BAK="/vol2/1000/Backup/Film and TV (aDrive)/$NAME"
CLOUD="/vol02/1000-1-ab449892/备份盘/Film and TV (aDrive)/$NAME"

# A. 本地留一份，避免飞牛每日备份任务重复下载
ssh -o BatchMode=yes sandy-nas-fnos "rsync -a --info=progress2 \"$SRC\" \"/vol2/1000/Backup/Film and TV (aDrive)/\""

# B. 传到阿里云盘（rclone 挂载，同机直接 rsync）
ssh -o BatchMode=yes sandy-nas-fnos "rsync -a --info=progress2 \"$BAK\" \"/vol02/1000-1-ab449892/备份盘/Film and TV (aDrive)/\""

# C. 回读校验：字节数必须一致
ssh -o BatchMode=yes sandy-nas-fnos "du -sb \"$BAK\" \"/vol02/1000-1-ab449892/备份盘/Film and TV (aDrive)/$NAME\""
```

注意：rclone 挂载写入后可能有延迟，校验前先 `sleep 5`；若两边差异仍在，说明上传未完成，等 30s 重查，不要直接重传覆盖。

**秒传的实测结论（2026-10-20，广州 NAS 上测的）**：飞牛网关对云盘里已存在的内容会走秒传——193MB 文件 `cp` 进挂载点 2 秒完成，网卡出向 0MB；而云盘没有的新内容会实传——100MB 随机文件耗时 22 秒、出向约 107MB。用 `aliyunpan upload` 做同样的对照，结果一致（已有内容 4 秒/0B，新内容 22 秒/100MB）。

所以：

- **新片（云盘里没有）两条路都要实传一次**，秒传省不到；"省钱"的收益只在重复上传、重建副本、误删补回时出现。
- 下面的 `du -sb` 预检，作用是**省掉一次无谓的写入动作**，不是触发秒传的机制，两者别混为一谈。
- 挂载点自己的秒传是不可见的（没有日志），想确认到底传没传，看 `aliyunpan upload` 的输出或测网卡字节。

```bash
ssh -o BatchMode=yes sandy-nas-fnos "du -sb \"$BAK\" 2>/dev/null; du -sb \"$CLOUD\" 2>/dev/null"
```

比较两行数字（云端没有输出就是不存在）。

- 云端已有同名同大小 → 跳过上传，只做第 C 步校验。
- 云端存在但大小不同 → 报给用户，不要盲目覆盖（可能是另一版本）。
- 云端不存在 → 正常上传。

## 4. 取到广州（本地落盘）

```bash
NAME="Some.Show.S01.1080p"
ssh -o BatchMode=yes sony-memini-fnos "df -h /vol1 | tail -1"
ssh -o BatchMode=yes sony-memini-fnos "rsync -a --info=progress2 \"/vol02/1000-1-a5d641f4/备份盘/Film and TV (aDrive)/$NAME\" \"/vol1/1000/Backup/Film and TV (aDrive)/\""
```

先确认剩余空间 > 文件大小 ×1.1。若不足，提示用户清理或改用流式播放，不要写满 /vol1（与系统同盘）。

## 5. 云盘管理（在 NAS 上跑）

两台 NAS 都装了 apt 版 `aliyunpan`（见第 0 节），管理类操作统一 SSH 到 NAS 执行，不要让数据绕道 Mac。

```bash
# 查配额 / 列云盘根
ssh -o BatchMode=yes sandy-nas-fnos 'aliyunpan quota; aliyunpan ls /'

# 列待看目录（等价于挂载点的 备份盘/Film and TV (aDrive)）
ssh -o BatchMode=yes sandy-nas-fnos 'aliyunpan ls "/Film and TV (aDrive)"'

# 删除某个云盘副本（归档校验通过之后）
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan rm \"/Film and TV (aDrive)/$NAME\""

# 复核删干净（应无输出）
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"/Film and TV (aDrive)\" | grep -F \"$NAME\""
```

要点：

- 云盘路径相对**备份盘根**，`/Film and TV (aDrive)/X` 等价于挂载点的 `备份盘/Film and TV (aDrive)/X`。资源库是另一个网盘，先 `aliyunpan drive` 切换。
- 删除走 API，比在挂载点上 `rm -rf` 大目录快得多，也不会留半删状态。
- 任意一台删完，两边挂载点同步消失（实测无延迟）。

## 6. 整理归档

顺序固定，前一步验证通过才做下一步。

### 6.0 归档前必须先提醒用户

动任何文件之前，先把下面几项发给用户并**等明确确认**（截图由用户自己完成，agent 不抽帧、不代做）：

- 主标识截图是否已全部完成？
- 这次要归档的条目清单（名称、大小、当前所在位置）。
- 计划执行的四步：搬到 TrueNAS → 校验 → 删阿里云盘副本 → 删广州副本。

用户没回确认之前不要执行第 6.1 步之后的任何写操作。

### 6.1 武汉待看 → TrueNAS（跨文件系统，先拷后删）

```bash
NAME="Some.Show.S01.1080p"
SRC="/vol2/1000/Backup/Film and TV (aDrive)/$NAME"
DST="/vol02/1000-0-8eb8a616/Film and TV"
ssh -o BatchMode=yes sandy-nas-fnos "rsync -a --info=progress2 \"$SRC\" \"$DST/\" && du -sb \"$SRC\" \"$DST/$NAME\""
```

两边字节数一致后，再 `rm -rf "$SRC"`。

### 6.2 删阿里云盘副本（用 aliyunpan 走 API，不是挂载点 rm）

```bash
[ -n "$NAME" ] || exit 1
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan rm \"/Film and TV (aDrive)/$NAME\""
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"/Film and TV (aDrive)\" | grep -F \"$NAME\"" || echo "已确认为空"
```

删除走 API 而不是挂载点 `rm -rf`；删完用第二条命令复核，有残留就不要继续下一步。

### 6.3 删广州 NAS 副本

```bash
ssh -o BatchMode=yes sony-memini-fnos "rm -rf \"/vol1/1000/Backup/Film and TV (aDrive)/$NAME\""
```

每次删除前，先 `ls -ld` 打印目标并让用户确认路径，尤其注意 `$NAME` 为空时会变成删整个目录——命令里加 `[ -n "$NAME" ] || exit 1` 守卫。

## 7. 故障与边界

- **TrueNAS SSH 不通**：不要试图开 SSH；文件操作统一从武汉 fnOS 走 CIFS 挂载点。
- **阿里云盘写入失败/只读**：检查挂载是否掉线（`mount | grep cloud-storage`），掉线时先在飞牛里重连云盘，不要反复重试覆盖。
- **广州盘将满**：先报剩余空间，让用户决定清理哪些旧片，禁止静默删除。
- **网络**：两站互通依赖现有隧道；`ssh sandy-nas-fnos` 超时先报告再重试一次，不要循环重连。

## 8. 完成标准

- 下载：任务 100%，给出落地路径。
- 转待看：武汉备份与阿里云盘条目数、字节数一致（云端本来就有同大小文件时跳过上传，只校验）。
- 取到广州：广州本地与阿里云盘字节数一致，剩余空间仍 >100G。
- 归档：`/vol02/1000-0-8eb8a616/Film and TV` 上字节数一致，源端已删，阿里云盘与广州均无残留。

## 9. 已确认事实

1. Transmission 密码已存 macOS 钥匙串（`transmission-rpc`，账号 `One_SONY`），脚本自动读取；`list` 已实测能列出全部任务。
2. 归档目标：`/vol02/1000-0-8eb8a616/Film and TV`；`/vol02/1002-0-ba62e9a2`（FAT 挂载）指向的是同一个目录。
3. 待看必须经阿里云盘中转，禁止武汉→广州直传（运营商上传风控）。
4. 主标识截图由用户手动完成，agent 不做抽帧；归档动作前必须先提醒用户确认。
5. `aliyunpan` v0.4.0 已通过官方 apt 源装在两台 NAS（`/usr/local/bin/aliyunpan`，`/usr/bin/aliyunpan` 为软链），账号 `One_SONY` 已验证可用；升级命令 `sudo apt update && sudo apt install --only-upgrade aliyunpan`。
6. 秒传实测（2026-10-20）：云盘已有的 193MB 文件经挂载点写入 2 秒、出向 0MB；云端没有的 100MB 新文件耗时 22 秒、出向约 107MB。`aliyunpan` 对照结果一致。

