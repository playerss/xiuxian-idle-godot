#!/bin/bash
# M9-P P4 四项基线
cd /home/playerss/xiuxian-idle-godot
G=~/bin/godot
UD="$HOME/.local/share/godot/app_userdata/Xiuxian Idle 修仙挂机"
rm -f "$UD/save.json"
echo "===SELFTEST==="
$G --headless --path . -s res://scripts/selftest.gd 2>&1 | tail -3
echo "===STRESS==="
$G --headless --path . -s res://scripts/stress_test.gd 2>&1 | tail -3
echo "===UITEST==="
rm -f "$UD/save.json"
DISPLAY=:99 timeout 600 $G --path . res://scenes/ui_test.tscn 2>&1 | tail -5
echo "===SMOKE15==="
rm -f "$UD/save.json"
DISPLAY=:99 timeout 25 $G --path . res://scenes/main.tscn 2>&1 | grep -c "SCRIPT ERROR" || true
echo "===DONE==="
