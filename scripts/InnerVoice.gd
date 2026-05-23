# ============================================================
# 三道心声 — Disco Elysium式内心声音
# 商道/天道/人心 = 你脑中的三个声音，在你做决定时说话
# ============================================================
extends RefCounted
class_name InnerVoice

enum Voice { SHANG = 0, TIAN = 1, REN = 2 }

# 商道 — 精明、算计、谈钱
static func shang(level: int, situation: String) -> String:
	var pool = SHANG_LINES.get(situation, [])
	if pool.is_empty(): return ""
	var idx = min(level / 10, pool.size() - 1)
	return pool[idx] if idx >= 0 else ""

# 天道 — 神秘、宿命、谈机缘
static func tian(level: int, situation: String) -> String:
	var pool = TIAN_LINES.get(situation, [])
	if pool.is_empty(): return ""
	var idx = min(level / 10, pool.size() - 1)
	return pool[idx] if idx >= 0 else ""

# 人心 — 温柔、共情、谈人
static func ren(level: int, situation: String) -> String:
	var pool = REN_LINES.get(situation, [])
	if pool.is_empty(): return ""
	var idx = min(level / 10, pool.size() - 1)
	return pool[idx] if idx >= 0 else ""

# 高道行时偶尔触发内心声音吐司
static func maybe_speak(situation: String, toast_target) -> void:
	if not toast_target or not toast_target.has_method("show_toast"):
		return
	
	var voices = []
	var sd = PlayerData.shang_dao
	var td = PlayerData.tian_dao
	var rd = PlayerData.ren_xin
	
	if sd >= 15: voices.append({"voice": Voice.SHANG, "level": sd})
	if td >= 15: voices.append({"voice": Voice.TIAN, "level": td})
	if rd >= 15: voices.append({"voice": Voice.REN, "level": rd})
	
	if voices.is_empty(): return
	
	var v = voices[randi() % voices.size()]
	var line = ""
	var color = Color.WHITE
	match v.voice:
		Voice.SHANG:
			line = shang(v.level, situation)
			color = Color(1, 0.85, 0.3)
		Voice.TIAN:
			line = tian(v.level, situation)
			color = Color(0.7, 0.45, 0.85)
		Voice.REN:
			line = ren(v.level, situation)
			color = Color(0.4, 0.85, 0.6)
	
	if line != "":
		toast_target.show_toast(line, color, 4.0)


# ============================================================
# 台词池
# ============================================================

const SHANG_LINES = {
	"day_start": [
		"商道：「新的一天。灵石不会自己进账。」",
		"商道：「今天集市行情怎么样？先去看看再说。」",
		"商道：「记住——低价买，高价卖。简单。」",
		"商道：「昨天赚了多少？不够，永远不够。」",
		"商道：「你嗅到钱的味道了吗？今天适合做生意。」",
	],
	"smelt": [
		"商道：「投资有风险。但你每次都不敢赌大的。」",
		"商道：「一件宝品值一座小城。算清楚再动手。」",
		"商道：「熔炼是最快的来钱路——前提是别赔。」",
	],
	"haggle_success": [
		"商道：「成交。这单做得漂亮。」",
		"商道：「赚了。不过我总觉得还能再抬一点…」",
		"商道：「灵石进账的声音，百听不厌。」",
	],
	"haggle_fail": [
		"商道：「走了？下次开价别那么狠。」",
		"商道：「顾客走了。生意就是这样——有赚有赔。」",
		"商道：「亏了。记住这个教训。」",
	],
	"big_earn": [
		"商道：「……这么多灵石。你终于像个真正的商人了。」",
		"商道：「这笔赚大了。灵墟商会该给你发请帖了。」",
	],
}

const TIAN_LINES = {
	"day_start": [
		"天道：「炉火将熄未熄。今日熔炼运势——中上。」",
		"天道：「灵气在流动。我感觉到了……今天会有好事发生。」",
		"天道：「天机不可泄露。但你可以试试。」",
	],
	"smelt": [
		"天道：「灵材在你手中颤抖。它知道自己的命运。」",
		"天道：「天地为炉，造化为工。你只是这天道中的一粒尘。」",
		"天道：「升品还是湮灭——全在一念之间。」",
	],
	"upgrade": [
		"天道：「升品了。天道眷顾了你一次。」",
		"天道：「灵材在你手中蜕变。这是你的道行。」",
	],
	"destroy": [
		"天道：「化为灰烬。但碎片留下了——天道不夺人所有。」",
		"天道：「失败是熔炼的一部分。天道从未承诺过什么。」",
	],
	"milestone": [
		"天道：「你已在灵墟走过了%d天。天地为证。」",
	],
}

const REN_LINES = {
	"day_start": [
		"人心：「今天石老会来吗？上次他夸了你的灵材。」",
		"人心：「每个人都有故事。你只是还没听。」",
		"人心：「摆摊不只是赚钱。是在和人打交道。」",
	],
	"haggle_success": [
		"人心：「他笑了。不是因为价格——是因为你。」",
		"人心：「成交的瞬间，你们之间多了一分信任。」",
	],
	"haggle_fail": [
		"人心：「他走了。也许下次可以温柔一点。」",
		"人心：「赶走一个人很容易。但你可能永远不会再见到他了。」",
	],
	"regular_visit": [
		"人心：「常客来了。这就是你在这灵墟的意义。」",
		"人心：「他记得你。从第一次交易开始。」",
	],
}
