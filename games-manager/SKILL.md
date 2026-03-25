---
name: games-manager
description: Manage your Notion gaming records database - track games, platforms, playtime, and gaming progress. Use when user wants to add or manage game records. Automatically fetches MC scores from Metacritic and game images (Header, Capsule, Icon) from SteamGridDB.
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

### SteamGridDB 图片获取规则
当用户添加游戏时，应自动从 SteamGridDB 获取游戏相关图片，并嵌入到 Notion 页面中。

#### 图片类型
| 图片类型 | SteamGridDB 名称 | 用途 | Notion 位置 |
|----------|------------------|------|-------------|
| 封面图 | Header | 页面封面 | 页面 cover 属性 |
| 游戏内容图 | Capsule | 内容展示 | 页面内容图片块 |
| 图标 | Client Icon | 游戏图标 | 页面内容图片块 |

#### 操作步骤
1. **访问 SteamGridDB**
   - 打开 `https://www.steamgriddb.com/`
   - 搜索游戏名称

2. **进入资源页面**
   - 点击搜索结果中的游戏
   - 点击 "View original Steam assets"

3. **获取图片链接**
   - **Header**：找到 Header 图片，右键复制图片地址
   - **Capsule**：找到 Capsule 图片，右键复制图片地址
   - **Client Icon**：找到 Client Icon 图片，右键复制图片地址

4. **嵌入到 Notion**
   - **封面图**：设置页面 cover 属性
   - **游戏内容图和图标**：添加图片块到页面内容

**重要**：不要下载图片，直接使用图片 URL 链接，Notion 可以解析外部链接。

#### Notion API 示例

**设置页面封面（Header）**
```javascript
// 创建页面时设置封面
const pageData = {
  parent: { database_id: '941594b6504d45549070c02dd16da5c1' },
  cover: {
    type: "external",
    external: {
      url: "https://steamgriddb.com/image/xxx-header.png"
    }
  },
  properties: {
    "游戏名": { title: [{ text: { content: "塞尔达传说：王国之泪" } }] },
    // ... 其他属性
  }
};
```

**添加游戏内容图和设置页面图标**
```javascript
// 创建页面后，添加 Capsule 图片块并设置页面图标
const pageId = "新创建的页面ID";
const capsuleUrl = "https://steamgriddb.com/image/xxx-capsule.png";
// 图标链接示例（.ico 或 .png 格式）：
// - Steam: https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/406350/6b2a798c3a2eb75cd7bc7a7cfccdf154f40903ca.ico
// - SteamGridDB: https://cdn2.steamgriddb.com/icon/be89ed054d7e403ce222eca45bca7045/32/1024x1024.png
const iconUrl = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/406350/6b2a798c3a2eb75cd7bc7a7cfccdf154f40903ca.ico";

// 方法1: 在创建页面时直接设置 icon（推荐）
// icon 可以在创建页面时直接设置，无需额外请求
const pageData = {
  parent: { database_id: '941594b6504d45549070c02dd16da5c1' },
  icon: {
    type: "external",
    external: { url: iconUrl }
  },
  cover: {
    type: "external",
    external: { url: headerUrl }
  },
  properties: { ... }
};

// 方法2: 创建页面后更新图标（如果需要单独设置）
// PATCH /v1/pages/{page_id}
fetch(`https://api.notion.com/v1/pages/${pageId}`, {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${NOTION_API_KEY}`,
    'Notion-Version': '2025-09-03',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    icon: {
      type: "external",
      external: { url: iconUrl }
    }
  })
});

// 添加 Capsule 图片块到页面内容
const imageBlock = {
  object: "block",
  type: "image",
  image: {
    type: "external",
    external: { url: capsuleUrl }
  }
};

// PATCH /v1/blocks/{page_id}/children
fetch(`https://api.notion.com/v1/blocks/${pageId}/children`, {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${NOTION_API_KEY}`,
    'Notion-Version': '2025-09-03',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    children: [imageBlock]
  })
});
```

#### 完整流程示例
```javascript
// 用户说"添加游戏「塞尔达传说：王国之泪」"
// 1. 在 Metacritic 搜索获取 MC 评分和链接
// 2. 在 SteamGridDB 搜索获取 Header、Capsule、Client Icon 图片链接
// 3. 确认游戏类型
// 4. 创建 Notion 页面

// 步骤1: 创建页面（包含封面、图标和 MC 数据）
const pageData = {
  parent: { database_id: '941594b6504d45549070c02dd16da5c1' },
  icon: {
    type: "external",
    external: { url: "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/406350/6b2a798c3a2eb75cd7bc7a7cfccdf154f40903ca.ico" }
  },
  cover: {
    type: "external",
    external: { url: "https://steamgriddb.com/image/zelda-totk-header.png" }
  },
  properties: {
    "游戏名": { title: [{ text: { content: "塞尔达传说：王国之泪" } }] },
    "平台": { multi_select: [{ name: "Switch" }] },
    "类型": { multi_select: [{ name: "冒险" }, { name: "开放世界" }] },
    "状态": { status: { name: "想玩" } },
    "MC 评分": { number: 96 },
    "MC 网址": { url: "https://www.metacritic.com/game/the-legend-of-zelda-tears-of-the-kingdom/" }
  }
};

// 步骤2: 创建页面后，添加 Capsule 图片块到页面内容
const capsuleUrl = "https://steamgriddb.com/image/zelda-totk-capsule.png";
// 使用 PATCH /v1/blocks/{page_id}/children 添加图片块
```

#### 注意事项
- **Client Icon**：应设置为 Notion 页面图标，而不是添加为图片块
  - 推荐格式：`.ico` 或 `.png`
  - 来源示例：Steam CDN、SteamGridDB 等
- **Header**：设置为页面封面
- **Capsule**：添加为页面内容中的图片块
- 如果 SteamGridDB 找不到游戏，可以跳过图片步骤
- 如果只找到部分图片，只添加找到的部分
- 确保图片 URL 是可公开访问的直接链接

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
  'Notion-Version': '2025-09-03',
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
