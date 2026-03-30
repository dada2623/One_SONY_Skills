---
name: books-manager
description: Manage your Notion reading records database - track books, reading progress, and reading habits. Use when user wants to add or manage book records, track reading progress, or search books via Douban.
---

# books-manager

A focused wrapper around Notion API for managing your **reading records** database.

## Database ID

- **阅读记录**: `c71d68a42dba491aa04d682b43b1a93e`

## Setup

Ensure Notion API key is saved to `~/.config/notion/api_key` (Windows: `%USERPROFILE%\.config\notion\api_key`)

---

## 字段列表

| 字段名 | 类型 | 说明 |
|--------|------|------|
| 书名 | title | 书籍名称（必填） |
| 作者 | rich_text | 作者姓名 |
| 状态 | status | 阅读状态 |
| 类型 | multi_select | 书籍分类 |
| 阅读方式 | multi_select | 阅读方式 |
| 豆瓣评分 | number | 豆瓣评分 (0-10) |
| 豆瓣网址 | url | 豆瓣链接 |
| 当前页数 | number | 当前阅读页码 |
| 总页数 | number | 书籍总页数 |
| 开始日期 | date | 开始阅读日期 |
| 结束日期 | date | 读完日期 |
| 进度 | formula | 自动计算进度百分比 |
| 个人评分 | select | 1-5星评分 |
| 创建时间 | created_time | 自动生成 |

### 状态选项
- 想读
- 在读
- 已读完
- 放弃

### 类型选项
小说, 非小说, 自传, 传记, 推理, 幻想, 科幻, 历史, 爱情, 惊悚, 工具书, 诗歌, 画册, 冒险, 恐怖, 犯罪, 儿童, 经典, 哲学, 人类学, 政治, 畅销, 短篇集, 科普, 经济, 校园, 商业, 魔幻现实

### 阅读方式选项
Kindle, iPad, 手机, 电脑, 纸质书

### 个人评分选项
- ⭐⭐⭐⭐⭐
- ⭐⭐⭐⭐
- ⭐⭐⭐
- ⭐⭐
- ⭐

---

## 新建书籍规则

### 询问缺失信息
当用户新建书籍记录时，如果用户没有提供以下必要信息，应主动向用户询问：
- 书名（必填）
- 作者
- 阅读方式（实体书/电子书等）
- 状态（想读/在读/已读完等）

除非用户明确确认不需要添加该信息，否则应尽量以完整的信息进行添加。

### 豆瓣链接自动识别规则
当用户提供豆瓣读书链接（如 `https://book.douban.com/subject/xxxxx`）时，应自动从页面提取以下信息：

- **书名**：页面标题中的书籍名称
- **作者**：作者信息
- **类型**：书籍分类标签（匹配已有类型选项）
- **豆瓣评分**：页面上的评分数字
- **豆瓣网址**：用户提供的豆瓣链接

#### 示例：从豆瓣提取数据后创建记录
```javascript
// 用户说"我想读这本书 https://book.douban.com/subject/123456/"
// 页面显示：百年孤独，作者: 加西亚·马尔克斯，评分: 9.3
const bookData = {
  parent: { database_id: 'c71d68a42dba491aa04d682b43b1a93e' },
  properties: {
    "书名": { title: [{ text: { content: "百年孤独" } }] },
    "作者": { rich_text: [{ text: { content: "加西亚·马尔克斯" } }] },
    "豆瓣评分": { number: 9.3 },
    "豆瓣网址": { url: "https://book.douban.com/subject/123456/" },
    "状态": { status: { name: "想读" } }
  }
};
```

## 图书封面获取规则
当用户通过豆瓣链接添加书籍时，应获取图书封面图片，并添加为页面内容的图片块。

### 图片来源（按优先级尝试）

| 优先级 | 来源 | 适用场景 | 网址 |
|--------|------|----------|------|
| 1 | 微信读书 | 中文书籍（推荐） | `https://weread.qq.com/` |
| 2 | LibraryThing | 英文书籍、国际书籍 | `https://www.librarything.com/` |
| 3 | 豆瓣 | 备选（直接从豆瓣页面获取） | 豆瓣图书页面 |

### 操作步骤

#### 方法1：微信读书（推荐中文书）
1. 打开 `https://weread.qq.com/`
2. 搜索书名或 ISBN
3. 进入书籍详情页
4. 找到封面图片，右键复制图片地址

#### 方法2：LibraryThing
1. 打开 `https://www.librarything.com/`
2. 搜索 ISBN 或书名
3. 进入书籍详情页
4. 找到封面图片，右键复制图片地址

#### 方法3：豆瓣
1. 从豆瓣图书页面直接获取封面图片
2. 右键复制图片地址

### 添加图片块到 Notion
```javascript
const pageId = "页面ID";
const coverUrl = "封面图片URL";

const imageBlock = {
  object: "block",
  type: "image",
  image: {
    type: "external",
    external: { url: coverUrl }
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

**重要**：不要下载图片，直接使用图片 URL 链接，Notion 可以解析外部链接。

---

## 创建阅读记录示例

```javascript
const readingData = {
  parent: { database_id: 'c71d68a42dba491aa04d682b43b1a93e' },
  properties: {
    "书名": { title: [{ text: { content: "百年孤独" } }] },
    "作者": { rich_text: [{ text: { content: "加西亚·马尔克斯" } }] },
    "状态": { status: { name: "想读" } },
    "类型": { multi_select: [{ name: "小说" }] },
    "阅读方式": { multi_select: [{ name: "Kindle" }] },
    "总页数": { number: 360 }
  }
};
```

---

## 更新状态示例

> 把「百年孤独」标记为已读完

```javascript
const updateData = {
  properties: {
    "状态": { status: { name: "已读完" } },
    "结束日期": { date: { start: new Date().toISOString().split('T')[0] } }
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
# 列出阅读记录数据库的所有页面
DATABASE_ID=c71d68a42dba491aa04d682b43b1a93e ./skills/notion-utils/scripts/list-pages.sh

# 在阅读记录数据库创建页面
DATABASE_ID=c71d68a42dba491aa04d682b43b1a93e ./skills/notion-utils/scripts/create-page.sh "百年孤独"

# 更新页面状态
./skills/notion-utils/scripts/update-page.sh <page_id> '{"状态":"已读完"}'
```

**注意**: 路径基于 workspace 目录，skills 文件夹应位于 workspace 下。
