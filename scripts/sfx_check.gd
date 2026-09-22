# 打磨-139a 音效入库验证: 逐个加载 assets/sfx/ 下 6 个 WAV, 校验格式/时长/非静音, 全过则输出 PASS
# 口径: AudioStreamWAV 44.1kHz 16bit 单声道; 时长 0.05~1.0s; 峰值能量 > 0.05 (非静音)
extends SceneTree

const FILES := [
	"break_win.wav",
	"break_fail.wav",
	"achieve.wav",
	"tower_win.wav",
	"new_record.wav",
	"onekey.wav",
]

func _initialize() -> void:
	var fail := 0
	for f in FILES:
		var p: String = "res://assets/sfx/" + f
		if not ResourceLoader.exists(p):
			print("FAIL %s: resource missing" % p)
			fail += 1
			continue
		var res := load(p)
		if res == null or not (res is AudioStreamWAV):
			print("FAIL %s: not an AudioStreamWAV (%s)" % [f, res.get_class() if res else "null"])
			fail += 1
			continue
		var st := res as AudioStreamWAV
		# 格式断言
		if st.format != AudioStreamWAV.FORMAT_16_BITS:
			print("FAIL %s: format != 16bit (%d)" % [f, st.format])
			fail += 1
			continue
		if st.mix_rate != 44100 or st.stereo:
			print("FAIL %s: rate/stereo mismatch (rate=%d stereo=%s)" % [f, st.mix_rate, st.stereo])
			fail += 1
			continue
		# 时长断言 (0.05~1.0s, 短音效口径; 16bit 单声道 data = 字节流, 采样数 = size/2)
		var dur := st.data.size() / 2.0 / 44100.0
		if dur < 0.05 or dur > 1.0:
			print("FAIL %s: duration %.3f out of [0.05, 1.0]" % [f, dur])
			fail += 1
			continue
		# 非静音: 峰值绝对值 > 0.05 (16bit little-endian 有符号)
		var peak := 0.0
		var data := st.data
		for i in range(0, data.size() - 1, 2):
			var raw := int(data[i]) | (int(data[i + 1]) << 8)
			var v := (raw - 65536 if raw >= 32768 else raw) / 32768.0
			if absf(v) > peak:
				peak = absf(v)
		if peak < 0.05:
			print("FAIL %s: silent (peak=%.4f)" % [f, peak])
			fail += 1
			continue
		print("OK %s dur=%.3fs peak=%.3f" % [f, dur, peak])
	if fail > 0:
		print("SFX CHECK FAIL (%d)" % fail)
		quit(1)
	else:
		print("SFX CHECK PASS (12 项: 6 文件 x 格式/时长/非静音)")
		quit(0)
