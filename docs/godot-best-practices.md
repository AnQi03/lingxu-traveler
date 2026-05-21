# Godot 游戏开发最佳实践 + AI辅助开发流程调研

> 调研时间：2026-05-21
> 来源：Godot官方文档、社区最佳实践、AI游戏开发现状

---

## 一、Godot 4 项目结构最佳实践

```
res://
├── scenes/             场景文件 (.tscn)
│   ├── main/           主场景
│   ├── ui/             UI场景
│   └── levels/         关卡场景
├── scripts/            GDScript (.gd)
│   ├── autoload/       全局单例
│   ├── systems/        系统模块
│   └── utils/          工具函数
├── assets/             资源文件
│   ├── img/            图片
│   │   ├── items/      道具图标
│   │   ├── ui/         UI元素
│   │   ├── bg/         背景
│   │   └── characters/ 角色
│   ├── audio/          音频
│   └── fonts/          字体
├── resources/          资源文件 (.tres)
└── addons/             插件
```

### 关键原则

| 原则 | 说明 |
|------|------|
| **场景即模块** | 每个场景自包含，通过信号和autoload通信 |
| **用信号解耦** | 避免硬引用，用信号传递事件 |
| **单例管理全局状态** | autoload管理玩家数据/游戏状态 |
| **资源文件保存配置** | .tres保存静态数据（灵材定义/NPC模板） |

---

## 二、GDScript 编码规范

### 命名规则

| 类型 | 规范 | 示例 |
|------|------|------|
| 变量 | snake_case | `var spirit_stones: int` |
| 函数 | snake_case | `func get_total_stones():` |
| 类 | PascalCase | `class_name PlayerData` |
| 常量 | ALL_CAPS | `const MAX_DAILY_REFINE: int = 5` |
| 信号 | snake_case | `signal trade_completed(item_id)` |
| 节点引用 | @onready | `@onready var label = $Path` |

### Godot 4 重要特性

```
# 类型标注（推荐）
var count: int = 0
func process(amount: int) -> String:

# @onready（替代_ready中get_node）
@onready var label: Label = $Path/To/Label

# $语法（替代get_node）
$HUD/StoneLabel.text = "100"

# 信号连接
button.pressed.connect(_on_pressed)

# 资源预加载
var item_scene = preload("res://scenes/item.tscn")

# 类型安全的Dictionary
@export var item_data: Dictionary = {}

# 自动绑定Lambda
buy_btn.pressed.connect(func(): _buy(item))
```

### 避免的常见错误

| 错误 | 正确 | 原因 |
|------|------|------|
| `remaining / 100` | `float(remaining) / 100.0` | int除法触发INTEGER_DIVISION警告 |
| `theme_override_colors/font_color` | `add_theme_color_override("font_color", ...)` | 场景文件中可用/语法，脚本中不可用 |
| 场景中写`[extent]` | 应该是`[ext_resource]` | 拼写错误导致Parse Error |
| `_buy(item_def)` 在循环中 | 用`.bind(inst)` 传参 | Lambda捕获的是循环变量引用 |

---

## 三、模拟经营游戏核心设计模式

### 生产-消费循环

```
采集/进货 → 加工/熔炼 → 售卖/交易 → 赚灵石
                                   ↓
                              扩大经营 → 采集更多
```

### 资源类型

| 资源类型 | 特点 | 灵墟旅商对应 |
|---------|------|-------------|
| 线性资源 | 无限增长，无消耗 | 灵石（中间介质） |
| 消耗品 | 使用后消失 | 灵材（核心资源） |
| 稀缺资源 | 限量供应 | 特殊灵材、异变产物 |
| 等级资源 | 随进度解锁 | 商道/天道/人心 |

### 经济平衡公式

```
利润 = 售价 - 成本 - 损耗
玩家效率 = f(商道, 顾客类型, 议价技巧)
利润率 = f(玩家效率, 市场竞争)
```

顾客AI行为模型：
```
需求 = f(时间, 灵潮, 玩家声望)
预算 = f(顾客类型, 市场价)
耐心 = f(性格, 急需程度)
出价 = f(预算, 耐心, 议价轮次)
```

---

## 四、AI辅助游戏开发全过程（已验证可行的工作流）

```
阶段1 - 设定（AI最佳发挥区）
  ├── 世界观构建 → AI生成设定文档（我们已完成42份）
  ├── 系统设计 → AI产出机制文档
  ├── 经济模型 → AI模拟闭环验证
  └── 剧情框架 → AI生成事件时间线

阶段2 - 原型（人机协作区）← 我们在这里
  ├── 核心循环 → AI写GDScript原型 ✅
  ├── UI框架 → AI搭建场景骨架 ⚠️（MCP断连导致.tscn写入不稳定）
  ├── 测试反馈 → 人类运行 > AI修bug 🔄
  └── 数据驱动 → AI生成资源配置

阶段3 - 内容（人类主导，AI辅助）
  ├── 像素美术 → AI生成原型素材（我们已做部分）
  ├── NPC对话 → AI写初稿
  └── 数值调优 → AI推荐参数

阶段4 - 打磨
  ├── 性能优化 → AI分析瓶颈
  ├── 体验优化 → AI建议修改
  └── Bug修复 → AI定位问题
```

### 目前遇到的问题及解决方案

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| .tscn文件写入失败 | MCP桥接写入不稳定 | 改用代码生成UI（Market.gd方案已验证可行） |
| 输入映射未保存 | MCP的input_map_manage写入位置不对 | 直接修改project.godot文件 |
| 场景节点路径不匹配 | 手写.tscn容易写错 | 用代码生成节点替代场景文件 |
| autoload未注册 | MCP写入的autoload没保存 | 手动编辑project.godot |

### 推荐工具链

| 环节 | 工具 | 用法 |
|------|------|------|
| 代码生成 | Hermes Agent + MCP | 用MCP创建脚本，无法连接时直接写文件 |
| 场景搭建 | 代码生成UI | 替代.tscn文件，避免写入丢失 |
| 像素素材 | gpt-image-2 (ithinkapi) | 生成原型素材，后期替换 |
| 版本控制 | Git + GitHub | 每次修改后commit并push |
| 测试验证 | game_eval + 日志 | 用game_eval验证游戏内部状态 |

---

## 五、针对灵墟旅商的下一步建议

### 短期（修复当前问题）

1. ✅ 已解决：Market.tscn引用问题 → 改用代码生成UI
2. ✅ 已解决：INTEGER_DIVISION警告 → 改用float除法
3. ⏳ 正在：摆摊系统调试

### 中期（完成MVP核心循环）

1. 天道熔炼核心玩法（熔炉UI + 升品判定）
2. 昼夜循环 + 过夜结算
3. 基础NPC老赵的剧情事件
4. 像素素材替换占位UI

### 长期（从原型到可玩）

1. 完整的经营循环（进货→摆摊→熔炼→销售）
2. 顾客系统（8种性格 + 察言观色）
3. 商路物流系统
4. 剧情事件系统（23个事件 + 立场站队）
