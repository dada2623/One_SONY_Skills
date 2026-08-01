---
name: games-manager
description: Manage your Notion gaming records database - track games, platforms, playtime, and gaming progress. Use when user wants to add or manage game records. Automatically fetches MC scores from Metacritic. Game images (Header, Capsule, Icon) are NOT auto-fetched from SteamGridDB - user will add them manually if needed.
triggers:
  - 游戏
  - 游戏记录
  - games-manager
  - 新建游戏
  - 添加游戏
tools_required:
  - filesystem
  - shell
  - web_fetch
---

# games-manager

A focused wrapper around Notion API for managing your **gaming records** database.

## Database ID

- **游戏记录**: `941594b6504d45549070c02dd16da5c1`

## Setup

Ensure Notion API key is saved to `~/.config/notion/api_key` (Windows: `%USERPROFILE%\.config\notion\api_key`)

---

## 字段列表

| 字段名 | 类型 | 说明 |
|--------|------|------|
| 游戏名 | title | 游戏名称（必填） |
| 平台 | multi_select | 游戏平台（可多选） |
| 类型 | multi_select | 游戏类型 |
| 状态 | status | 游玩状态 |
| 个人评分 | select | 1-5星评分 |
| MC 评分 | number | Metacritic 评分 |
| MC 网址 | url | Metacritic 链接 |
| 游戏时间 | number | 游玩时长（小时） |
| 最后运行日期 | date | 最后一次运行游戏的日期 |
| 创建时间 | created_time | 自动生成 |

### 状态选项
- 未开始
- 想玩
- 在玩
- 已通关
- 弃坑

### 平台选项
PC_STEAM, PC, PC_XBOX, PC_GOG, PC_Epic, PC_模拟器, PC_学习版, PC_BattleNet, PC_Uplay, PC_EA Play, PS5, PS4, XBOX, Switch, Mac, iOS, Apple TV, 云游戏

### 类型选项
体感, 休闲, 平台跳跃, 合作, 探索, 冒险, 肉鸽, 生存, 动作, MOBA, 开放世界, 银河恶魔城, 竞速, 策略, RPG, 模拟, 射击, 剧情, 格斗, 对战, 机甲, 运动, 恐怖, 解谜, 音乐, Galgame, 回合制, MMO, 派对, 塔防, 卡牌/棋盘, 共斗, 狼人杀, 种田

### 个人评分选项
- ⭐⭐⭐⭐⭐
- ⭐⭐⭐⭐
- ⭐⭐⭐
- ⭐⭐
- ⭐

---

## 核心原则

### ❌ 禁止事项
1. **严禁**从 SteamGridDB 自动获取图片 —— 用户明确表示放弃此要求，图片留空由用户自行补充
2. **严禁**在未查询现有页面数据的情况下，询问用户是否要补充平台、类型、评分等信息 —— 必须先查询页面现有属性，只有字段确实为空时才可提示

### ✅ 必须做
1. 新建/更新游戏前，**先查询数据库确认是否已存在同名游戏**，存在则更新而非新建
2. 更新现有页面时，**先 GET 页面属性**，检查哪些字段已有值，仅对空字段提示或补全
3. 更新页面前，**先把页面里已经有的信息列给用户看**，确认后再操作
4. Metacritic 评分和链接继续自动获取（这是有用的）

---

## 新建游戏规则

### 询问缺失信息
当用户新建游戏记录时，如果用户没有提供以下必要信息，应主动向用户询问：
- 游戏名（必填）
- 平台（PC/Switch/PS5等）
- 状态（想玩/在玩/已通关等）

除非用户明确确认不需要添加该信息，否则应尽量以完整的信息进行添加。

### 平台识别规则
当用户提及以下平台时，自动匹配对应选项：
- "Steam" 或 "PC Steam" → PC_STEAM
- "Epic" 或 "Epic Games" → PC_Epic
- "GOG" → PC_GOG
- "PlayStation 5" 或 "PS5" → PS5
- "PlayStation 4" 或 "PS4" → PS4
- "Switch" 或 "Nintendo Switch" → Switch
- "Xbox" → XBOX
- "iOS" 或 "iPhone" 或 "iPad" → iOS
- "Mac" 或 "macOS" → Mac

### 类型确认规则
由于游戏类型可能较多且复杂，添加游戏时：
1. 首先根据游戏名称自动推断类型（如"塞尔达"→冒险、开放世界）
2. 向用户确认推断的类型是否正确
3. 如果用户暂时不想确认，可以使用默认推断的类型
4. 用户可以随时回来补充或修改类型

**示例对话：**
> 用户：添加游戏「黑神话：悟空」
> Agent：我推断这个游戏的类型是：动作、冒险、RPG。是否正确？或者你想修改类型？
> 用户：正确 / 暂时跳过 / 改成动作、剧情、探索

---

### Metacritic 评分获取规则
当用户添加游戏时，应自动从 Metacritic 获取游戏评分和链接。

#### 操作步骤
1. **访问 Metacritic 搜索**
   - 打开 `https://www.metacritic.com/`
   - 使用搜索功能，输入游戏名称进行搜索

2. **选择正确结果**
   - 在搜索结果中找到匹配的游戏
   - 优先选择评分最高或最相关的版本

3. **获取数据**
   - **MC 评分**：页面上的 Metascore 数字
   - **MC 网址**：游戏详情页的完整 URL

#### 示例
```javascript
// 用户说"添加游戏「艾尔登法环」"
// 1. 在 Metacritic 搜索 "Elden Ring"
// 2. 找到游戏页面，获取评分 96
// 3. 获取链接 https://www.metacritic.com/game/elden-ring/

const gamingData = {
  parent: { database_id: '941594b6504d45549070c02dd16da5c1' },
  properties: {
    "游戏名": { title: [{ text: { content: "艾尔登法环" } }] },
    "MC 评分": { number: 96 },
    "MC 网址": { url: "https://www.metacritic.com/game/elden-ring/" },
    // ... 其他字段
  }
};
```

---

### 图片处理规则（已废弃）
**用户已明确放弃 SteamGridDB 自动获取图片的要求。**
- 封面图、图标、内容图均**留空**，不再自动获取
- 用户会自行在 Notion 中补充
- 如用户后续明确要求，可临时恢复，但默认不做

---

## 创建游戏记录示例

```javascript
const gamingData = {
  parent: { database_id: '941594b6504d45549070c02dd16da5c1' },
  properties: {
    "游戏名": { title: [{ text: { content: "塞尔达传说：王国之泪" } }] },
    "平台": { multi_select: [{ name: "Switch" }] },
    "类型": { multi_select: [{ name: "冒险" }, { name: "开放世界" }] },
    "状态": { status: { name: "想玩" } }
  }
};
```

---

## 更新状态示例

> 把「塞尔达传说：王国之泪」标记为已通关

```javascript
const updateData = {
  properties: {
    "状态": { status: { name: "已通关" } },
    "最后运行日期": { date: { start: new Date().toISOString().split('T')[0] } }
  }
};
// PATCH /v1/pages/{page_id}
```

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

---

## Scripts

通用脚本位于 `notion-utils` skill，请使用以下方式调用：

```bash
# 列出游戏记录数据库的所有页面
DATABASE_ID=941594b6504d45549070c02dd16da5c1 ./skills/notion-utils/scripts/list-pages.sh

# 在游戏记录数据库创建页面
DATABASE_ID=941594b6504d45549070c02dd16da5c1 ./skills/notion-utils/scripts/create-page.sh "塞尔达传说：王国之泪"

# 更新页面状态
./skills/notion-utils/scripts/update-page.sh <page_id> '{"状态":"已通关"}'
```

**注意**: 路径基于 workspace 目录，skills 文件夹应位于 workspace 下。