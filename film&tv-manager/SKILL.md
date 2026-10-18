---
name: film-tv-manager
description: Manage your Notion media records database - track movies, TV shows, anime, and viewing habits. Use when user wants to add or manage film/TV records, track viewing progress, or search media via Douban. Includes the Douban-page extraction rules (browser render, wait 2-3s, strip year/更多...) and the two-stage create-then-update write flow.
triggers:
  - 影视
  - 电影
  - 剧集
  - film-tv-manager
  - 新建影视
tools_required:
  - filesystem
  - shell
  - web_fetch
---

# film-tv-manager

A focused wrapper around Notion API for managing your **media/film records** database.

## Database ID

- **影视记录**: `8ad61aac3afd4101862e50986e36b9bc`

## Setup

Ensure Notion API key is saved to `~/.config/notion/api_key` (Windows: `%USERPROFILE%\.config\notion\api_key`)

---

## 字段列表

| 字段名 | 类型 | 说明 |
|--------|------|------|
| 名称 | title | 影视名称（必填） |
| 导演 | rich_text | 导演姓名 |
| 类别 | select | 影视类型 |
| 类型 | multi_select | 影视细分类型 |
| 进行状态 | status | 观看状态 |
| 个人评分 | select | 1-5星评分 |
| 豆瓣评分 | number | 豆瓣评分 (0-10) |
| 豆瓣网址 | url | 豆瓣链接 |
| 观看方式 | multi_select | 观看方式（整体覆盖，追加需先读原值合并，见下文） |
| 观看次数 | number | 整数；默认值规则见下文 |
| 结束日期 | date | 看完日期（YYYY-MM-DD） |
| 创建时间 / 上次编辑时间 | created_time / last_edited_time | 只读，自动生成，不要在 payload 里传 |

### 状态选项
- 想看
- 在看
- 已速看
- 看过
- 放弃

### 类别选项
国产电影, 海外电影, 国产剧, 海外剧, 韩剧, 日剧, 美剧, 港剧, 动画剧集, 纪录片, 综艺, 脱口秀, 儿童

### 类型选项
喜剧, 剧情, 动画, 冒险, 科幻, 动作, 奇幻, 爱情, 运动, 灾难, 医疗, 悬疑, 犯罪, 传记, 历史, 音乐, 家庭, 纪实, 战争, 古装, 歌舞, 恐怖, 惊悚, 短片, 小说改编, 游戏改编, 武侠, 真人秀, 儿童, 自然, 美食

### 观看方式选项
投影, 显示器, 电影院, 电视, 移动设备

当用户提及通过以下方式观看时，请自动归类为"移动设备"：
- 平板：iPad、Android 平板等
- 手机：智能手机观看
- 其他移动便携设备

### 个人评分选项
- ⭐⭐⭐⭐⭐
- ⭐⭐⭐⭐
- ⭐⭐⭐
- ⭐⭐
- ⭐

---

## 核心原则

### ❌ 禁止事项
1. **严禁**在未查询数据库的情况下直接新建页面 —— 必须先查询数据库确认是否已存在同名影视，存在则更新而非新建
2. **严禁**在未获取页面现有属性的情况下，询问用户是否要补充类型、导演、评分、观看方式等信息 —— 必须先 GET 页面属性，检查哪些字段已有值，只有字段确实为空时才可提示
3. **严禁**更新页面时不先把现有信息列给用户看 —— 更新前必须先展示页面当前已有的所有字段值
4. **严禁**更新 `观看方式`（multi_select）时不读原值直接传新值 —— multi_select 是整体覆盖，未列出的旧值会被抹掉；追加本次设备必须先 GET 原值合并传入

### ✅ 必须做
1. 新建/更新影视前，**先查询数据库确认是否已存在同名影视**，存在则更新而非新建
2. 更新现有页面时，**先 GET 页面属性**，检查哪些字段已有值，仅对空字段提示或补全
3. 更新前**必须 GET 页面属性确认每个字段的 type**，再按类型构造 payload（multi_select 必须传对象数组 `[{"name": "选项"}]`，不能传字符串数组）
4. 更新页面前，**先把页面里已经有的信息列给用户看**，确认后再操作
5. 更新完成后，**检查「个人评分」「观看方式」等字段是否为空**，为空则提醒用户补全
6. 豆瓣链接自动识别和评分获取继续保留（这是有用的）
7. 封面不需要自动获取：**不要**自动从 Trakt.tv、SteamGridDB 等网站取图写入页面，封面由用户手动添加

---

## 标准操作流程（四步，缺一不可）

1. **查重**：按 `名称` 的 title contains 查询数据库，命中则走更新，未命中才新建。命中多条时人工核对全名（如「洛基 第一季」vs「洛基 第二季」），别把续季更新到同一页
2. **读现状**：GET 页面属性，把已有字段值逐条列给用户看，并确认每个字段的 type
3. **构造 payload 并落库**：写入临时 JSON 文件（避免 shell 转义），用 `update-page.sh` 更新
4. **回读验证 + 收尾**：PATCH 的响应体本身就是更新后的完整属性，可直接核对关键字段；检查 `个人评分`、`观看方式` 等是否为空，空则提醒用户补全

### 查重命令示例

```bash
SCRIPT_DIR="${DSH_HOME:-$HOME/.dsh}/skills/notion-utils"
cd "$SCRIPT_DIR"
DB=8ad61aac3afd4101862e50986e36b9bc

API_KEY=$(cat ~/.config/notion/api_key)
curl -s -X POST "https://api.notion.com/v1/databases/$DB/query" \
  -H "Authorization: Bearer $API_KEY" -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"filter":{"property":"名称","title":{"contains":"洛基"}},"page_size":20}' | jq -r \
  '.results[] | [.id, (.properties.名称.title[0].plain_text // "")] | @tsv'
```

## 场景 → 标准动作

| 场景 | 必须做的改动 |
|------|--------------|
| 首次记录 | 查重 → 建页（只写 title）→ `update-page.sh` 补齐其余字段 |
| 重看一遍 | 观看次数 **+1**；结束日期 → 今天；状态保持 `看过`；观看方式**追加**本次设备（先读原值合并，不是替换） |
| 补全空字段 | 先 GET 看哪些为空，只补空值，已有值不动 |
| 改评分 | 只改 `个人评分`（1–5 星），不改豆瓣评分 |
| 状态推进 | 想看 → 在看 → 看过；同步观看次数默认值 |

---

## 新建影视规则

### 名称格式规则
- 影视名称**使用豆瓣网页上显示的标题**（`h1` 去掉 `span.year` 年份徽标，通常是「中文名 + 空格 + 英文原名」），作为数据库主键
- 示例：豆瓣 `h1` 显示 `蜘蛛侠：崭新之日 Spider-Man: Brand New Day (2026)`，其中 `(2026)` 在 `span.year` 里 → 名称填 `蜘蛛侠：崭新之日 Spider-Man: Brand New Day`
- 豆瓣 API 的 `title` 字段只是中文名（不带外文原名），**不要**用它替代网页显示标题
- 渲染后读空时**不要**猜名称、也不要判定条目不存在：重读一次，仍为空才回报渲染失败

### 导演字段规则
- 只取豆瓣 `#info` 里**可见**的导演姓名，多位用 `、` 连接
- **去掉**末尾的「更多...」和任何占位省略号；不要把 `/` 直接留在字段里
- 示例：豆瓣显示 `导演: 佐藤卓哉 / 滨崎博嗣 / 小林智树 / 立川让 / 小泽一浩 / 更多...` → 存 `佐藤卓哉、滨崎博嗣、小林智树、立川让、小泽一浩`
- 若发现库里旧条目是本规则之前的脏数据（`/` 分隔 + 「更多...」尾巴），顺手按本规则改正

### 询问缺失信息
当用户新建影视记录时，如果用户没有提供以下必要信息，应主动向用户询问：
- 名称（必填）
- 类别（国产电影/海外电影/国产剧等）
- 进行状态（想看/在看/看过等）

除非用户明确确认不需要添加该信息，否则应尽量以完整的信息进行添加。

### 观看次数默认值规则
- 进行状态为"想看"、"在看"或"放弃"时：观看次数 = 0
- 进行状态为"已速看"或"看过"时：观看次数 = 1

### 豆瓣链接自动识别规则
当用户提供豆瓣电影链接（如 `https://movie.douban.com/subject/xxxxx`）时，应自动从页面提取以下信息。

#### 取数方式（重要：只认浏览器渲染后的 DOM）
豆瓣的 `h1`、`#info`、`[property="v:average"]` 都是前端渲染出来的，**页面打开瞬间读是空的**。

- **必须**用浏览器加载 `https://movie.douban.com/subject/<id>/`，**等 2–3 秒**渲染完成后再读 DOM
- 读到的值为空（如 `NO_H1`、评分空串、`#info` 只有「载入中…」）时，**重读一次**再判定
- **不要把 `web_extract` / 服务端抓取当取数入口**：桌面页和 `m.douban.com` 移动页都只会返回「载入中…」，拿不到真实数据
- 一次读空**不等于**条目不存在、更不允许凭猜写名称；只有重读仍为空才回报「页面未能渲染」并让用户确认链接或稍后重试

- **名称**：页面 `h1` 文本，**去掉 `span.year`**（年份徽标），剩下的才是「中文名 + 空格 + 外文原名」
- **导演**：`#info` 里的导演信息（如"导演: 亚伦·霍瓦斯 / 迈克尔·杰勒尼克"）
  - 多位导演用 `/` 分隔，只取可见姓名，**去掉末尾「更多...」**
  - 存储格式：将多位导演用 `、` 连接存入 rich_text 字段
- **类型**：类型标签（如"喜剧 / 爱情 / 科幻"）
  - 按 `/` 分隔，去除首尾空格
  - 匹配已有的类型选项
- **豆瓣评分**：`[property="v:average"]` 的数字
- **豆瓣网址**：用户提供的豆瓣链接

#### 示例：从豆瓣提取数据后创建记录
```javascript
// 用户说"我看过这个 https://movie.douban.com/subject/25845392/"
// 页面显示：超级马里奥兄弟大电影 The Super Mario Bros. Movie (2023)，导演: 亚伦·霍瓦斯 / 迈克尔·杰勒尼克，类型: 喜剧 / 爱情 / 科幻 / 动画 / 奇幻 / 冒险，评分: 7.8
const mediaData = {
  parent: { database_id: '8ad61aac3afd4101862e50986e36b9bc' },
  properties: {
    "名称": { title: [{ text: { content: "超级马里奥兄弟大电影 The Super Mario Bros. Movie" } }] },
    "导演": { rich_text: [{ text: { content: "亚伦·霍瓦斯、迈克尔·杰勒尼克" } }] },
    "类型": { multi_select: [
      { name: "喜剧" }, { name: "爱情" }, { name: "科幻" },
      { name: "动画" }, { name: "奇幻" }, { name: "冒险" }
    ]},
    "豆瓣评分": { number: 7.8 },
    "豆瓣网址": { url: "https://movie.douban.com/subject/25845392/" },
    "进行状态": { status: { name: "看过" } },
    "观看次数": { number: 1 }
  }
};
```

---

### 封面规则
不需要自动获取封面：**不要**自动从 Trakt.tv、SteamGridDB 等网站取图写入页面，封面由用户手动添加。

---

## 创建影视记录示例

```javascript
const mediaData = {
  parent: { database_id: '8ad61aac3afd4101862e50986e36b9bc' },
  properties: {
    "名称": { title: [{ text: { content: "奥本海默" } }] },
    "类别": { select: { name: "海外电影" } },
    "进行状态": { status: { name: "想看" } }
  }
};
```

---

## 更新状态示例

> 把「奥本海默」标记为看过

```javascript
const updateData = {
  properties: {
    "进行状态": { status: { name: "看过" } },
    "观看次数": { number: 1 },
    "结束日期": { date: { start: new Date().toISOString().split('T')[0] } }
  }
};
// PATCH /v1/pages/{page_id}
```

### multi_select 更新示例

> 更新观看方式（multi_select 字段）

```javascript
const updateData = {
  properties: {
    "观看方式": { multi_select: [{ name: "电视" }, { name: "投影" }] }
  }
};
// PATCH /v1/pages/{page_id}
```

**注意**：Notion API 要求 multi_select 传**对象数组** `[{"name": "电视"}]`，不能传字符串数组 `["电视"]`。使用 `update-page.sh` 时直接传 `{"观看方式": ["电视"]}` 即可，脚本会自动完成转换。

**⚠️ multi_select 是整体覆盖**：传 `["电视", "投影"]` 会把未列出的旧值**全部抹掉**。追加观看方式时必须先 GET 原值、合并后一起传（如原为 `显示器`，本次又用了电视 → 传 `["显示器", "电视"]`）。

**省略 key = 不修改，不是清空**：`update-page.sh` 只提交 payload 里出现的字段，无法靠省略把字段改空；要清空需显式传空值。

---

## API 使用说明

### Headers
```javascript
{
  'Authorization': `Bearer ${NOTION_API_KEY}`,
  'Notion-Version': '2022-06-28',
  'Content-Type': 'application/json'
}
```

**`Notion-Version` 固定用 `2022-06-28`**（`common.sh` 已内置），不要手改成其他版本——如 `2024-02-28` 会被 API 拒绝并返回允许值清单。

### 常用端点
- 创建页面: `POST /v1/pages`
- 更新页面: `PATCH /v1/pages/{page_id}`
- 查询数据库: `POST /v1/databases/{database_id}/query`
- 获取数据库结构: `GET /v1/databases/{database_id}`

### 字段类型对照表

| Notion 类型 | JavaScript 格式 |
|-------------|-----------------|
| title | `{ title: [{ text: { content: "..." } }] }` |
| rich_text | `{ rich_text: [{ text: { content: "..." } }] }` |
| select | `{ select: { name: "Option" } }` |
| multi_select | `{ multi_select: [{ name: "A" }, { name: "B" }] }` |
| status | `{ status: { name: "Option" } }` |
| date | `{ date: { start: "2024-01-15" } }` |
| number | `{ number: 5 }` |
| url | `{ url: "https://..." }` |

**注意**：`multi_select` 必须传对象数组 `[{"name": "A"}]`，不能传字符串数组。

---

## Scripts

通用脚本位于 `notion-utils` skill。DSH 环境下目录为 `~/.dsh/skills/notion-utils/scripts/`（可用 `DSH_HOME` 覆盖根目录）；源仓库中为仓库根目录下 `notion-utils/scripts/`。

**一律用 `bash ./scripts/xxx.sh` 调用**：即使副本带可执行位，用 `bash` 调用也最稳；若遇到 `Permission denied`（某些安装副本权限为 `644`），先跑一次 `chmod +x scripts/*.sh` 再继续。

```bash
SCRIPT_DIR="${DSH_HOME:-$HOME/.dsh}/skills/notion-utils"
cd "$SCRIPT_DIR"
DB=8ad61aac3afd4101862e50986e36b9bc

# 列出影视记录数据库的所有页面
DATABASE_ID=$DB bash ./scripts/list-pages.sh

# 在影视记录数据库创建页面（两段式第一步：只写 title）
DATABASE_ID=$DB bash ./scripts/create-page.sh "洛基 第一季 Loki Season 1"

# 读取页面属性与内容
bash ./scripts/get-page.sh <page_id>

# 更新页面（推荐：JSON 文件方式，避免 shell 转义；multi_select 传字符串数组即可，脚本自动转换）
cat > /tmp/updates.json <<'EOF'
{"进行状态":"看过","观看方式":["显示器","电视"],"个人评分":"⭐⭐⭐⭐","观看次数":1,"结束日期":"2026-08-06"}
EOF
bash ./scripts/update-page.sh <page_id> /tmp/updates.json
```

**新建时的两段式**：`create-page.sh` 只写 title，其余字段（类别、状态、导演、类型、评分、观看方式、观看次数、结束日期）要紧接着跑一次 `update-page.sh` 补齐。

**省略 key = 不修改，不是清空**：`update-page.sh` 只提交 payload 里出现的字段；无法靠省略把字段改空，要清空需显式传空值。

**回读验证**：`update-page.sh` 成功后打印的 PATCH 响应体就是更新后的完整属性，可直接当回读证据核对。

---

## 完成前校验清单

- [ ] 库里没有重复页（同片同季只有一条）
- [ ] `名称` 是豆瓣 h1 全名（中文 + 空格 + 英文原名），已去掉 `span.year` 年份、没有用 API 的纯中文 title
- [ ] `导演` 用 `、` 连接、已去掉「更多...」，没有残留 `/` 分隔
- [ ] 豆瓣数据来自浏览器渲染后的 DOM（等待 2–3 秒），不是 `web_extract` 的「载入中…」
- [ ] 新建走完了两段式：`create-page.sh` 写 title 后紧接 `update-page.sh` 补齐其余字段
- [ ] `观看次数` 与 `进行状态` 符合默认值规则（重看已 +1）
- [ ] `结束日期` = 实际看完当天（YYYY-MM-DD）
- [ ] `观看方式` 保留了历史值，本次设备已追加
- [ ] `类别` / `类型` 用的是库里已有选项，没有新造选项
- [ ] 写后回读确认落库成功
- [ ] 空字段（个人评分、观看方式等）已提醒用户补全
