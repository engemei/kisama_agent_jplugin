import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar

plugins {
    java
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

// 🌟 核心修正：降级编译目标到 Java 17，确保 1.18 服务器能够识别，同时 1.21 也能完美向下兼容运行
java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}

repositories {
    mavenCentral() // 🌟 修正为 Central
    maven("https://repo.papermc.io/repository/maven-public/")
    maven("https://packages.jetbrains.team/maven/p/ij/intellij-dependencies")
}

dependencies {
    // 🌟 核心修正：编译依赖降级到 1.18.2，确保不会在源码中误用 1.21 的新版专有 API 方法
    compileOnly("io.papermc.paper:paper-api:1.18.2-R0.1-SNAPSHOT")
    implementation("io.github.cdimascio:dotenv-java:3.0.0")

    implementation("com.sparkjava:spark-core:2.9.4")
    implementation("com.google.code.gson:gson:2.10.1")
    implementation("org.bouncycastle:bcprov-jdk15on:1.70")
    implementation("org.jetbrains.pty4j:pty4j:0.12.13")
    implementation("org.slf4j:slf4j-nop:1.7.36")
    implementation("org.eclipse.jetty:jetty-jmx:9.4.48.v20220622")
}

group = "com.mingli2038"
version = "1.0.0"

// 1. 编译生成【极小包】
val jarTask = tasks.named<Jar>("jar") {
    archiveBaseName.set("AetherEngine-raw")
}

// 2. 对【极小包】进行混淆
val obfuscateJar = tasks.register<JavaExec>("obfuscateJar") {
    dependsOn(jarTask)
    
    val outputDir = layout.buildDirectory.dir("libs").get().asFile
    val inputFile = jarTask.get().archiveFile.get().asFile
    val outputFile = File(outputDir, "AetherEngine-obfuscated.jar")
    val configFile = File(project.projectDir, "config.hocon")

    classpath(files("skidfuscator.jar"))
    mainClass.set("dev.skidfuscator.obfuscator.SkidfuscatorMain")

    val runtimeCp = configurations.runtimeClasspath.get().files.joinToString(File.pathSeparator) { it.absolutePath }

    doFirst {
        println("====== [Skidfuscator] 🚀 正在施展 1.18/1.21 双栖级精准多态混淆... ======")
        configFile.writeText("""
            exempt: [
                "class{^com\\/mingli2038\\/}",
                "class{^kisama\\/kisama${'$'}}",
                "class{^kisama\\/kisama\\${'$'}KisamaWebSocketHandler.*}"
            ]

            exceptionReturn { enabled: false }
            flowCondition { enabled: false }
            flowSwitch { enabled: false }
            flowRange { enabled: false }
            crasher { enabled: false }
            interprocedural { enabled: false }
        """.trimIndent())
    }

    args(
        "obfuscate",
        "--libs", runtimeCp, 
        "--output=${outputFile.absolutePath}",
        "--config=${configFile.absolutePath}",
        inputFile.absolutePath
    )

    doLast {
        if (configFile.exists()) configFile.delete()
    }
}

// 3. 创建全新的干净打包任务
val protectedJar = tasks.register<ShadowJar>("protectedJar") {
    dependsOn(obfuscateJar)
    
    archiveBaseName.set("AetherEngine")
    archiveClassifier.set("protected")
    
    configurations = listOf(project.configurations.runtimeClasspath.get())
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    
    exclude("com/sun/jna/**")
    exclude("META-INF/*.SF")
    exclude("META-INF/*.RSA")
    exclude("META-INF/*.DSA")
    
    val outputDir = layout.buildDirectory.dir("libs").get().asFile
    val obfuscatedJarFile = File(outputDir, "AetherEngine-obfuscated.jar")
    from(project.zipTree(obfuscatedJarFile))
    
    manifest {
        attributes(
            "Main-Class" to "com.mingli2038.AetherEngine",
            "Enable-Native-Access" to "ALL-UNNAMED"
        )
    }
}

tasks.named("build") {
    dependsOn(protectedJar)
}

// 4. 同步处理两个 YML 文件
tasks.named<ProcessResources>("processResources") {
    inputs.property("version", project.version)
    // 🌟 同时扫描这两个 YML，把里面的 ${version} 动态刷成当前版本号
    filesMatching(listOf("plugin.yml", "paper-plugin.yml")) {
        expand(mapOf("version" to project.version))
    }
}