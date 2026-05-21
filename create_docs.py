#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Read all .md files, create integrated markdown and concise .docx."""

import os
from docx import Document
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn

BASE = "/home/ziyuting/Projects/灵墟旅商/设定文档"
OUT_MD = "/home/ziyuting/Projects/灵墟旅商/灵墟旅商-完整设定整合.md"
OUT_DOCX = "/mnt/c/Users/35595/Desktop/灵墟旅商-核心设定摘要.docx"

# ── Part 1: Read all files ──────────────────────────────────────────────
files = sorted(f for f in os.listdir(BASE) if f.endswith(".md"))
print(f"Reading {len(files)} files...")

file_contents = {}
for fname in files:
    path = os.path.join(BASE, fname)
    with open(path, "r", encoding="utf-8") as fh:
        file_contents[fname] = fh.read()
    print(f"  OK {fname} ({len(file_contents[fname])} chars)")

# ── Part 2: Create integrated markdown ──────────────────────────────────
integrated = """# 灵墟旅商 - 完整设定整合文档

> 本文档由 32 份设定文档自动整合生成，包含完整的世界观、系统、剧情与角色设定。

---

# 一、世界观基础

"""

world_files = [
    "灵墟创世记.md", "世界观框架.md", "天裂之战.md",
    "货币与经济系统.md", "灵潮周期系统.md", "时间系统设定.md",
]
for fname in world_files:
    content = file_contents.get(fname, "")
    integrated += f"\n## {fname.replace('.md','')}\n\n{content}\n\n---\n\n"

integrated += "\n# 二、经营系统\n\n"

biz_files = [
    "经营系统框架.md", "商路系统设定.md", "拍卖会系统草案.md",
    "暗市系统设定.md", "商会系统.md", "灵材图鉴.md",
]
for fname in biz_files:
    content = file_contents.get(fname, "")
    integrated += f"\n## {fname.replace('.md','')}\n\n{content}\n\n---\n\n"

integrated += "\n# 三、势力与角色\n\n"

char_files = [
    "五大宗门人物志.md", "五域引路人.md", "天机子与天道商会.md",
    "宁家家族.md", "管家系统草案.md", "随从雇员系统.md",
]
for fname in char_files:
    content = file_contents.get(fname, "")
    integrated += f"\n## {fname.replace('.md','')}\n\n{content}\n\n---\n\n"

integrated += "\n# 四、剧情系统\n\n"

plot_files = ["主角成长路线.md", "剧情框架与多结局.md", "新手引导设计.md"]
for fname in plot_files:
    content = file_contents.get(fname, "")
    integrated += f"\n## {fname.replace('.md','')}\n\n{content}\n\n---\n\n"

integrated += "\n# 五、交互与体验\n\n"

ux_files = [
    "交互系统设计.md", "NPC系统设定.md", "好感度声望系统.md",
    "前3小时正反馈设计.md", "体验优化清单.md", "体验优化方案二.md",
]
for fname in ux_files:
    content = file_contents.get(fname, "")
    integrated += f"\n## {fname.replace('.md','')}\n\n{content}\n\n---\n\n"

integrated += "\n# 六、项目管理与边界条件\n\n"

misc_files = ["游戏体量分层.md", "游戏边界条件.md", "细节优化补丁.md", "日志与预警技术方案.md"]
for fname in misc_files:
    content = file_contents.get(fname, "")
    integrated += f"\n## {fname.replace('.md','')}\n\n{content}\n\n---\n\n"

integrated += "\n---\n> 整合完成于 2026年5月21日\n"

with open(OUT_MD, "w", encoding="utf-8") as f:
    f.write(integrated)
print(f"\nIntegrated markdown: {OUT_MD} ({len(integrated)} chars)")

# ── Part 3: Create concise docx ─────────────────────────────────────────
doc = Document()

style = doc.styles['Normal']
font = style.font
font.name = 'Microsoft YaHei'
font.size = Pt(11)

def add_heading1(text):
    h = doc.add_heading(text, level=1)
    for r in h.runs:
        r.font.color.rgb = RGBColor(0x1a, 0x1a, 0x2e)
    return h

def add_heading2(text):
    h = doc.add_heading(text, level=2)
    for r in h.runs:
        r.font.color.rgb = RGBColor(0x2d, 0x2d, 0x5e)
    return h

def add_para(text, size=11):
    p = doc.add_paragraph(text)
    for r in p.runs:
        r.font.size = Pt(size)
    return p

def add_bullet(text, bold_prefix="", size=10):
    p = doc.add_paragraph(style='List Bullet')
    if bold_prefix:
        r = p.add_run(bold_prefix)
        r.bold = True
        r.font.size = Pt(size)
    r = p.add_run(text)
    r.font.size = Pt(size)

# Title
t = doc.add_heading('', level=0)
t.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = t.add_run('灵墟旅商 - 核心设定摘要')
r.font.size = Pt(22)
r.font.color.rgb = RGBColor(0x1a, 0x1a, 0x2e)

sub = doc.add_paragraph()
sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = sub.add_run('一款修仙题材的经营模拟游戏 / 像素风 / 多结局剧情')
r.font.size = Pt(11)
r.font.color.rgb = RGBColor(0x66, 0x66, 0x66)

doc.add_paragraph()

# ═══ 1. Game Overview ═══
add_heading1("一、游戏概述")
add_para(
    "《灵墟旅商》是一款修仙题材的经营模拟游戏（像素风）。玩家扮演宁秩——"
    "一个被判定「修炼无望」的五行杂灵根少年，从宁家出走后白手起家，"
    "在修仙世界靠经商证明自己的价值。核心体验是「进货、议价、卖货、赚灵石、扩张」"
    "的经营循环，叠加独特的「天道熔炼」系统（赌博式材料升品），"
    "以及深度剧情多结局系统。"
)
add_para(
    "灵墟是一个天道之核破碎后分裂成五大板块的修仙世界。灵气由天道碎片驱动，"
    "五大板块各具特色生态与垄断资源。灵石三阶制（下品/中品/上品，1:100:100）"
    "为通用货币。大商会（天道商会）吃不下、看不上、管不到的市场缝隙，就是玩家的生存空间。"
)

# ═══ 2. Core Mechanics ═══
add_heading1("二、核心玩法机制")
add_heading2("经营循环三阶段")
add_para(
    "第一阶段（前1/3）：亲力亲为，面对面讨价还价，口碑积累。\n"
    "第二阶段（中1/3）：雇佣伙计，宗门合作，商路开拓。\n"
    "第三阶段（后1/3）：多分号/商队运营，势力博弈，宏观布局。"
)
add_heading2("天道熔炼（核心特色）")
add_para(
    "宁秩的五行杂灵根让他能感知灵材间的共鸣。将2-5件同品阶物品投入熔炉，"
    "可能获得更高品阶产物（升品约3-5%），也可能异变（约10-15%）、降品或报废。"
    "五行相生组合升品概率更高。异变产物是灵墟只有玩家能产出的独家商品。"
    "每天限熔炼5次。"
)
add_heading2("议价系统")
add_para(
    "以市场参考价为锚点，不同顾客类型（散修/宗门采购/炼药师/急需客/老顾客）"
    "有不同心理底价。品阶鉴微能力让玩家识别被低估的好货。"
)
add_heading2("商路与物流")
add_para(
    "五大板块间跨域运输，不同路线有时间/运费/安全度三维属性。"
    "风险事件包括货物受损、延迟、劫修。可通过保险、护卫、分批发货对冲风险。"
)
add_heading2("暗市系统")
add_para(
    "中央荒原地下的平行市场，有守夜人执法，可交易违禁灵材、情报、暗杀令等。"
    "戴面具进入不降商道值，不戴面具则降商道。高利润但影响正道宗门好感。"
)
add_heading2("拍卖会")
add_para(
    "中期可参与竞拍（明拍/暗拍/一口价），后期可自己主办拍卖会——征集拍品、"
    "宣传邀约、场地安保、定价排期全部由玩家决策。"
)

# ═══ 3. World Setting ═══
add_heading1("三、世界设定")
add_heading2("世界起源")
add_para(
    "太古时期，天道之核驱动灵墟。不知何故天道之核破碎，大陆分裂成五大板块，"
    "碎片嵌入各板块核心。五大宗门在各碎片附近建立。"
    "中央荒原是碎片飞离后留下的空洞——不受天道碎片意志影响，成为自由之地。"
    "灵潮周期是天道碎片试图同步但失败的共振回响。"
)
add_heading2("五大板块")
add_para(
    "北-玄冰域：永冻之地，产玄冰髓、极光晶。宗门寒渊宗（清冷守旧）。\n"
    "南-炎狱域：火山群，产火心石、灰灵壤。宗门焚天阁（暴烈直爽）。\n"
    "东-苍木域：万古森林，产世界树之液、灵木心。宗门万木灵宗（温和重因果）。\n"
    "西-金戈域：戈壁矿脉，产星陨铁、金灵砂。宗门铸魂殿（务实重利）。\n"
    "渊-深海域：深海渊层，产渊灵珠、海魂丝。宗门沧溟宫（神秘莫测）。\n"
    "各板块间有完整的贸易闭环——玄冰髓换灰灵壤、灰灵壤换灵木心、灵木心换星陨铁……"
)
add_heading2("天裂之战")
add_para(
    "300年前域外墟兽入侵，战争持续7年。五大宗门联手封印空间裂缝。"
    "战后铸魂殿成为最富裕宗门、暗市因战场遗物流通而催生、天道商会因倒卖战争物资起家。"
    "目前封印已有不稳定迹象。"
)

# ═══ 4. Progression ═══
add_heading1("四、角色成长与商会发展")
add_heading2("成长路线")
add_para(
    "流浪小贩(1-3月) >> 固定摊位(3-6月) >> 跨域商人(6-12月) >> 商会主事(12-18月) >> 商界大能(18-24月)。"
    "能力树分经营类（行情感知/议价直觉等）、熔炼类（五行感知/相性分析等）、"
    "人际关系类（察言观色/人情账等）。"
)
add_heading2("商会等级（1-9级）")
add_para(
    "1无名小摊 >> 3固定铺面 >> 5商号挂牌（可开分店）>> 7跨域商会 >> 9商道传奇。"
    "每次升级需满足商道条件和花费灵石。商会等级越高固定开销越大。"
)
add_heading2("三道隐性维度")
add_para(
    "商道：经营行为积累，影响交易价格和市场准入。\n"
    "天道：熔炼频率和结果，影响熔炼概率和感知能力。\n"
    "人心：对待他人的方式，影响NPC态度和关键时刻。\n"
    "三个维度不显示数值，但世界通过NPC的态度给你反馈。结局由三道综合走向决定。"
)
add_heading2("随从系统")
add_para(
    "从招募、自荐、暗市等渠道招募随从。有修为/商道/忠诚/体力四维属性和特长标签。"
    "可派去看店、进货、押送、打探、管理分店。忠诚度低于20可能背叛。"
)

# ═══ 5. Economy ═══
add_heading1("五、经济系统")
add_para(
    "灵石三阶制（下品/中品/上品，1:100:100）。品阶体系：凡品(灰) >> 灵品(绿) >> 宝品(蓝) >> 仙品(金)。"
    "物价受产地价差、灵潮周期、供需关系、板块距离等因素影响。"
)
add_para(
    "经济闭环：灵石来自有限矿脉，通过修士劳动流入市场，经玩家交易流转，"
    "最终被传送阵消耗/税收/修炼消耗/熔炼报废等方式回收。"
    "顾客的购买力有来源，花完了要离开——形成自然客流节奏。"
)
add_para(
    "灵材有保质期（灵草7-30天，灵兽材料7-14天，矿石无限期），过期降品或报废。"
    "灵潮周期影响全局经济——小周期7天，大周期数年一次，每位玩家一周目至少体验一次。"
)

# ═══ 6. Unique Selling Points ═══
add_heading1("六、独特卖点")
add_bullet("灵墟唯一能产出异变品的系统，赌博式升品制造核心心理张力", "天道熔炼：")
add_bullet("结局不是选出来的，是每一笔交易积累出来的", "三道隐性结局系统：")
add_bullet("9种主线结局+2种隐藏结局，由玩家行为自然导向", "多结局：")
add_bullet("灵潮周期、宗门兴衰、动态物价、NPC记忆", "活的世界：")
add_bullet("大商会傲慢>>玩家生存空间：灵活/可议价/什么都能找", "差异化竞争：")
add_para("")
add_para(
    "核心情感内核：灵墟是一个破碎的世界，宁秩是一个被判定「无望」的人。"
    "天道熔炼的本质——是宁秩用自己的五行杂灵根复现天道之核破碎前的状态，"
    "让灵材回归它们本来融为一体时的样子。杂灵根不是缺陷，是天赋。"
    "整个灵墟都在等待一个能听见「完整旋律」的人出现。"
)

# ═══ 7. Game Info ═══
add_heading1("七、游戏基本信息")
info = [
    ("游戏类型：", "修仙题材经营模拟（像素风2.5D）"),
    ("一周目时长：", "约60-80小时（游戏内约2年）"),
    ("目标平台：", "PC（Steam），有移动端适配潜力"),
    ("目标受众：", "模拟经营玩家、修仙题材爱好者、像素风游戏玩家"),
    ("开发路线：", "MVP(3-4月) >> 正式版基础(6-8月) >> 剧情(4-6月) >> DLC"),
    ("核心差异化：", "天道熔炼系统+三道隐性结局+活的世界经济+非选项式多结局"),
]
for bp, txt in info:
    add_bullet(txt, bold_prefix=bp)

# Footer
doc.add_paragraph()
f = doc.add_paragraph()
f.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = f.add_run('--- 灵墟旅商 / 核心设定摘要 / 分享版 ---')
r.font.size = Pt(9)
r.font.color.rgb = RGBColor(0x99, 0x99, 0x99)
r.italic = True

doc.save(OUT_DOCX)
print(f"DOCX: {OUT_DOCX}")
print("Done!")
