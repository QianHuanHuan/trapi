# Pocket Agent

一个面向 TrollStore 测试的 iOS AI 助手初版。源码可以在 Windows 编辑，GitHub Actions 使用 macOS/Xcode 构建 IPA。

## 当前功能

- 多个模型服务商配置，可填写名称、API Base URL、模型名和 API Key。
- 通过 OpenAI Chat Completions 兼容接口发送对话。
- API Key 保存在 iOS 钥匙串；服务商配置保存在本机偏好设置。
- 首版对话界面、请求状态和错误提示。

## 构建 IPA

推送到 GitHub 的 main/master 分支会自动构建；也可以在 Actions 页面手动运行 **Build TrollStore IPA**。完成后从该次 workflow 的 Artifacts 下载 `PocketAgent-unsigned-ipa`，解压取得 IPA，再通过 TrollStore 安装。首次构建的 bundle id 是 `com.example.pocketagent`。

首版已推送到 GitHub，首次 Actions 构建成功并上传了 IPA artifact。以后推送到 main/master 会自动构建；也可以在 Actions 页面手动触发。Windows 环境不运行 Xcode，构建由 GitHub 的 macOS runner 完成。

后续开发顺序和屏幕读取/全局悬浮的设备限制见 [ROADMAP.md](ROADMAP.md)。

## 功能边界

普通 iOS App 不能在其他 App 上任意显示全局浮窗，也不能静默读取其他 App 当前屏幕。当前版本提供应用内对话。之后可先加入用户主动选择截图/照片的视觉问答；持续屏幕读取需要用户授权的系统录屏流程，真正跨 App 的悬浮插件需另行设计 TrollStore 注入方案。
