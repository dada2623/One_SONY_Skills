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
| 类型 | multi_select | 游戏类型 |
| 状态 | status | 游玩状态 |
| 个人评分 | select | 1-5星评分 |
| MC 评分 | number | Metacritic 评分 |
| MC网址 | url | Metacritic 链接 |
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
| 导演 | rich_text | 导演姓名 |
| 类别 | select | 影视类型 |
| 类型 | multi_select | 影视细分类型 |
| 进行状态 | status | 观看状态 |
| 个人评分 | select | 1-5星评分 |
| 豆瓣评分 | number | 豆瓣评分 (0-10) |
| 豆瓣网址 | url | 豆瓣链接 |
| 观看方式 | multi_select | 观看方式 |
| 观看次数 | number | 观看次数 |
| 结束日期 | date | 看完日期 |
| 创建时间 | created_time | 自动生成 |

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

### 创建影视记录示例

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

## 新建项目规则

### 询问缺失信息
当用户新建任何类型的内容项目时，如果用户没有提供以下必要信息，应主动向用户询问：
- 必填字段（如书名、游戏名、影视名称等标题字段）
- 类别（如阅读类型的实体书/电子书、游戏平台、影视类别等）
- 状态（如想读、在读、已读完等）

除非用户明确确认不需要添加该信息，否则应尽量以完整的信息进行添加。如果用户不确定某个字段的值，可以提供合理的默认值供用户确认。

### 观看次数默认值规则
对于影视记录，观看次数字段的默认值设置规则如下：
- 进行状态为"想看"、"在看"或"放弃"时：观看次数 = 0
- 进行状态为"已速看"或"看过"时：观看次数 = 1

### 豆瓣链接自动识别规则
当用户提供豆瓣链接（如 `https://movie.douban.com/subject/xxxxx` 或 `https://book.douban.com/subject/xxxxx`）时，应自动从页面提取以下信息并填充到对应字段：

#### 影视记录（豆瓣电影）
从豆瓣电影页面提取：
- **名称**：页面标题中的影视名称
- **导演**：导演信息（如"导演: 亚伦·霍瓦斯 / 迈克尔·杰勒尼克"）
  - 多位导演用 `/` 分隔，提取所有导演姓名
  - 存储格式：将多位导演用 `、` 连接存入 rich_text 字段
- **类型**：类型标签（如"喜剧 / 爱情 / 科幻 / 动画 / 奇幻 / 冒险"）
  - 按 `/` 分隔，去除首尾空格
  - 匹配已有的类型选项：喜剧, 剧情, 动画, 冒险, 科幻, 动作, 奇幻, 爱情, 运动, 灾难, 医疗, 悬疑, 犯罪, 传记, 历史, 音乐, 家庭, 纪实, 战争, 古装, 歌舞, 恐怖, 惊悚, 短片, 小说改编, 游戏改编, 武侠, 真人秀, 儿童, 自然, 美食
  - 如果页面类型不在选项中，选择最接近的选项或跳过
- **豆瓣评分**：页面上的评分数字
- **豆瓣网址**：用户提供的豆瓣链接

#### 阅读记录（豆瓣读书）
从豆瓣读书页面提取：
- **书名**：页面标题中的书籍名称
- **作者**：作者信息
- **类型**：书籍分类标签（匹配已有类型选项）
- **豆瓣评分**：页面上的评分数字
- **豆瓣网址**：用户提供的豆瓣链接

#### 示例：从豆瓣提取数据后创建记录
```javascript
// 用户说"我看过这个 https://movie.douban.com/subject/25845392/"
// 页面显示：超级马里奥兄弟大电影，导演: 亚伦·霍瓦斯 / 迈克尔·杰勒尼克，类型: 喜剧 / 爱情 / 科幻 / 动画 / 奇幻 / 冒险，评分: 7.8
const mediaData = {
  parent: { database_id: '8ad61aac3afd4101862e50986e36b9bc' },
  properties: {
    "名称": { title: [{ text: { content: "超级马里奥兄弟大电影" } }] },
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

### 影视封面获取规则（Trakt.tv）
当用户添加影视记录时，应自动从 Trakt.tv 搜索并获取电影/剧集封面图片，然后嵌入到 Notion 页面中。

#### 操作步骤
1. **访问 Trakt.tv 搜索页面**
   - 打开 `https://app.trakt.tv/`
   - 使用搜索功能，输入影视名称进行搜索

2. **搜索并选择正确结果**
   - 在搜索结果中找到匹配的电影或剧集
   - 点击进入详情页获取封面图片 URL

3. **获取封面图片 URL**
   - 封面图片通常位于详情页的海报/封面区域
   - 提取图片的直接链接（确保是高质量图片）

4. **嵌入封面到 Notion 页面**
   - 创建 Notion 页面后，使用 Notion API 添加图片块
   - 将封面图片作为外部图片嵌入

#### Notion API 添加图片块示例
```javascript
// 创建页面后，添加封面图片块
const pageId = "新创建的页面ID";
const coverImageUrl = "https://example.com/movie-poster.jpg";

// 添加图片块到页面内容
const imageBlock = {
  object: "block",
  type: "image",
  image: {
    type: "external",
    external: {
      url: coverImageUrl
    }
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
// 用户说"添加电影「奥本海默」，已看过"
// 1. 先在 Trakt.tv 搜索 "Oppenheimer"
// 2. 找到电影详情页，获取封面图片 URL
// 3. 创建 Notion 页面
// 4. 添加图片块到页面内容

// 步骤1: 创建页面
const pageData = {
  parent: { database_id: '8ad61aac3afd4101862e50986e36b9bc' },
  properties: {
    "名称": { title: [{ text: { content: "奥本海默" } }] },
    "类别": { select: { name: "海外电影" } },
    "进行状态": { status: { name: "看过" } },
    "观看次数": { number: 1 }
  }
};

// 步骤2: 创建页面后，添加封面图片块
const coverImageUrl = "https://walter.trakt.tv/images/movies/poster.jpg";
// 使用 PATCH /v1/blocks/{page_id}/children 添加图片块
```

#### 注意事项
- Trakt.tv 搜索时使用英文原名可能获得更准确的结果
- 如果找不到封面，可以跳过此步骤，不影响页面创建
- 确保图片 URL 是可公开访问的直接链接

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
> 我想在 PC 上玩游戏「黑神话：悟空」

解析：
- 游戏名: 黑神话：悟空
- 平台: PC_STEAM
- 状态: 想玩

### 添加影视
> 添加电影「流浪地球 2」

解析：
- 名称: 流浪地球 2  
- 类别: 国产电影
- 进行状态: 想看

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
