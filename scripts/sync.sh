#!/bin/bash
# 同步WSL项目到Windows桌面项目目录
# 用法: bash scripts/sync.sh

WSL_PROJECT="/home/ziyuting/Projects/灵墟旅商"
WIN_PROJECT="/mnt/c/Users/35595/Desktop/灵墟旅商"

echo "🔄 同步 WSL → Windows 桌面..."
echo "  源: $WSL_PROJECT/scripts/"
echo "  目标: $WIN_PROJECT/scripts/"
echo ""

# 同步scripts
cp -u "$WSL_PROJECT/scripts/"*.gd "$WIN_PROJECT/scripts/"
echo "✅ scripts/ 同步完成"

# 同步scenes
cp -u "$WSL_PROJECT/scenes/"*.tscn "$WIN_PROJECT/scenes/"
echo "✅ scenes/ 同步完成"

# 同步project.godot
cp -u "$WSL_PROJECT/project.godot" "$WIN_PROJECT/project.godot"
echo "✅ project.godot 同步完成"

# 同步assets
cp -ru "$WSL_PROJECT/assets/img/"* "$WIN_PROJECT/assets/img/"
echo "✅ assets/img/ 同步完成"

echo ""
echo "🎉 全部同步完成！重启Godot编辑器即可看到更新。"
echo ""
echo "未同步的文件类型（如有需要请手动处理）:"
echo "  - .tscn 文件（已同步）"
echo "  - .tres 文件"
echo "  - addons/ 目录"
