# Pocket Agent

一个面向 TrollStore 测试的 iOS AI 助手初版。源码可以在 Windows 编辑，GitHub Actions 使用 macOS/Xcode 构建 IPA。

## 当前功能

- 多个模型服务商配置，可填写名称、API Base URL、模型名和 API Key。
- 通过 OpenAI Chat Completions 兼容接口发送对话。
- API Key 保存在 iOS 钥匙串；服务商配置保存在本机偏好设置。
- 首版对话界面、请求状态和错误提示。

## 构建 IPA

推送到 GitHub 的 main/master 分支会自动构建；也可以在 Actions 页面手动运行 **Build TrollStore IPA**。完成后从该次 workflow 的 Artifacts 下载 `PocketAgent-unsigned-ipa`，解压取得 IPA，再通过 TrollStore 安装。首次构建的 bundle id 是 `com.example.pocketagent`。

当前工作目录没有 Git remote，因此需要先将这些工程文件放进你的 GitHub 仓库并推送后，Actions 才能实际运行。此运行环境是 Windows，不能本地运行 Xcode；IPA 是否构建成功以 GitHub Actions 结果为准。

## 功能边界

普通 iOS App 不能在其他 App 上任意显示全局浮窗，也不能静默读取其他 App 当前屏幕。当前版本提供应用内对话。之后可先加入用户主动选择截图/照片的视觉问答；持续屏幕读取需要用户授权的系统录屏流程，真正跨 App 的悬浮插件需另行设计 TrollStore 注入方案。
