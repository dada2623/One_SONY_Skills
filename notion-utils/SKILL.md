---
name: notion-utils
description: 通用 Notion API 脚本工具集，提供页面创建、查询、更新、删除、添加内容块等常用操作。适用于所有 Notion 数据库。
triggers:
  - notion
  - Notion
  - notion-utils
tools_required:
  - filesystem
  - shell
---

# notion-utils

通用 Notion API 脚本工具集，可被所有 Notion 相关 skill 复用。

## 脚本位置

`./notion-utils/scripts/`（仓库根目录下）

## 常用脚本列表

| 脚本 | 功能 | 用法 |
|------|------|------|
| `common.sh` | API 辅助函数、 `source` 引入 |
| `create-page.sh` | 创建页面 | `DATABASE_ID=xxx ./notion-utils/scripts/create-page.sh "标题" [内容]` |
| `list-pages.sh` | 列出页面 | `DATABASE_ID=xxx ./notion-utils/scripts/list-pages.sh` |
| `get-page.sh` | 获取页面详情 | `./notion-utils/scripts/get-page.sh <page_id> [include_blocks]` |
| `update-page.sh` | 更新页面属性 | `./notion-utils/scripts/update-page.sh <page_id> '<json>' 或 <json 文件路径>` |
| `delete-page.sh` | 归档页面 | `./notion-utils/scripts/delete-page.sh <page_id>` |
| `add-block.sh` | 添加内容块 | `./notion-utils/scripts/add-block.sh <page_id> "内容"` |

## 环境变量

| 变量 | 说明 |
|------|------|
| `NOTION_API_KEY` | Notion API 密钥（可选，默认从 `~/.config/notion/api_key` 读取） |
| `DATABASE_ID` | 目标数据库 ID（create-page.sh 和 list-pages.sh 需要） |

## 通用规则（所有调用方 skill 都应遵守）

1. **更新前先 GET 页面属性确认字段类型**：`update-page.sh` 会自动 GET 页面拿到每个字段的 type 再构造 payload；手动构造 payload 时也必须先 GET，select/status 用 `{name}`，multi_select 用对象数组 `[{"name": "..."}]`
2. **multi_select 直接传字符串数组**：调用 `update-page.sh` 时写 `{"观看方式": ["电视"]}` 即可，脚本会自动转换为 Notion 要求的 `[{"name": "电视"}]`；不要把字符串数组直接传给 Notion API
3. **复杂更新用 JSON 文件**：字段多或含特殊字符时，把 JSON 写入文件再传入 `./notion-utils/scripts/update-page.sh <page_id> /path/updates.json`，避免 shell 转义问题；也支持 `@/path/updates.json`
4. **报错看 message**：API 400/422 时脚本会打印 `error.message`，据此定位（最常见原因是 multi_select payload 结构错误或字段类型不匹配）
5. **只读/不存在的字段会被跳过并提示**：如 formula、created_time、relation 等，脚本会打印被跳过的字段名，避免静默丢数据

## 使用示例

```bash
# 列出 Wishlist 数据库的所有页面
DATABASE_ID=c1b6e15bc8e5472897f80fa3b0a18a02 ./notion-utils/scripts/list-pages.sh

# 在影视记录数据库创建页面
DATABASE_ID=8ad61aac3afd4101862e50986e36b9bc ./notion-utils/scripts/create-page.sh "test"

# 读取页面属性与内容（更新前建议先跑）
./notion-utils/scripts/get-page.sh <page_id>

# 更新页面状态（内联 JSON；multi_select 传字符串数组即可，脚本自动转换）
./notion-utils/scripts/update-page.sh <page_id> '{"状态":"已买","平台":["Switch","PC"]}'

# 更新页面（推荐：JSON 文件方式，避免 shell 转义问题）
cat > /tmp/updates.json <<'EOF'
{"状态":"已通关","个人评分":"⭐⭐⭐⭐","结束日期":"2026-08-06"}
EOF
./notion-utils/scripts/update-page.sh <page_id> /tmp/updates.json
```

**注意**: 脚本已从 `skills/` 子目录上移到仓库根目录，路径基于仓库根目录。
