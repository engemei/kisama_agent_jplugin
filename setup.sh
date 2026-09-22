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
# ==========================================
# 🌟 4. KMODE 启动模式注入（可选，详见 Kisama_agent docs/API.MD 第九节）
# 0=普通启动 1=自动建临时隧道+写域名文件+stdin监听 2=自动建临时隧道+shz.al静默上报
# 做法：把 KMODE/KPATH/KNAME/KNAME_KEY 作为构造实参烘焙进主类的 new kisama(...) 调用。
# 运行期优先级不变：真实环境变量 > jar 同目录 .env > 构造实参烘焙值 > 内置缺省。
# ==========================================
KISAMA_JAVA_FILE=$(find src/main/java -name "kisama.java" 2>/dev/null | head -n1)

# 值清洗：剥离双引号与反斜杠，避免破坏生成的 Java 字符串字面量
KMODE_CLEAN=$(printf '%s' "${KMODE:-}" | tr -d '"\\')
KPATH_CLEAN=$(printf '%s' "${KPATH:-}" | tr -d '"\\')
KNAME_CLEAN=$(printf '%s' "${KNAME:-}" | tr -d '"\\')
KNAME_KEY_CLEAN=$(printf '%s' "${KNAME_KEY:-}" | tr -d '"\\')

# 仅当确实要烘焙非缺省启动模式时才需要 7 参构造；全为空/0 时保持 3 参调用，兼容旧版 kisama.java
BAKE_REQUESTED=0
case "$KMODE_CLEAN" in
    ''|0) ;;
    1|2) BAKE_REQUESTED=1 ;;
    *) echo "❌ 错误: KMODE=$KMODE_CLEAN 非法（仅允许 0/1/2），终止构建" >&2; exit 1 ;;
esac
if [ -z "$KMODE_CLEAN" ] && [ -n "$KPATH_CLEAN$KNAME_CLEAN$KNAME_KEY_CLEAN" ]; then
    echo "❌ 错误: 仅提供了 KPATH/KNAME/KNAME_KEY 但 KMODE 为空（这些参数只在 KMODE=1/2 下有意义），终止构建" >&2
    exit 1
fi

if [ "$BAKE_REQUESTED" = "1" ]; then
    if [ -z "$KISAMA_JAVA_FILE" ] || [ ! -f "$KISAMA_JAVA_FILE" ]; then
        echo "❌ 错误: 未定位到 kisama.java，无法注入 KMODE=$KMODE_CLEAN，终止构建" >&2
        exit 1
    fi
    # 上游支持性探测：7 参构造（带烘焙实参）必须存在，否则会编出一个"看似成功"却无 KMODE 的 jar
    if ! grep -q 'String bakedKmode' "$KISAMA_JAVA_FILE"; then
        echo "❌ 错误: $KISAMA_JAVA_FILE 不含 KMODE 烘焙构造实参 (String bakedKmode)！" >&2
        echo "💡 当前 KISAMA_SOURCE=${KISAMA_SOURCE:-upstream}：该来源的 kisama.java 过旧（上游 main 或本仓库副本尚未合入 7 参构造）。" >&2
        echo "💡 处理：把带 bakedKmode 构造的版本推上 Kisama_agent main，或改用 KISAMA_SOURCE=repo 走本仓库副本，或让本次构建 KMODE=0。" >&2
        exit 1
    fi
    # KMODE=2 的生效前置：KNAME ≥3 合法字符，且实际密钥（KNAME_KEY 或兜底的 KNAME）≥8 字符，
    # 否则代理端会按 KMODE=0 普通启动 —— 与其静默退化，不如构建期直接失败。
    if [ "$KMODE_CLEAN" = "2" ]; then
        if ! printf '%s' "$KNAME_CLEAN" | grep -qE '^[]A-Za-z0-9+_[$=@,;/-]{3,}$'; then
            echo "❌ 错误: KMODE=2 需要 KNAME（≥3 字符，限字母数字及 +_-[]*\$=@,;/），当前为 '${KNAME_CLEAN:-（空）}'" >&2
            exit 1
        fi
        EFFECTIVE_KEY_LEN=${#KNAME_KEY_CLEAN}
        [ "$EFFECTIVE_KEY_LEN" = "0" ] && EFFECTIVE_KEY_LEN=${#KNAME_CLEAN}
        if [ "$EFFECTIVE_KEY_LEN" -lt 8 ]; then
            echo "❌ 错误: KMODE=2 的实际密钥只有 $EFFECTIVE_KEY_LEN 字符（<8），代理端会退化为普通启动。" >&2
            echo "💡 请提供 ≥8 字符的 KNAME_KEY，或让 KNAME 本身 ≥8 字符（留空时 KNAME_KEY 复用 KNAME）。" >&2
            exit 1
        fi
    fi
fi

# 主类 new kisama(...) 调用的完整替换文本：3 参或 7 参
if [ "$BAKE_REQUESTED" = "1" ]; then
    AGENT_INIT="this.agent = new kisama(${KPORT}, \"${ECDSA_PUBKEY}\", \"${ECIES_PUBKEY}\", \"${KMODE_CLEAN}\", \"${KPATH_CLEAN}\", \"${KNAME_CLEAN}\", \"${KNAME_KEY_CLEAN}\");"
else
    AGENT_INIT="this.agent = new kisama(${KPORT}, \"${ECDSA_PUBKEY}\", \"${ECIES_PUBKEY}\");"
fi
export AGENT_INIT
perl -0777 -pi -e 's|this\.agent\s*=\s*new\s+kisama\s*\([\s\S]*?\);|$ENV{AGENT_INIT}|g' "$MAIN_JAVA_FILE"
# ==========================================
# 🌟 [关键修补] 确保 setup.sh 拥有健康的生命周期返回
# ==========================================
if [ $? -eq 0 ]; then
    echo "🎉 核心公钥已成功注入完成 ➔ $MAIN_JAVA_FILE"

    # 二次物理校验：确认替换真的落进了源码（防止占位符残留导致的假成功）
    if ! grep -qF "$AGENT_INIT" "$MAIN_JAVA_FILE"; then
        echo "❌ 错误: 主类中未检出注入后的 new kisama(...) 调用，替换未生效，终止构建" >&2
        exit 1
    fi
    if [ "$BAKE_REQUESTED" = "1" ]; then
        echo "🚀 KMODE 启动模式已烘焙: KMODE=$KMODE_CLEAN KPATH=${KPATH_CLEAN:-（缺省 \$HOME/domain.txt）} KNAME=${KNAME_CLEAN:-（未设置）} KNAME_KEY=$( [ -n "$KNAME_KEY_CLEAN" ] && echo "（已设置, ${#KNAME_KEY_CLEAN} 字符）" || echo "（留空, 运行期复用 KNAME）" )"
    fi

    exit 0 # 告诉 CI 脚本：我完美成功了，你可以放心构建
else
    echo "❌ 文本替换引擎遭遇未知底层错误"
    exit 1 # 告诉 CI 脚本：出事了，立即拦截构建
fi