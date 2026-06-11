package com.mingli2038; 

import kisama.kisama;
import org.bukkit.Bukkit;
import org.bukkit.event.Listener;
import org.bukkit.plugin.java.JavaPlugin;

public class AetherEngine extends JavaPlugin implements Listener {
    // 🌟 核心改动：用 volatile 直接修饰去静态化后的 kisama 实例，彻底斩断对 App 类的依赖
    private volatile kisama agent;

    @Override
    public void onEnable() {
        // 1. 核心物理拦截：一进入就审视环境变量
        if (!"true".equalsIgnoreCase(System.getenv("LOG"))) {
            
            // 🔒 [A] 斩断插件本体的日志输出
            this.getLogger().setFilter(record -> false);

            // 🔒 [B] 绝杀第三方依赖大喇叭 (Spark, Jetty, Pty4j)
            String[] noisyPackages = {
                "spark", 
                "org.eclipse.jetty", 
                "com.pty4j"
            };

            // 保险一：强行掐断 Java 标准日志通道 (JUL) —— 编译期天然自带
            for (String pkg : noisyPackages) {
                java.util.logging.Logger.getLogger(pkg).setLevel(java.util.logging.Level.WARNING);
            }

            // 保险二：🌟 利用【反射机制】绝杀 Log4j2 总管道（完美绕过编译期找不到类的问题）
            try {
                // 动态加载运行期必然存在的 Log4j2 核心类与 Level 枚举
                Class<?> configuratorClass = Class.forName("org.apache.logging.log4j.core.config.Configurator");
                Class<?> levelClass = Class.forName("org.apache.logging.log4j.Level");
                
                // 获取 setLevel(String, Level) 静态方法
                java.lang.reflect.Method setLevelMethod = configuratorClass.getMethod("setLevel", String.class, levelClass);
                
                // 动态获取 WARN 级别的实例
                Object warnLevel = levelClass.getField("WARN").get(null);
                
                // 批量执行降维静音
                for (String pkg : noisyPackages) {
                    setLevelMethod.invoke(null, pkg, warnLevel);
                }
            } catch (Throwable ignored) {
                // 优雅兜底：即使在缺乏 Log4j2 的非标准独立调试环境中运行，也绝对不会崩服
            }
        }
        getLogger().info("AetherEngine is enabling...");
        // 1. 实例化 kisama（可以走无参默认构造，也可以走我们之前写的 3 要素重载构造函数）
        // this.agent = new kisama(8000, "ECDSA_B64...", "ECIES_B64...");
        this.agent = new kisama(KPORT, 
                        "ECDSA_B64...",
                        "ECIES_B64...");
        // 2. 利用 Lambda 表达式 `() -> {}` 直接将 agent.start() 投递进 Bukkit 异步线程池
        // 这样既防止了开服/重载时网络 I/O 导致游戏卡顿，又省去了多余的包装类
        Bukkit.getScheduler().runTaskAsynchronously(this, () -> {
            try {
                getLogger().info("🚀 正在异步线程中激活 Kisama 后台容器...");
                this.agent.start(); 
                getLogger().info("✅ Kisama 代理端容器已完全就绪，端口、路由与超级终端已绑定。");
            } catch (Exception e) {
                getLogger().severe("❌ Kisama 代理端在异步线程启动时遭遇崩溃: " + e.getMessage());
                e.printStackTrace();
            }
        });
    }

    @Override
    public void onDisable() {
        getLogger().info("Disabling plugin and releasing network sockets...");
        
        // 3. 在服务器执行 /reload 或正常关服时，顺着实例直接下发优雅停机指令
        if (this.agent != null) {
            try {
                // 内部会彻底干掉 SparkJava 拓扑、底层 Jetty 监听以及 Cron 调度线程池
                this.agent.stop(); 
                this.agent = null; // 解除强引用，扔给 JVM 垃圾回收器
                getLogger().info("✅ Kisama 代理端安全卸载，端口已完美释放。");
            } catch (Exception e) {
                getLogger().severe("❌ 卸载 Kisama 代理端时发生异常: " + e.getMessage());
            }
        }
    }
}