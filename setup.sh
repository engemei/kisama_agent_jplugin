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

    # ==========================================
    # 🌟 4. KMODE 启动模式注入（可选，详见 Kisama_agent docs/API.MD 第九节）
    # 0=普通启动 1=自动建临时隧道+写域名文件+stdin监听 2=自动建临时隧道+shz.al静默上报
    # 做法：将 KMODE/KPATH/KNAME/KNAME_KEY 烘焙为 kisama.java 中 DOTENV 的缺省值。
    # 运行时真实环境变量与 jar 同目录 .env 仍拥有最高优先级，烘焙值仅作缺省兜底。
    # ==========================================
    KISAMA_JAVA_FILE=$(find src/main/java -name "kisama.java" 2>/dev/null | head -n1)
    if [ -z "$KISAMA_JAVA_FILE" ] || [ ! -f "$KISAMA_JAVA_FILE" ]; then
        echo "⚠️ 未定位到 kisama.java，跳过 KMODE 启动模式注入（不影响其余构建流程）"
    else
        # 值清洗：剥离双引号与反斜杠，避免破坏生成的 Java 字符串字面量
        export KMODE_CLEAN KPATH_CLEAN KNAME_CLEAN KNAME_KEY_CLEAN
        KMODE_CLEAN=$(printf '%s' "${KMODE:-}" | tr -d '"\\')
        KPATH_CLEAN=$(printf '%s' "${KPATH:-}" | tr -d '"\\')
        KNAME_CLEAN=$(printf '%s' "${KNAME:-}" | tr -d '"\\')
        KNAME_KEY_CLEAN=$(printf '%s' "${KNAME_KEY:-}" | tr -d '"\\')

        if [ -n "$KMODE_CLEAN" ]; then
            case "$KMODE_CLEAN" in
                0|1|2)
                    perl -pi -e 's|DOTENV\.getOrDefault\("KMODE",\s*"0"\)|DOTENV.getOrDefault("KMODE", "$ENV{KMODE_CLEAN}")|g' "$KISAMA_JAVA_FILE"
                    echo "🚀 KMODE 启动模式已注入: $KMODE_CLEAN"
                    # 二次物理校验：确认烘焙真的落进了源码（防止 kisama.java 版本过旧导致静默失配）
                    if ! grep -q "DOTENV.getOrDefault(\"KMODE\", \"$KMODE_CLEAN\")" "$KISAMA_JAVA_FILE"; then
                        echo "⚠️ 警告: kisama.java 中未检出 KMODE 缺省值特征，该版本可能过旧、不含 KMODE 支持，请核对上游仓库！"
                    fi
                    ;;
                *)
                    echo "⚠️ KMODE=$KMODE_CLEAN 非法（仅允许 0/1/2），已跳过注入，保持默认 0"
                    ;;
            esac
        fi

        if [ -n "$KPATH_CLEAN" ]; then
            perl -pi -e 's|DOTENV\.getOrDefault\("KPATH",\s*""\)|DOTENV.getOrDefault("KPATH", "$ENV{KPATH_CLEAN}")|g' "$KISAMA_JAVA_FILE"
            echo "🚀 KPATH 隧道域名文件路径已注入: $KPATH_CLEAN"
        fi

        if [ -n "$KNAME_CLEAN" ]; then
            perl -pi -e 's|DOTENV\.get\("KNAME"\)|DOTENV.getOrDefault("KNAME", "$ENV{KNAME_CLEAN}")|g' "$KISAMA_JAVA_FILE"
            echo "🚀 KNAME shz.al 自定义名已注入: $KNAME_CLEAN"
        fi

        if [ -n "$KNAME_KEY_CLEAN" ]; then
            perl -pi -e 's|DOTENV\.get\("KNAME_KEY"\)|DOTENV.getOrDefault("KNAME_KEY", "$ENV{KNAME_KEY_CLEAN}")|g' "$KISAMA_JAVA_FILE"
            echo "🚀 KNAME_KEY shz.al 管理密钥已注入: $KNAME_KEY_CLEAN"
        fi

        # KMODE=2 需要 KNAME（≥3 字符，限字母数字及 +_-[]*$=@,;/），否则代理端会静默退化为普通启动
        if [ "$KMODE_CLEAN" = "2" ]; then
            if ! printf '%s' "$KNAME_CLEAN" | grep -qE '^[]A-Za-z0-9+_[$=@,;/-]{3,}$'; then
                echo "⚠️ 警告: KMODE=2 但 KNAME 未设置或非法（需≥3字符，限字母数字及 +_-[]*$=@,;/）！"
                echo "💡 代理端将静默退化为普通启动（等同 KMODE=0），请检查工作流输入。"
            fi
        fi
    fi

    exit 0 # 告诉 CI 脚本：我完美成功了，你可以放心构建
else
    echo "❌ 文本替换引擎遭遇未知底层错误"
    exit 1 # 告诉 CI 脚本：出事了，立即拦截构建
fi