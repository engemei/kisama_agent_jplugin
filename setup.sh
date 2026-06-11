#!/bin/bash

# =====================================================================
# 🛡️ Kisama Agent 运行时动态特征配置注入流水线
# =====================================================================

# 1. 严格校验传入的环境变量
if [ -z "$KPORT" ] || [ -z "$ECDSA_PUBKEY" ] || [ -z "$ECIES_PUBKEY" ]; then
    echo "❌ 错误: 必要的配置环境变量未完全提供！"
    echo "💡 使用示例:"
    echo "   KPORT=8443 ECDSA_PUBKEY=\"暗号1\" ECIES_PUBKEY=\"暗号2\" ./setup.sh"
    exit 1
fi

# 2. ⚡ 动态主类物理定位（拒绝任何硬编码路径）
# 优先策略：从现有的 YML 配置文件中提取主类完整 package 路由
DETECTED_MAIN=$(grep -E "^main:" src/main/resources/paper-plugin.yml src/main/resources/plugin.yml 2>/dev/null | head -n1 | awk '{print $2}')

if [ -n "$DETECTED_MAIN" ]; then
    MAIN_JAVA_FILE="src/main/java/$(echo "$DETECTED_MAIN" | tr '.' '/').java"
fi

# 备用保底策略：如果更名过程中 YML 缓存未同步，则直接全盘扫描包含特征代码的 Java 文件
if [ -z "$MAIN_JAVA_FILE" ] || [ ! -f "$MAIN_JAVA_FILE" ]; then
    MAIN_JAVA_FILE=$(find src/main/java -name "*.java" -exec grep -l "new kisama" {} \+ | head -n1)
fi

# 最终合规性安全拦截
if [ -z "$MAIN_JAVA_FILE" ] || [ ! -f "$MAIN_JAVA_FILE" ]; then
    echo "❌ 错误: 在 src/main/java 中未能捕获到包含 'new kisama' 特征的主类文件！"
    exit 1
fi

echo "======================================================="
echo "🎯 成功动态锁定目标主类: $MAIN_JAVA_FILE"
echo "⚡ 正在执行全隔离环境映射替换手术..."
echo "======================================================="

# 3. 🌟 变参安全级环境映射替换
# 改用 s|...|...|g 隔离分隔符，并利用 Perl 内置的 %ENV 字典直接读取系统变量！
# 这样密文里的 /、+、双引号将全部退化为纯文本数据，100% 免疫任何语法冲突。
perl -0777 -pi -e 's|this\.agent\s*=\s*new\s+kisama\s*\([\s\S]*?\);|this.agent = new kisama($ENV{KPORT}, "$ENV{ECDSA_PUBKEY}", "$ENV{ECIES_PUBKEY}");|g' "$MAIN_JAVA_FILE"
# ==========================================
# 🌟 [关键修补] 确保 setup.sh 拥有健康的生命周期返回
# ==========================================
if [ $? -eq 0 ]; then
    echo "🎉 核心公钥已成功注入完成 ➔ $MAIN_JAVA_FILE"
    exit 0 # 告诉 CI 脚本：我完美成功了，你可以放心构建
else
    echo "❌ 文本替换引擎遭遇未知底层错误"
    exit 1 # 告诉 CI 脚本：出事了，立即拦截构建
fi