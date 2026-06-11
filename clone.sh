#!/bin/bash

# =====================================================================
# 🛡️ 超纯净·手术刀级全多态项目克隆流水线 (包含动态版本控制)
# =====================================================================

# 1. 精准定位当前模板项目的绝对路径
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 2. ⚡ 动态特征指纹识别：自动内审当前项目的实际包名、类名及当前版本号
DETECTED_MAIN=$(grep -E "^main:" "$SCRIPT_DIR/src/main/resources/paper-plugin.yml" 2>/dev/null | awk '{print $2}')
if [ -z "$DETECTED_MAIN" ]; then
    DETECTED_MAIN=$(grep -E "^main:" "$SCRIPT_DIR/src/main/resources/plugin.yml" 2>/dev/null | awk '{print $2}')
fi

if [ -n "$DETECTED_MAIN" ]; then
    OLD_ORG=$(echo "$DETECTED_MAIN" | cut -d'.' -f2)
    OLD_NAME=$(echo "$DETECTED_MAIN" | cut -d'.' -f3)
else
    OLD_ORG="mycrypto"
    OLD_NAME="HyperEngine"
fi

# 🌟 动态识别当前模板中的旧版本号 (从 build.gradle.kts 中精准提取)
OLD_VERSION=$(grep -E '^version\s*=\s*' "$SCRIPT_DIR/build.gradle.kts" 2>/dev/null | head -n1 | tr -d '"'\'' ' | cut -d'=' -f2)
if [ -z "$OLD_VERSION" ]; then
    OLD_VERSION="1.0.0" # 终极保底
fi

# 3. 自动化输入解析：参数优先，环境变量次之，双空则保持现状（为空则不改）
# 参数1: 主类名 (保底使用老名字)
NEW_NAME=$1
[ -z "$NEW_NAME" ] && NEW_NAME=$PACKAGE
[ -z "$NEW_NAME" ] && NEW_NAME=$OLD_NAME   

# 参数2: 组织包名 (保底使用老组织名)
NEW_ORG=$2
[ -z "$NEW_ORG" ] && NEW_ORG=$ORG
[ -z "$NEW_ORG" ] && NEW_ORG=$OLD_ORG     

# 🌟 参数3: 新版本号 (优先看第3参数 -> 其次看环境变量 -> 最后保底沿用老版本号)
NEW_VERSION=$3
[ -z "$NEW_VERSION" ] && NEW_VERSION=$VERSION
[ -z "$NEW_VERSION" ] && NEW_VERSION=$OLD_VERSION

# 确定新项目生成的绝对路径（严格建立在当前 clone.sh 的同级目录下）
TARGET_DIR="${SCRIPT_DIR}/${NEW_NAME}"

echo "======================================================="
echo "🔍 识别到当前模板特征: com.${OLD_ORG}.${OLD_NAME} (v${OLD_VERSION})"
echo "🔮 即将生成新项目特征: com.${NEW_ORG}.${NEW_NAME} (v${NEW_VERSION})"
echo "📍 新项目绝对生成路径: ${TARGET_DIR}"
echo "======================================================="

# 安全拦截：防止同名原地覆盖自杀行为
if [ "$TARGET_DIR" = "$SCRIPT_DIR" ] && [ "$NEW_NAME" = "$OLD_NAME" ] && [ "$NEW_VERSION" = "$OLD_VERSION" ]; then
    echo "❌ 错误: 新项目与当前项目特征完全一致，请指定全新的名称或版本号！"
    echo "💡 用法示例: ./clone.sh SuperEngine neworg 2.1.0"
    exit 1
fi

# 清理可能残存的旧目标同名文件夹
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# 4. 白名单精准物理拓扑拷贝
echo "🚚 正在外科手术式抽取必要骨架核心..."
ITEMS_TO_COPY=(
    "src"
    "gradle"
    "build.gradle.kts"
    "settings.gradle.kts"
    "gradle.properties"
    "gradlew"
    "gradlew.bat"
    "skidfuscator.jar"
    "README.md"
    "clone.sh"
    "build.sh"
    "setup.sh"
)

for item in "${ITEMS_TO_COPY[@]}"; do
    if [ -e "$SCRIPT_DIR/$item" ]; then
        cp -r "$SCRIPT_DIR/$item" "$TARGET_DIR/"
    fi
done

# 彻底切入新副本主战场进行多态重构
cd "${TARGET_DIR}" || exit 1

# 5. 物理重构 Java 源码目录拓扑
OLD_PACK_DIR="src/main/java/com/${OLD_ORG}"
NEW_PACK_DIR="src/main/java/com/${NEW_ORG}"

if [ "$OLD_ORG" != "$NEW_ORG" ]; then
    echo "📦 正在建立全新的平坦化包路径结构..."
    if [ -d "$OLD_PACK_DIR" ]; then
        mkdir -p "$NEW_PACK_DIR"
        mv "$OLD_PACK_DIR"/* "$NEW_PACK_DIR/" 2>/dev/null
        rm -rf "$OLD_PACK_DIR"
    fi
fi

# 6. 重命名主类源码文件
if [ "$OLD_NAME" != "$NEW_NAME" ]; then
    echo "📝 正在重命名主类定义文件..."
    mv "${NEW_PACK_DIR}/${OLD_NAME}.java" "${NEW_PACK_DIR}/${NEW_NAME}.java" 2>/dev/null
fi

# 7. 全局文本特征代码洗涤与新旧版本号强力置换
echo "⚡ 正在全自动重构配置、版本号、豁免规则与包声明指向..."
find . -type f \( -name "*.kts" -o -name "*.yml" -o -name "*.java" \) | while read -r file; do
    if sed --version >/dev/null 2>&1; then
        # Linux / Docker 内核环境
        sed -i "s/${OLD_NAME}/${NEW_NAME}/g" "$file"
        sed -i "s/${OLD_ORG}/${NEW_ORG}/g" "$file"
        # 🌟 强力精准匹配 build.gradle.kts 和 yml 中的旧版本指纹
        sed -i "s/version = \"${OLD_VERSION}\"/version = \"${NEW_VERSION}\"/g" "$file"
        sed -i "s/version: ${OLD_VERSION}/version: ${NEW_VERSION}/g" "$file"
    else
        # macOS 专属 BSD sed 环境适配
        sed -i "" "s/${OLD_NAME}/${NEW_NAME}/g" "$file"
        sed -i "" "s/${OLD_ORG}/${NEW_ORG}/g" "$file"
        sed -i "" "s/version = \"${OLD_VERSION}\"/version = \"${NEW_VERSION}\"/g" "$file"
        sed -i "" "s/version: ${OLD_VERSION}/version: ${NEW_VERSION}/g" "$file"
    fi
done

echo "======================================================="
echo "🎉 恭喜！全多态纯净无痕副本 [v${NEW_VERSION}] 已成功脱离母体！"
echo "🌲 已自动屏蔽排除任何残留杂质文件，版本特征已被完美覆写。"
echo "🚀 编译就绪指令: cd ${NEW_NAME} && ./gradlew clean build"
echo "======================================================="