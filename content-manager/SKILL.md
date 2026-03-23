---
name: content-manager
description: Manage your Notion content databases - track reading, gaming, and media consumption. Use when user wants to add or manage content items like books, games, movies, TV shows, anime, etc. Supports reading records, gaming records, and media/film records.
---

# content-manager

A focused wrapper around Notion API for managing your **content databases** - reading, gaming, and media consumption tracking.

## Database IDs

| Database | Database ID |
|----------|-------------|
| 阅读记录 | `c71d68a42dba491aa04d682b43b1a93e` |
| 游戏记录 | `941594b6504d45549070c02dd16da5c1` |
| 影视记录 | `8ad61aac3afd4101862e50986e36b9bc` |

## Setup

Ensure Notion API key is saved to `~/.config/notion/api_key` (Windows: `%USERPROFILE%\.config\notion\api_key`)

---

## 阅读记录数据库

### 字段列表

| 字段名 | 类型 | 说明 |
|--------|------|------|
| 书名 | title | 书籍名称（必填） |
| 作者 | rich_text | 作者姓名 |
| 状态 | status | 阅读状态 |
| 类型 | multi_select | 书籍载体类型 |
| 豆瓣评分 | number | 豆瓣评分 (0-10) |
| 豆瓣网址 | url | 豆瓣链接 |
| 当前页数 | number | 当前阅读页码 |
| 总页数 | number | 书籍总页数 |
| 开始日期 | date | 开始阅读日期 |
| 结束日期 | date | 读完日期 |
| 进度 | formula | 自动计算进度百分比 |
| 创建时间 | created_time | 自动生成 |

### 状态选项
- 想读
- 在读
- 已读完
- 放弃

### 类型选项
- 实体书
- 电子书
- 有声书
- Kindle
- 微信读书
- 电脑

### 创建阅读记录示例

```javascript
const readingData = {
  parent: { database_id: 'c71d68a42dba491aa04d682b43b1a93e' },
  properties: {
    "书名": { title: [{ text: { content: "百年孤独" } }] },
    "作者": { rich_text: [{ text: { content: "加西亚·马尔克斯" } }] },
    "状态": { status: { name: "想读" } },
    "类型": { multi_select: [{ name: "电子书" }] },
    "总页数": { number: 360 }
  }
};
```

---

## 游戏记录数据库

### 字段列表

| 字段名 | 类型 | 说明 |
|--------|------|------|
| 游戏名 | title | 游戏名称（必填） |
| 平台 | multi_select | 游戏平台（可多选） |
| 状态 | status | 游玩状态 |
| 个人评分 | select | 1-5星评分 |
| MC 评分 | number | Metacritic 评分 |
| MC网址 | url | Metacritic 链接 |
| 游戏时间 | number | 游玩时长（小时） |

### 状态选项
- 未开始
- 想玩
- 在玩
- 已通关
- 弃坑

### 平台选项
- PC_STEAM
- PC
- PC_XBOX
- PC_GOG
- PC_Epic
- PC_模拟器
- PC_学习版
- PC_BattleNet
- PC_Uplay
- PC_EA Play
- PS5
- PS4
- XBOX
- Switch
- Mac
- iOS
- Apple TV
- 云游戏

### 个人评分选项
- ⭐⭐⭐⭐⭐
- ⭐⭐⭐⭐
- ⭐⭐⭐
- ⭐⭐
- ⭐

### 创建游戏记录示例

```javascript
const gamingData = {
  parent: { database_id: '941594b6504d45549070c02dd16da5c1' },
  properties: {
    "游戏名": { title: [{ text: { content: "塞尔达传说：王国之泪" } }] },
    "平台": { multi_select: [{ name: "Switch" }] },
    "状态": { status: { name: "想玩" } }
  }
};
```

---

## 影视记录数据库

### 字段列表

| 字段名 | 类型 | 说明 |
|--------|------|------|
| 名称 | title | 影视名称（必填） |
| 类别 | select | 影视类型 |
| 状态 | status | 观看状态 |
| 个人评分 | select | 1-5星评分 |
| 豆瓣评分 | number | 豆瓣评分 (0-10) |
| 豆瓣网址 | url | 豆瓣链接 |

### 状态选项
- 想看
- 在看
- 已速看
- 看过
- 放弃

### 类别选项
- 国产电影
- 海外电影
- 国产剧
- 海外剧
- 韩剧
- 日剧
- 美剧
- 港剧
- 动画剧集
- 纪录片
- 综艺
- 脱口秀
- 儿童

### 个人评分选项
- ⭐⭐⭐⭐⭐
- ⭐⭐⭐⭐
- ⭐⭐⭐
- ⭐⭐
- ⭐

### 创建影视记录示例

```javascript
const mediaData = {
  parent: { database_id: '8ad61aac3afd4101862e50986e36b9bc' },
  properties: {
    "名称": { title: [{ text: { content: "奥本海默" } }] },
    "类别": { select: { name: "海外电影" } },
    "状态": { status: { name: "想看" } }
  }
};
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
- 获取 Data Source 结构: `GET /v1/data_sources/{data_source_id}`

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
| created_time | 自动生成，只读 |

---

## 使用场景示例

### 添加书籍
> 添加一本书「百年孤独」作者加西亚·马尔克斯，实体书

解析：
- 书名: 百年孤独
- 作者: 加西亚·马尔克斯
- 类型: 实体书
- 状态: 想读

### 添加游戏
> 添加游戏「黑神话：悟空」在 PC 上

解析：
- 游戏名: 黑神话：悟空
- 平台: PC_STEAM
- 状态: 想玩

### 添加影视
> 添加电影「流浪地球2」

解析：
- 名称: 流浪地球2
- 类别: 国产电影
- 状态: 想看

### 更新状态
> 把「百年孤独」标记为已读完

```javascript
const updateData = {
  properties: {
    "状态": { status: { name: "已读完" } },
    "结束日期": { date: { start: new Date().toISOString().split('T')[0] } }
  }
};
PATCH /v1/pages/{page_id}
```
