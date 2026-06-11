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
| **ORG** | `可选` | 彻底洗涤旧组织名特征，重构 Package 路径（留空则不改） | `mycrypto` |
| **PACKAGE** | `可选` | 彻底重构插件主类名与 Jar 包物理名称（留空则不改） | `HyperEngine` |
| **VERSION** | `可选` | 自定义本次编译生成的插件版本号（留空沿用老版本） | `1.2.5` |

4. 填写完毕后，点击绿色的 **Run workflow** 正式启动云端构建。

---

## 📦 最终产物下载

1. 等待构建流水线变为绿色对勾（通常耗时 1~2 分钟，混淆器在全盘施展多态控制流平坦化）。
2. 点击进入该次构建的详情页，滑动至页面最底部。
3. 在 **Artifacts** 区域，你会看到以你指定的主类名命名的产物。
4. **直接点击即可下载**。得益于免 ZIP 直传技术，下载下来的直接就是标准的、无敏感后缀的原生 `.jar` 插件包，扔进服务器的 `plugins` 文件夹即可直接开服交叉联测！