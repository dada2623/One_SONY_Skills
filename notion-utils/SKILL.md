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

- 源仓库：`./notion-utils/scripts/`（仓库根目录下）
- 安装后：`~/.cc-switch/skills/notion-utils/scripts/`

**一律用 `bash ./scripts/xxx.sh` 调用**：安装副本的脚本权限常为 `644`，直接 `./scripts/xxx.sh` 会报 `Permission denied`。

## 常用脚本列表

| 脚本 | 功能 | 用法 |
|------|------|------|
| `common.sh` | API 辅助函数、 `source` 引入 |
| `create-page.sh` | 创建页面 | `DATABASE_ID=xxx bash ./notion-utils/scripts/create-page.sh "标题" [内容]` |
| `list-pages.sh` | 列出页面 | `DATABASE_ID=xxx bash ./notion-utils/scripts/list-pages.sh` |
| `get-page.sh` | 获取页面详情 | `bash ./notion-utils/scripts/get-page.sh <page_id> [include_blocks]` |
| `update-page.sh` | 更新页面属性 | `bash ./notion-utils/scripts/update-page.sh <page_id> '<json>' 或 <json 文件路径>` |
| `delete-page.sh` | 归档页面 | `bash ./notion-utils/scripts/delete-page.sh <page_id>` |
| `add-block.sh` | 添加内容块 | `bash ./notion-utils/scripts/add-block.sh <page_id> "内容"` |

## 环境变量

| 变量 | 说明 |
|------|------|
| `NOTION_API_KEY` | Notion API 密钥（可选，默认从 `~/.config/notion/api_key` 读取） |
| `DATABASE_ID` | 目标数据库 ID（create-page.sh 和 list-pages.sh 需要） |

## 通用规则（所有调用方 skill 都应遵守）

1. **更新前先 GET 页面属性确认字段类型**：`update-page.sh` 会自动 GET 页面拿到每个字段的 type 再构造 payload；手动构造 payload 时也必须先 GET，select/status 用 `{name}`，multi_select 用对象数组 `[{"name": "..."}]`
2. **multi_select 直接传字符串数组**：调用 `update-page.sh` 时写 `{"观看方式": ["电视"]}` 即可，脚本会自动转换为 Notion 要求的 `[{"name": "电视"}]`；不要把字符串数组直接传给 Notion API。**multi_select 是整体覆盖**：传新数组会抹掉未列出的旧值，追加时先把原值读出来合并传入
3. **复杂更新用 JSON 文件**：字段多或含特殊字符时，把 JSON 写入文件再传入 `./notion-utils/scripts/update-page.sh <page_id> /path/updates.json`，避免 shell 转义问题；也支持 `@/path/updates.json`
4. **报错看 message**：API 400/422 时脚本会打印 `error.message`，据此定位（最常见原因是 multi_select payload 结构错误或字段类型不匹配）
5. **只读/不存在的字段会被跳过并警告**：脚本输出 `Warning: skipped fields (missing from page or read-only): 字段名`，看到这条警告说明对应字段那次更新**没有生效**（字段名拼错或传了只读字段如 创建时间/上次编辑时间）
6. **省略 key = 不修改，不是清空**：payload 里没出现的字段不会被改动；要清空字段需显式传空值
7. **create-page.sh 是两段式**：只写 title（+ 可选正文段落），其余属性要紧接着跑一次 `update-page.sh` 补齐
8. **Notion-Version 固定 `2022-06-28`**：`common.sh` 已内置，不要手改成其他版本（如 `2024-02-28` 会被 API 拒绝并返回允许值清单）
9. **PATCH 响应体即回读证据**：`update-page.sh` 成功后打印的响应就是更新后的完整属性，可直接核对，不必再 GET 一次

## 使用示例

```bash
# 列出 Wishlist 数据库的所有页面
DATABASE_ID=c1b6e15bc8e5472897f80fa3b0a18a02 bash ./notion-utils/scripts/list-pages.sh

# 在影视记录数据库创建页面
DATABASE_ID=8ad61aac3afd4101862e50986e36b9bc bash ./notion-utils/scripts/create-page.sh "test"

# 读取页面属性与内容（更新前建议先跑）
bash ./notion-utils/scripts/get-page.sh <page_id>

# 更新页面状态（内联 JSON；multi_select 传字符串数组即可，脚本自动转换）
bash ./notion-utils/scripts/update-page.sh <page_id> '{"状态":"已买","平台":["Switch","PC"]}'

# 更新页面（推荐：JSON 文件方式，避免 shell 转义问题）
cat > /tmp/updates.json <<'EOF'
{"状态":"已通关","个人评分":"⭐⭐⭐⭐","结束日期":"2026-08-06"}
EOF
bash ./notion-utils/scripts/update-page.sh <page_id> /tmp/updates.json
```

**注意**: 路径基于仓库根目录（脚本已从 `skills/` 子目录上移到根目录）；安装副本位于 `~/.cc-switch/skills/notion-utils/`。
