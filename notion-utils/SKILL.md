---
name: notion-utils
description: 通用 Notion API 脚本工具集，提供页面创建、查询、更新、删除、添加内容块等常用操作。适用于所有 Notion 数据库。
metadata:
  {
    "openclaw":
      { "emoji": "🔧", "requires": { "env": ["NOTION_API_KEY"] }, "primaryEnv": "NOTION_API_KEY" },
  }
---

# notion-utils

通用 Notion API 脚本工具集，可被所有 Notion 相关 skill 复用。

## 脚本位置

`./skills/notion-utils/scripts/`

## 猟用脚本列表

| 脚本 | 功能 | 用法 |
|------|------|------|
| `common.sh` | API 辅助函数、 `source` 引入 |
| `create-page.sh` | 创建页面 | `DATABASE_ID=xxx ./scripts/create-page.sh "标题" [内容]` |
| `list-pages.sh` | 列出页面 | `DATABASE_ID=xxx ./scripts/list-pages.sh` |
| `get-page.sh` | 获取页面详情 | `./scripts/get-page.sh <page_id> [include_blocks]` |
| `update-page.sh` | 更新页面属性 | `./scripts/update-page.sh <page_id> '{"属性名":"值"}'` |
| `delete-page.sh` | 归档页面 | `./scripts/delete-page.sh <page_id>` |
| `add-block.sh` | 添加内容块 | `./scripts/add-block.sh <page_id> "内容"` |

## 环境变量

| 变量 | 说明 |
|------|------|
| `NOTION_API_KEY` | Notion API 密钥（可选，默认从 `~/.config/notion/api_key` 读取） |
| `DATABASE_ID` | 目标数据库 ID（create-page.sh 和 list-pages.sh 需要） |

## 使用示例

```bash
# 列出 Wishlist 数据库的所有页面
DATABASE_ID=c1b6e15bc8e5472897f80fa3b0a18a02 ./skills/notion-utils/scripts/list-pages.sh

# 在影视记录数据库创建页面
DATABASE_ID=8ad61aac3afd4101862e50986e36b9bc ./skills/notion-utils/scripts/create-page.sh "test"

# 更新页面状态
./skills/notion-utils/scripts/update-page.sh <page_id> '{"状态":"已买"}'
```

