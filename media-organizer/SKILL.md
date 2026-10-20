---
name: media-organizer
description: 管理家庭影音流水线：PT 下载、阿里云盘中转待看、TrueNAS 归档与清理。Use when 用户要添加/查询/暂停 PT 下载任务、把下载完成的影视加入待看、上传或取回阿里云盘、把待看归档进 TrueNAS（归档前先提醒确认）、或清理云盘与本地副本。
---

# Media Organizer

## 0. 环境

主机与账号见 `~/.ssh/config`，设备与站点命名以 `~/.dsh/network/devices.md` 为准。**不要在 skill 或脚本里写死密码。**

站点代号只有两个，本 skill 不写地名：

- **SandY** = `192.168.50.0/24`：`sandy-nas-fnos`（飞牛，跑 Transmission）、`sandy-nas-truenas`（TrueNAS，仅经 CIFS 访问）、`vaio-deskstation-2023`（Mac mini）
- **租房** = `192.168.5.0/24`：`sony-memini-fnos`（飞牛，接收待看）、`vaio-deskstation-2024`（Mac mini，当前执行端）

路径（均已核实存在）：

| 用途 | 主机 | 路径 |
|---|---|---|
| 下载目录 | SandY 飞牛 `sandy-nas-fnos` | `/vol2/1000/Downloads` |
| 待看备份 | SandY 飞牛 `sandy-nas-fnos` | `/vol2/1000/Backup/Film and TV (aDrive)` |
| 待看（取回端） | 租房飞牛 `sony-memini-fnos` | `/vol1/1000/Backup/Film and TV (aDrive)` |
| TrueNAS 影音（**归档目标**） | TrueNAS，经 SandY 飞牛 CIFS 访问 | `/vol02/1000-0-8eb8a616/Film and TV` |
| TrueNAS 影音（同一目标的另一挂载点） | TrueNAS，经 SandY 飞牛 CIFS 访问 | `/vol02/1002-0-ba62e9a2`（FAT 共享根，挂载到的**就是**上面那个目录，别当成两个地方） |

Transmission：`http://192.168.50.87:9091/transmission/rpc`，用户名 `One_SONY`；密码在 macOS 钥匙串（`transmission-rpc`），脚本自动读取，**不要写进文件**。

阿里云盘管理 CLI（`aliyunpan` v0.4.0，**两台飞牛均已通过官方 apt 源装好**，同一账号 `One_SONY`）：

| 项 | 值 |
|---|---|
| 二进制 | `/usr/local/bin/aliyunpan`（`/usr/bin/aliyunpan` 是它的软链） |
| 配置 | `~/.config/aliyunpan/aliyunpan_config.json`（600，两台各一份，内容相同） |
| 默认网盘 | 备份盘；`aliyunpan drive` 可切到资源库，不在资源库里进行任何操作 |
| 云盘根 | 备份盘下的 `/Film and TV (aDrive)` |
| 已用配额 | 757 / 997 GB（76%，2026-10-20） |

**所有云盘操作统一用 `aliyunpan`**：上传、下载、删除、查配额、判断文件是否存在。

两台飞牛上确实还挂着 rclone/WebDAV 云盘目录（`/vol02/1000-1-…/备份盘/…`），但**本 skill 不使用它们**，原因是它不可信：目录缓存会让已删除的条目继续显示、新上传的目录半天不出现，甚至能 `ls` 出来却读成 `Input/output error`。它只适合你在 GUI 里手动拖文件；任何自动流程都不要碰。

## 1. 通用规则

- 全部操作走 `ssh <别名>`，命令加 `-o BatchMode=yes`，失败立刻报错而不是卡住。
- 路径含空格与括号，**每个路径都加双引号**。
- 删除前必须校验：目标存在、且**文件大小总和与文件数**一致；默认先 `--dry-run` 打印计划，用户确认后再执行。
- **校验不要用 `du -sb`**：目录本身的 stat size 随文件系统而变（ext4 / CIFS / rclone 挂载各不相同），实测同一部剧三个位置相差 672 字节，纯属目录条目的记账差异，会误报不一致。一律只统计普通文件：`find "$P" -type f -printf '%s\n' | awk '{s+=$1} END{printf "%.0f\n", s}'`。

- 在各节里统一用这个函数（先在本机定义一次，后面直接调用）：

```bash
sum() {
  local host="$1" path="$2" q
  q=$(printf '%q' "$path")
  ssh -o BatchMode=yes "$host" "find $q -type f -printf '%s\n' | awk '{s+=\$1} END{printf \"%.0f\n\", s}'"
}

# 用法：sum sandy-nas-fnos "/vol2/1000/Backup/Film and TV (aDrive)/$NAME"
# 返回 0 或空一般表示路径不存在，先用 test -e 确认
```
- 云盘侧的任何判断都以 `aliyunpan` 的输出为准（`ls` / `quota` / upload 日志），不要用飞牛的挂载点确认。
- 大文件先查剩余空间：租房飞牛只剩 ~214G，4K 原盘可能放不下，先报数再动手。
- **待看中转只能走阿里云盘**：不要为了省事从 SandY 飞牛直接 rsync 到租房飞牛 —— 家宽上传量过大会触发运营商风控。
- 云盘管理（列目录、删文件、查配额）一律在 NAS 上执行 `aliyunpan`，不走 Mac，也不用 FUSE 挂载点。
- `Downloads` 是**永久做种源**：只读用途，任何时候都不删、不移、不改名；Transmission 里的任务同样永不删除。归档和清理都不碰它们。
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

任务完成后**不要** `remove`，也不要在 `Downloads` 里做任何删除或移动——那里是永久做种源（见 6.4）。下一步只是把它**复制**出去。

## 3. 转待看（SandY 本地备份 + 上阿里云）

```bash
NAME="Some.Show.S01.1080p"
SRC="/vol2/1000/Downloads/$NAME"
BAK="/vol2/1000/Backup/Film and TV (aDrive)/$NAME"
```

**0) 预检**：云端是否已有同名条目（只看 API，不看挂载点）

```bash
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"/Film and TV (aDrive)/$NAME\""
```

- 已有、且报的总大小与本地一致 → 跳过上传，只做第 3 步校验
- 已有但大小不同 → 报给用户，不要盲目覆盖（可能是另一版本）
- 返回"指定目录不存在" → 直接上传；即便自己云盘没有，大概率仍会秒传（服务端全库按哈希匹配）
- 本地大小用 `sum sandy-nas-fnos "$SRC"`（按第 1 节定义）

**1) 本地留一份**（Downloads → Backup，同盘，秒级）

```bash
ssh -o BatchMode=yes sandy-nas-fnos "rsync -rlt --no-perms --no-owner --no-group --info=progress2 \"$SRC\" \"/vol2/1000/Backup/Film and TV (aDrive)/\""
```

**2) 上传到阿里云盘**：优先 `aliyunpan`，进度、续传、秒传结果都可见

```bash
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan upload \"$BAK\" \"/Film and TV (aDrive)\""

# 想看动态面板加 -ui；或在后台跑、用命令轮询输出看进度：
#   ↑ 12.30MB/34.00GB(0.04%) 3.2MB/s(3.1MB/s) in 4s, left 3h
```

大文件上传时，agent 应该把命令放到后台任务里，定期读取输出汇报百分比和速度，而不是干等；日志里的 `秒传成功` / `秒传失败，开始正常上传` 也要一并转述。

**3) 校验**：用 API 视角核对，**不要用挂载点**（新目录会被目录缓存挡住，见 3.2）

```bash
# 云端：名称、大小、条目数
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"/Film and TV (aDrive)/$NAME\""

# 本地：文件总字节 + 文件数
echo "本地 $(sum sandy-nas-fnos "$BAK")"
ssh -o BatchMode=yes sandy-nas-fnos "find \"$BAK\" -type f | wc -l"
```

判定标准：

- 日志出现 `秒传成功` → 服务端按内容哈希命中，内容一致性由服务端保证，只需核对条目数与大小。
- 日志是实传 → `aliyunpan` 上传后自带校验，同样核对条目数与大小即可。
- 云端条目数、总大小与本地一致就放行。


### 3.1 三条容易踩的坑

- **不要用 `du -sb` 校验**：目录自身的 stat size 随文件系统而变，实测同一部 Loki.S02 在 SandY 飞牛上是 36,519,754,132、在 TrueNAS 是 36,519,753,460，差的 672 字节全是目录条目；按文件求和两边都是 36,519,753,460。
- **rsync 不要用 `-a`**：`-a` 含 `-p -g -o`，源 `700:1001`、CIFS 目标 `777:1000`，每次都会刷一屏 `.f...p.....`，看着像没拷完。用 `-rlt --no-perms --no-owner --no-group`，实测差异行数为 0。
- **秒传按内容哈希在整个云盘里匹配，不限于自己的账号**：只要有人上传过同样的文件，哪怕自己的云盘里没有，也能命中且不走上传流量。PT 上的热门资源基本都会命中，所以“新片一定要实传”是错的，别拿它当预期。`aliyunpan upload` 会打印 `秒传成功` 或 `秒传失败，开始正常上传`，以日志为准。
- 实测对照：随机 100MB 文件（云盘里绝无仅有）实传 107MB；已存在的 193MB 文件 2 秒、出向 0MB。
- 真需要实传时，速度受 SandY 上行限制：20MB 约 34 秒（0.6MB/s 上下）。

### 3.2 为什么完全不用挂载点

飞牛的 rclone/WebDAV 云盘挂载（`/vol02/1000-1-…/备份盘/…`）看起来像个普通目录，实际不可信，两个会话里各撞到一种表现：

- **新内容不出现**：`aliyunpan upload` 建好目录后，4 分钟过去挂载点仍然 `No such file or directory`。
- **旧内容不消失**：云端已删除的条目，挂载点还留着同名目录；真去读里面的文件，直接 `Input/output error`，因为根本没有数据可读。租房那台的挂载点倒是已经没了，两台不同步。

两种情况都是目录缓存导致的，跟数据是否真的在云上没有关系。判断存在性、大小、是否上传完成，一律以 `aliyunpan ls` 为准；挂载点只留给 GUI 手动拖拽，任何自动流程都不使用。

## 4. 取回租房（本地落盘）

```bash
NAME="Some.Show.S01.1080p"
TMP="/vol1/1000/Temp"
DST="/vol1/1000/Backup/Film and TV (aDrive)"
ssh -o BatchMode=yes sony-memini-fnos "df -h /vol1 | tail -1"
ssh -o BatchMode=yes sony-memini-fnos "aliyunpan config set -savedir \"$TMP\" && aliyunpan download \"/Film and TV (aDrive)/$NAME\""
# 注意：文件落在 <savedir>/<账号uid>/ 下，要挪到待看目录
ssh -o BatchMode=yes sony-memini-fnos "mv \"$TMP/0ffece242926461289eb6640d49f6fdc/$NAME\" \"$DST/\""
```

先确认剩余空间 > 文件大小 ×1.1。若不足，提示用户清理或改用流式播放，不要写满 /vol1（与系统同盘）。

**速度实测（2026-10-20，同一个 20MB 文件，租房飞牛）**：

| 路径 | 耗时 | 折算 |
|---|---|---|
| `aliyunpan download` | 71s | ≈280 KB/s |
| 挂载点 `cp` | 206s | ≈97 KB/s |

两条都被第三方接口限速，`aliyunpan` 快约 3 倍，所以**下载统一走 `aliyunpan`**。代价是要接受这个速度：15GB 的单集按 280KB/s 约 15 小时，排期时留足时间，别按分钟级预期。

## 5. 云盘管理（在 NAS 上跑）

两台飞牛都装了 apt 版 `aliyunpan`（见第 0 节），管理类操作统一 SSH 到 NAS 执行，不要让数据绕道 Mac。

```bash
# 查配额 / 列云盘根
ssh -o BatchMode=yes sandy-nas-fnos 'aliyunpan quota; aliyunpan ls /'

# 列待看目录（云盘路径相对备份盘根）
ssh -o BatchMode=yes sandy-nas-fnos 'aliyunpan ls "/Film and TV (aDrive)"'

# 删除某个云盘副本（归档校验通过之后）
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan rm \"/Film and TV (aDrive)/$NAME\""

# 复核删干净（应无输出）
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"/Film and TV (aDrive)\" | grep -F \"$NAME\""
```

要点：

- 云盘路径相对**备份盘根**，`/Film and TV (aDrive)/X` 就是完整路径。资源库是另一个网盘，先 `aliyunpan drive` 切换。
- 删除走 API，比在 FUSE 挂载点上 `rm -rf` 大目录快得多，也不会留半删状态。
- 任意一台删完，另一台用 `aliyunpan ls` 复查即为准；挂载点可能还留着缓存残影，不要被它误导。

## 6. 整理归档

顺序固定，前一步验证通过才做下一步。

### 6.0 归档前必须先提醒用户

动任何文件之前，先把下面几项发给用户并**等明确确认**（截图由用户自己完成，agent 不抽帧、不代做）：

- 主标识截图是否已全部完成？
- 这次要归档的条目清单（名称、大小、当前所在位置）。
- 计划执行的四步：搬到 TrueNAS → 校验 → 删阿里云盘副本 → 删租房副本。
- 明确告诉用户：`Downloads` 里的原件不在本次范围内，会继续做种（见 6.4）。

用户没回确认之前不要执行第 6.1 步之后的任何写操作。

### 6.1 SandY 待看 → TrueNAS（跨文件系统，先拷后删）

```bash
NAME="Some.Show.S01.1080p"
SRC="/vol2/1000/Backup/Film and TV (aDrive)/$NAME"
DST="/vol02/1000-0-8eb8a616/Film and TV"

# 1) 预演：加 -n 看还有没有真实差异（权限类差异已被 --no-perms 消除，输出应为空）
ssh -o BatchMode=yes sandy-nas-fnos "rsync -rltn --no-perms --no-owner --no-group --itemize-changes \"$SRC/\" \"$DST/$NAME/\" | head"

# 2) 拷贝
ssh -o BatchMode=yes sandy-nas-fnos "rsync -rlt --no-perms --no-owner --no-group --info=progress2 \"$SRC\" \"$DST/\""

# 3) 校验：普通文件总字节 + 文件数
echo "源 $(sum sandy-nas-fnos "$SRC") / 目标 $(sum sandy-nas-fnos "$DST/$NAME")"
ssh -o BatchMode=yes sandy-nas-fnos "find \"$SRC\" -type f | wc -l; find \"$DST/$NAME\" -type f | wc -l"
```

两个数字都一致后，再 `rm -rf "$SRC"`。预演若有真实差异（`.f+++++++++`、`>f.st......` 之类），说明没拷全，此时不能删源。

### 6.2 删阿里云盘副本（用 aliyunpan 走 API，不是挂载点 rm）

```bash
[ -n "$NAME" ] || exit 1
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan rm \"/Film and TV (aDrive)/$NAME\""
ssh -o BatchMode=yes sandy-nas-fnos "aliyunpan ls \"/Film and TV (aDrive)\" | grep -F \"$NAME\"" || echo "已确认为空"
```

删除走 API 而不是挂载点 `rm -rf`；删完用第二条命令复核，有残留就不要继续下一步。

### 6.3 删租房飞牛副本

```bash
[ -n "$NAME" ] || exit 1
ssh -o BatchMode=yes sony-memini-fnos "rm -rf \"/vol1/1000/Backup/Film and TV (aDrive)/$NAME\""
```

每次删除前，先 `ls -ld` 打印目标并让用户确认路径，尤其注意 `$NAME` 为空时会变成删整个目录——命令里加 `[ -n "$NAME" ] || exit 1` 守卫。

### 6.4 下载目录原件：保留，不清理

`/vol2/1000/Downloads/$NAME` 在归档完成后**继续保持原样**，它是 Transmission 的做种源：

- 不 `rm`、不 `mv`、不改名；Transmission 任务也不 `remove`。
- 归档的四步只处理 `Backup/…`、云盘、租房三处，`Downloads` 不在清理范围内。
- 磁盘紧张时先报给用户，由用户决定，**不要自行清理做种文件**，否则任务立刻变成缺文件的红种。

要看某部片子是否下载完成，查 Transmission 的进度就够了；确认 100% 后再从 `Downloads` **复制**出去，原件留在原地继续做种。

## 7. 故障与边界

- **TrueNAS SSH 不通**：不要试图开 SSH；文件操作统一从 SandY 飞牛走 CIFS 挂载点。
- **云盘操作报错/看不到文件**：先 `aliyunpan quota` 确认登录态，再 `aliyunpan ls` 确认真实路径；不要拿挂载点的结果判断（缓存会骗人）。
- **租房盘将满**：先报剩余空间，让用户决定清理哪些旧片，禁止静默删除。
- **网络**：两站互通依赖现有隧道；`ssh sandy-nas-fnos` 超时先报告再重试一次，不要循环重连。

## 8. 完成标准

- 下载：任务 100%，给出落地路径。
- 转待看：SandY 备份与阿里云盘**普通文件总字节、文件数**一致（云端已有同内容时跳过上传，只校验）。
- 取回租房：租房本地与云盘**文件总字节、文件数**一致，剩余空间仍 >100G。
- 归档：`/vol02/1000-0-8eb8a616/Film and TV` 上文件总字节、文件数一致，`Backup/…` 源端已删，阿里云盘与租房均无残留；`Downloads` 里的原件保持不动。

校验一律用 `find -type f -printf '%s\n' | awk` 求和，不用 `du -sb`，也不比较权限/属主。

## 9. 已确认事实

1. Transmission 密码已存 macOS 钥匙串（`transmission-rpc`，账号 `One_SONY`），脚本自动读取；`list` 已实测能列出全部任务。
2. 归档目标：`/vol02/1000-0-8eb8a616/Film and TV`；`/vol02/1002-0-ba62e9a2`（FAT 挂载）指向的是同一个目录。
3. 待看必须经阿里云盘中转，禁止 SandY→租房直传（运营商上传风控）。
4. 主标识截图由用户手动完成，agent 不做抽帧；归档动作前必须先提醒用户确认。
5. `aliyunpan` v0.4.0 已通过官方 apt 源装在两台飞牛（`/usr/local/bin/aliyunpan`，`/usr/bin/aliyunpan` 为软链），账号 `One_SONY` 已验证可用；升级命令 `sudo apt update && sudo apt install --only-upgrade aliyunpan`。
6. 秒传按内容哈希在**整个云盘**匹配，别人上传过同样文件也算，不限于自己账号；热门 PT 资源基本必中，不能预设“新片一定实传”。实测：随机 100MB 文件实传 107MB（必然不命中）；40.98GB 的 Spider-Man 走 `aliyunpan upload` 全部秒传、0B。
7. `du -sb` 会在跨文件系统时误报（实测 Loki.S02：SandY 36,519,754,132 / TrueNAS 36,519,753,460，差 672 字节全是目录条目）。改用 `find -type f -printf '%s\n' | awk` 求和后两边都是 36,519,753,460。
8. `rsync -a` 在 CIFS 目标上会一直报 `.f...p.....`（源 700:1001，目标 777:1000）。换成 `-rlt --no-perms --no-owner --no-group` 后同一目录差异行数为 0。
9. 传输速度（20MB 实测，未命中秒传的情况）：上传 34s（受 SandY 上行限制）；下载 `aliyunpan` 71s（≈280KB/s），挂载点 `cp` 206s（≈97KB/s）。两条云盘传输统一用 `aliyunpan`。
10. `Downloads` 里的文件是永久做种源，Transmission 任务（如 Loki 的 1451/1452）不删、目录不动；看过不等于要清掉。
11. 真实资源验证过秒传：40.98GB 的 Spider-Man.No.Way.Home（3 个文件）全部 `秒传成功`，数据总量 0B；耗时 3 分 22 秒全部花在本地算 SHA1（约 200MB/s），不是网络。
12. 飞牛的云盘挂载点不可信：已删除的条目会因目录缓存继续显示，读进去直接 `Input/output error`；新上传的目录也可能几十分钟不出现。所有判断改用 `aliyunpan ls`。
13. `aliyunpan download` 会把文件存到 `<savedir>/<账号uid>/` 下（uid `0ffece242926461289eb6640d49f6fdc`），不会直接落在 savedir 根，取件时要多一步 `mv`。

