---
name: consumable-manager
description: 管理Obsidian base耗材数据库，支持增删查改耗材物品。使用场景：(1) 列出/筛选耗材物品，(2) 添加新耗材，(3) 更新耗材信息（数量、位置、归档状态等），(4) 删除耗材，(5) 搜索耗材，(6) 查看统计信息
---

# 耗材管理系统

## 重要：耗材数据库位置

**根据操作系统自动选择正确的数据库路径**：

| 操作系统 | 数据库路径 |
|----------|-----------|
| Windows | `C:\Users\dada2\OneDrive\存档\耗材管理` |
| macOS | `/Users/hu/Library/CloudStorage/OneDrive-个人/存档/耗材管理` |

可通过 `sys.platform` 或 `os.name` 判断操作系统：
- `sys.platform == 'win32'` → Windows
- `sys.platform == 'darwin'` → macOS

## 高效查询工具

### 使用 Python 查询脚本

耗材管理文件夹下提供了高效的 Python 查询脚本 `功能函数/query_consumables.py`，可以快速查询耗材信息。

**导入查询工具**：
```python
import sys
import os

# 根据操作系统选择数据库路径
if sys.platform == 'win32':
    DB_PATH = r"C:\Users\dada2\OneDrive\存档\耗材管理"
else:  # macOS
    DB_PATH = "/Users/hu/Library/CloudStorage/OneDrive-个人/存档/耗材管理"

sys.path.append(os.path.join(DB_PATH, "功能函数"))
from query_consumables import ConsumableQuery

# 初始化查询器
query = ConsumableQuery()
```

**常用查询方法**：

1. **按分类查询**：
```python
# 查询所有个卫洗护类的耗材
results = query.list_by_category("个卫洗护")
for item in results:
    data = item['data']
    print(f"{item['name']}: {data.get('数量', 0)} {data.get('单位', '')}")
```

2. **按位置查询**：
```python
# 查询鞋柜第一层的所有耗材
results = query.list_by_location("鞋柜第一层")
for item in results:
    data = item['data']
    print(f"{item['name']}: {data.get('数量', 0)} {data.get('单位', '')}")
```

3. **按品牌查询**：
```python
# 查询高露洁的所有耗材
results = query.list_by_brand("高露洁")
```

4. **搜索耗材**：
```python
# 搜索包含"牙膏"的耗材
results = query.search_consumables("牙膏")
```

5. **获取统计信息**：
```python
stats = query.get_statistics()
print(f"总物品数: {stats['total_items']}")
print(f"库存中: {stats['in_stock']}")
print(f"按分类统计: {stats['by_category']}")
```

6. **查看单个耗材**：
```python
item = query.get_consumable("牙膏")
if item:
    print(item['data'])
```

**筛选条件**：
```python
# 组合筛选
results = query.list_consumables(
    category="个卫洗护",      # 按分类
    brand="高露洁",           # 按品牌
    location="鞋柜第一层",    # 按位置
    in_stock_only=True,      # 只显示库存中的
    archived_only=False      # 只显示未归档的
)
```

**清除缓存**：
```python
# 如果添加或修改了耗材，需要清除缓存
query.clear_cache()
```

## 快速开始

### 查看所有耗材
```python
# 列出所有耗材
list_consumables()

# 按分类筛选
list_consumables(category="清洁")

# 按品牌筛选
list_consumables(brand="高露洁")

# 按位置筛选
list_consumables(location="鞋柜第二层")

# 仅显示库存中的耗材
list_consumables(in_stock_only=True)
```

### 搜索耗材
```python
# 按名称、品牌、位置、备注搜索
search_consumables("牙膏")
search_consumables("高露洁")
search_consumables("鞋柜")
```

### 查看单个耗材
```python
# 获取耗材详细信息
get_consumable("牙膏")
```

### 添加新耗材
```python
# 基本添加（必需参数）
add_consumable(
    name="新耗材名称",
    quantity=10,
    unit="个"
)

# 完整添加（包含所有可选参数）
add_consumable(
    name="新耗材名称",
    quantity=10,
    unit="个",
    categories=["清洁", "个卫洗护"],  # 分类列表
    brand="品牌名",
    location="鞋柜第二层",
    last_purchase_date="2025-01-31",  # 格式：YYYY-MM-DD
    notes="备注信息",
    archived=False
)
```

### 更新耗材
```python
# 更新数量
update_consumable(name="牙膏", quantity=5)

# 更新位置
update_consumable(name="牙膏", location="鞋柜第一层")

# 更新多个字段
update_consumable(
    name="牙膏",
    quantity=3,
    location="鞋柜第二层",
    notes="含氟"
)

# 归档耗材（表示下次不再购买）
update_consumable(name="旧耗材", archived=True)

# 取消归档（表示下次可能还会购买）
update_consumable(name="旧耗材", archived=False)

# 删除某个字段（传空字符串）
update_consumable(name="牙膏", brand="", location="")
```

### 删除耗材
```python
# 删除耗材（文件将被永久删除）
delete_consumable(name="旧耗材")
```

### 查看统计
```python
# 获取耗材统计信息
stats = get_statistics()
print(f"总物品数: {stats['total_items']}")
print(f"库存中: {stats['in_stock']}")
print(f"缺货: {stats['out_of_stock']}")
print(f"已归档: {stats['archived']}")
print(f"按分类统计: {stats['by_category']}")
print(f"按位置统计: {stats['by_location']}")
```

## 数据结构

### 耗材文件格式
每个耗材存储为一个 `.md` 文件，包含 YAML frontmatter：

```yaml
---
数量: 3
单位: 瓶
最后购买日期: 2025-10-10
品牌: 高露洁
位置: 鞋柜第二层
备注: 含氟
分类:
  - 个卫洗护
已归档: false
---
```

### 字段说明
- **数量** (必需): 整数，表示当前库存数量
- **单位** (必需): 字符串，如"个"、"瓶"、"包"等
- **分类** (可选): 字符串列表，如 `["清洁", "个卫洗护"]`
- **品牌** (可选): 字符串，品牌名称
- **位置** (可选): 字符串，存放位置
- **最后购买日期** (可选): 日期字符串，格式 `YYYY-MM-DD`
- **备注** (可选): 字符串，**仅用于填写耗材的参数**，如容量、规格、型号等。不要添加其他信息（如"已用完"、"不再购买"等）
- **已归档** (可选): 布尔值，默认 `False`，表示是否下次不再购买

## 备注栏使用规范

### 备注栏的用途
**重要规则**：备注栏仅用于填写耗材的**参数信息**，如：
- 容量：`1280 g`、`80 mL`、`1 L`
- 规格：`一包 8 个`、`2 青 1 紫`
- 型号：`iPhone 12 mini`、`小米 15 Pro`
- 适配：`适配米家扫地机器人 5 Pro`

### 备注栏禁止的内容
**不要在备注栏添加**：
- ❌ 使用状态：`已用完`、`已开封`、`正在使用`
- ❌ 购买意向：`不再购买`、`下次还会买`、`考虑换品牌`
- ❌ 评价：`好用`、`不好用`、`推荐`
- ❌ 其他非参数信息

### 状态管理
耗材的状态应通过以下字段管理：
- **数量**：表示当前库存数量（用完后设为 0）
- **已归档**：表示是否下次不再购买（设为 `true` 表示不再购买）

### 示例对比
**正确示例**：
```yaml
备注: 1280 g
已归档: false
```

**错误示例**：
```yaml
备注: 1280 g，已用完，不再购买  ❌
已归档: false
```

**正确的完整示例**：
```yaml
数量: 0
单位: 瓶
品牌: 极男
备注: 80 mL
已归档: true
```

## 命名规范

### 品牌与耗材名称分离
**重要规则**：耗材名称和品牌必须分开存储

**正确示例**：
- 耗材名称：`一次性地漏贴`
- 品牌：`KKV`

**错误示例**：
- 耗材名称：`KKV一次性地漏贴` ❌

### 同一耗材不同品牌的处理
当同一种耗材有多个品牌时，使用空格加数字后缀区分：

**示例**：
- 第一个品牌：`一次性地漏贴`（相当于后缀 "0"，但不显示）
- 第二个品牌：`一次性地漏贴 1`
- 第三个品牌：`一次性地漏贴 2`
- 第四个品牌：`一次性地漏贴 3`

**规则**：
- 第一个品牌不加后缀（相当于后缀 "0"）
- 第二个品牌使用后缀 ` 1`
- 第三个及以后的品牌使用 `空格 + 数字`（如 ` 2`、` 3`）
- 品牌字段仍然填写实际品牌名称（如 `KKV`、`名创优品`）

### 补充装的处理
当耗材是补充装或其他特殊情况时，使用下划线加描述：

**示例**：
- 普通装：`洗手液`
- 补充装：`洗手液_补充装`
- 大包装：`洗手液_大包装`
- 试用装：`洗手液_试用装`

**规则**：
- 使用下划线 `_` 连接
- 描述使用中文，如 `补充装`、`大包装`、`试用装`
- 品牌字段仍然填写实际品牌名称

### 综合示例
```
耗材名称: 一次性地漏贴_补充装 1
品牌: 名创优品
分类: [一次性用品, 清洁]
数量: 5
单位: 个
位置: 鞋柜第二层
已归档: false
```

## 归档管理

### 何时归档
归档表示**下次不再购买**该耗材，适用于以下情况：
- 产品停产或下架
- 不再需要该类产品
- 找到更好的替代品
- 个人需求变化

### 何时不归档
不归档（已归档: false）表示**下次可能还会购买**，适用于：
- 正在使用的产品
- 临时缺货但会补货
- 季节性用品（下次季节还会用）
- 常规消耗品

### 归档操作
```python
# 归档耗材（表示不再购买）
update_consumable(name="旧耗材", archived=True)

# 取消归档（表示可能还会购买）
update_consumable(name="旧耗材", archived=False)

# 查看已归档的耗材
list_consumables(archived_only=True)

# 查看未归档的耗材
list_consumables(archived_only=False)
```

## 常见工作流

### 工作流1：添加新购买的耗材
```python
# 1. 检查是否已存在
existing = get_consumable("一次性地漏贴")
if existing:
    # 2. 更新数量
    new_quantity = existing['data']['数量'] + 3
    update_consumable(name="一次性地漏贴", quantity=new_quantity)
else:
    # 3. 添加新耗材
    add_consumable(
        name="一次性地漏贴",
        quantity=3,
        unit="个",
        categories=["一次性用品", "清洁"],
        brand="KKV",
        location="鞋柜第二层",
        last_purchase_date="2025-01-31"
    )
```

### 工作流2：添加同种耗材的不同品牌
```python
# 检查是否已存在同名耗材
existing = get_consumable("一次性地漏贴")
if existing:
    # 检查品牌是否相同
    if existing['data'].get('品牌') == '名创优品':
        # 品牌相同，更新数量
        new_quantity = existing['data']['数量'] + 3
        update_consumable(name="一次性地漏贴", quantity=new_quantity)
    else:
        # 品牌不同，添加带数字后缀的名称
        # 查找最大数字后缀
        max_num = 0
        for i in range(1, 10):
            test_name = f"一次性地漏贴 {i}"
            if get_consumable(test_name):
                max_num = i
        new_name = f"一次性地漏贴 {max_num + 1}"

        add_consumable(
            name=new_name,
            quantity=3,
            unit="个",
            categories=["一次性用品", "清洁"],
            brand="名创优品",
            location="鞋柜第二层",
            last_purchase_date="2025-01-31"
        )
else:
    # 第一个品牌，直接添加（后缀相当于 "0"，不显示）
    add_consumable(
        name="一次性地漏贴",
        quantity=3,
        unit="个",
        categories=["一次性用品", "清洁"],
        brand="KKV",
        location="鞋柜第二层",
        last_purchase_date="2025-01-31"
    )
```

### 工作流3：处理补充装
```python
# 检查普通装是否存在
existing = get_consumable("洗手液")
if existing:
    # 更新普通装数量
    new_quantity = existing['data']['数量'] + 1
    update_consumable(name="洗手液", quantity=new_quantity)
else:
    # 添加普通装
    add_consumable(
        name="洗手液",
        quantity=1,
        unit="瓶",
        categories=["个卫洗护"],
        brand="滴露",
        location="洗手台",
        last_purchase_date="2025-01-31"
    )

# 添加补充装（作为独立耗材）
add_consumable(
    name="洗手液_补充装",
    quantity=2,
    unit="袋",
    categories=["个卫洗护"],
    brand="滴露",
    location="洗手台",
    last_purchase_date="2025-01-31",
    notes="补充装，需要倒入空瓶使用"
)
```

### 工作流4：清理过期/用完的耗材
```python
# 1. 查找缺货的耗材
out_of_stock = list_consumables(in_stock_only=False)
for item in out_of_stock:
    if item['data'].get('数量', 0) <= 0:
        # 2. 判断是否归档
        # 如果确定不再购买，归档
        update_consumable(name=item['name'], archived=True)
        # 如果只是暂时缺货，不归档
        # update_consumable(name=item['name'], archived=False)
```

### 工作流5：按位置整理耗材
```python
# 1. 查看某个位置的所有耗材
location_items = list_consumables(location="鞋柜第二层")

# 2. 统计分类
from collections import Counter
categories = []
for item in location_items:
    cats = item['data'].get('分类', [])
    categories.extend(cats)
print(Counter(categories))

# 3. 需要移动的耗材
update_consumable(name="牙膏", location="鞋柜第一层")
```

### 工作流6：定期盘点
```python
# 1. 获取总体统计
stats = get_statistics()
print(f"总物品: {stats['total_items']}")
print(f"库存中: {stats['in_stock']}")
print(f"已归档: {stats['archived']}")

# 2. 查看分类分布
for category, count in stats['by_category'].items():
    print(f"{category}: {count}件")

# 3. 查看位置分布
for location, count in stats['by_location'].items():
    print(f"{location}: {count}件")

# 4. 搜索特定耗材
results = search_consumables("清洁")
for item in results:
    print(f"{item['name']}: {item['data'].get('数量', 0)} {item['data'].get('单位', '')}")
```

## 最佳实践

### 命名规范
- **品牌与名称分离**：耗材名称只写产品名，品牌单独存储
- **同种不同品牌**：使用空格加数字后缀（如 ` 2`、` 3`）
- **补充装/特殊装**：使用下划线加描述（如 `_补充装`、`_大包装`）
- 保持一致性，避免随意更改名称

### 分类管理
- 使用标准分类，如：`清洁`、`个卫洗护`、`一次性用品`、`吃喝零食`、`运动`、`电子数码`
- 一个耗材可以有多个分类
- 保持分类名称一致

### 位置管理
- 使用具体位置描述
- 保持位置名称一致
- 定期更新位置信息

### 归档管理
- **归档** = 下次不再购买（产品停产、不需要、找到替代品）
- **不归档** = 下次可能购买（正在使用、临时缺货、季节性用品）
- 定期检查归档状态，确保准确

### 数据维护
- 定期更新数量
- 及时归档已用完且不再购买的耗材
- 保持备注信息更新

## 故障排除

### 问题：耗材已存在
**错误**: `耗材 '名称' 已存在`
**解决**:
- 检查拼写和大小写
- 使用 `get_consumable()` 确认是否存在
- 如果存在，使用 `update_consumable()` 更新
- 如果是不同品牌，使用数字后缀（如 ` 2`）

### 问题：耗材不存在
**错误**: `耗材 '名称' 不存在`
**解决**:
- 检查拼写和大小写
- 使用 `search_consumables()` 搜索
- 使用 `list_consumables()` 查看所有耗材
- 检查是否使用了正确的命名规范

### 问题：文件编码错误
**解决**: 确保所有文件使用 UTF-8 编码保存

### 问题：YAML格式错误
**解决**: 检查 frontmatter 格式，确保使用正确的缩进和语法

### 问题：路径错误
**解决**: 确认耗材数据库路径是否正确，不同设备路径可能不同

### 文件结构
```
耗材管理/
├── 0.耗材数据库.base  # 基础配置（可选）
├── 牙膏.md           # 单个耗材文件
├── 一次性地漏贴.md
├── 一次性地漏贴 2.md
├── 洗手液_补充装.md
└── ...
```

### 现有分类
- 一次性用品
- 清洁
- 吃喝零食
- 个卫洗护
- 运动
- 电子数码

### 常见位置
- 主衣柜左侧第二层
- 鞋柜第二层
- 厨房洗手池下
- 客厅书桌右上抽屉
- 客厅书桌右下大抽屉
- 茶几远沙发侧左边抽屉
- 卧室抽屉最下层
- 鞋柜第一层
- 客厅书桌上
- 仓库间架子旁
- 鞋柜桌面
- 客厅书桌下
- 入户椅下储物层
- 电视柜最右侧抽屉
- 厨房桌面


## 示例对话

### 场景1：用户想查看所有清洁用品
```
用户: 列出所有清洁类的耗材
助手: [导入查询工具]
[调用 query.list_by_category("清洁")]
[输出结果]
```

### 场景2：用户想查看鞋柜第一层的所有耗材
```
用户: 鞋柜第一层有哪些耗材？
助手: [导入查询工具]
[调用 query.list_by_location("鞋柜第一层")]
[输出结果]
```

### 场景3：用户想查看某个分类的统计
```
用户: 个卫洗护类有多少种耗材？
助手: [导入查询工具]
[调用 query.list_by_category("个卫洗护")]
[统计并输出结果]
```

### 场景4：用户想搜索耗材
```
用户: 我的牙膏有哪些？
助手: [导入查询工具]
[调用 query.search_consumables("牙膏")]
[输出结果]
```

### 场景5：用户想查看库存统计
```
用户: 现在还有多少耗材？
助手: [导入查询工具]
[调用 query.get_statistics()]
[输出统计信息]
```

### 场景6：用户想添加新购买的耗材（KKV品牌）
```
用户: 我刚买了3个KKV的一次性地漏贴，放在鞋柜第二层
助手: [调用 add_consumable(name="一次性地漏贴", quantity=3, unit="个", categories=["一次性用品", "清洁"], brand="KKV", location="鞋柜第二层", last_purchase_date="2025-01-31")]
[调用 query.clear_cache()  # 清除缓存]
```

### 场景7：用户想添加同种耗材的不同品牌
```
用户: 我又买了3个名创优品的一次性地漏贴
助手: [检查是否已存在"一次性地漏贴"]
[如果存在且品牌不同，调用 add_consumable(name="一次性地漏贴 1", quantity=3, unit="个", categories=["一次性用品", "清洁"], brand="名创优品", location="鞋柜第二层", last_purchase_date="2025-01-31")]
[调用 query.clear_cache()  # 清除缓存]
```

### 场景8：用户想添加补充装
```
用户: 我买了2袋滴露洗手液的补充装
助手: [调用 add_consumable(name="洗手液_补充装", quantity=2, unit="袋", categories=["个卫洗护"], brand="滴露", location="洗手台", last_purchase_date="2025-01-31", notes="补充装，需要倒入空瓶使用")]
[调用 query.clear_cache()  # 清除缓存]
```

### 场景9：用户想更新耗材信息
```
用户: 把牙膏的数量改成5瓶
助手: [调用 update_consumable(name="牙膏", quantity=5)]
[调用 query.clear_cache()  # 清除缓存]
```

### 场景10：用户表示不再购买某个产品
```
用户: 这个一次性地漏贴不好用，下次不买了
助手: [调用 update_consumable(name="一次性地漏贴", archived=True)]
[调用 query.clear_cache()  # 清除缓存]
```

### 场景11：用户表示还会购买某个产品
```
用户: 这个牙膏用完了，下次还会买
助手: [调用 update_consumable(name="牙膏", archived=False)]
[调用 query.clear_cache()  # 清除缓存]
```
