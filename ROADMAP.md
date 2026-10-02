# Pocket Agent 路线图

## 方向

先把应用内 AI 对话做成稳定、可持续使用的工具，再加入用户明确选择的图片输入。全局悬浮和持续屏幕读取单独做设备可行性验证，验证通过前不把它们当作普通 iOS 功能承诺。

## 当前基线

- v0.1 首版已由 GitHub Actions 成功构建并上传 IPA：[构建记录](https://github.com/QianHuanHuan/trapi/actions/runs/37015056089)。
- 支持多个服务商配置，但请求格式目前只有 OpenAI Chat Completions 兼容协议；每个配置可指定 URL、模型和 Key。
- API Key 存 Keychain；聊天记录目前只在运行期间保留。
- 首版仅有应用内聊天，没有全局浮窗、图片输入、流式输出或工具调用。

## v0.2：日常对话基础

建议下一步实现这一阶段。

1. **会话记录**：本地保存多轮会话；新建、切换、重命名、删除会话；删除前明确告知会清除本地记录。
2. **流式回复**：解析服务端 SSE 增量内容，显示正在生成状态，支持停止生成、失败重试。
3. **连接与错误处理**：增加“测试连接”；解析常见服务端错误；对 URL、模型名、空 Key 给出可操作提示；所有日志隐藏 Key。
4. **配置可靠性**：检查 Keychain 写入/删除结果，支持清除 Key；配置和会话在应用重启后仍可恢复。
5. **首版整理**：确定正式应用名与唯一 Bundle ID，再替换 `com.example.pocketagent`；设置版本号和应用图标。

验收：重启后配置和会话都还在；至少用一个真实 OpenAI 兼容端点完成连续对话、停止、重试和错误场景；构建出新的 IPA。

## v0.3：服务商适配器

- 把网络协议抽象为 Provider Adapter，配置中记录协议类型和能力，而不是只靠不同 Base URL。
- 保留 OpenAI-compatible adapter，覆盖兼容端点；后续逐个增加 Anthropic Messages、Google Gemini 等原生协议 adapter。
- 模型列表先允许手动输入；连接测试通过后，再决定是否维护远程模型列表。
- 每个 adapter 单独检查文本、流式输出、工具调用和图片能力；不假设不同服务商的 API 完全一致。

验收：至少两个不同协议的服务商可分别配置和切换；切换后请求格式、Key 和模型保持各自独立。

## v0.4：用户选择图片后提问

- 用系统 Photos Picker 让用户主动选择截图或照片；只读取用户选中的项目。
- 发送前显示缩略图和确认状态，支持移除；压缩图片并限制尺寸；仅在用户发送后上传给当前选中的模型服务。
- 把图片消息能力放进 Provider Adapter；不支持图像输入的模型显示明确提示。
- 约定图片的内存与临时文件生命周期，不把图片内容写入普通日志。

验收：用户选一张截图、确认发送后，视觉模型可回答画面问题；取消选择或移除图片时，图片不会发出。

## v0.5：轻量 Agent Core

- 将消息、会话、模型请求和工具调用拆成独立模块，保留 Pi 的 Provider/Model/Agent/Tool/Session 思路，不嵌入完整 Pi Coding Agent。
- 先做少量明确、可撤销的本地工具；每次工具调用在界面展示用途和结果。暂不开放任意 shell、文件系统或后台操作。
- 加入 system prompt、上下文长度控制、取消操作，以及工具调用失败后的恢复。

验收：至少一个支持工具调用的 Provider 能完成一次“模型请求工具—用户看到调用—工具返回结果—模型总结”的闭环；用户可以随时停止。

## 独立可行性验证：屏幕读取

1. 先记录目标设备型号、iOS 版本、TrollStore 版本和是否越狱；在目标设备上验证系统 picker、授权提示、前后台状态和可取得的帧数据。
2. 首选系统明确授权、用户主动启动/停止的屏幕共享；每次只抽取少量帧用于提问，不持续上传视频。
3. Apple 当前 iOS ScreenCaptureKit 示例要求 iOS 27 或更高；TrollStore 项目当前列出的支持范围最高到 iOS 17.0。两者对目标版本没有交集，因此不能把新版 ScreenCaptureKit 当作 TrollStore 设备的现成方案。旧 ReplayKit 捕获 API 已被 Apple 标为弃用；是否能满足目标设备的跨应用采集，必须单独实测。
4. 若目标设备上没有可用、由用户明确启动的跨应用采集路径，保留 Photos Picker / 分享扩展发送截图的方案，不做静默读取。

## 独立可行性验证：全局悬浮

普通 SwiftUI App 的窗口只属于自身应用。结合 iOS 16.1 + TrollStore，现有方案分三档：

1. **PiP 兼容入口**：AVKit 可把视频帧放在系统管理的 PiP 小窗里，能跨 App 悬浮，但它是媒体播放窗口，不是任意 SwiftUI 面板。视频通话样式 PiP 不接收自定义触摸事件，适合展示短答/状态并点击返回主 App，不适合作完整聊天框。[Apple PiP 文档](https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-for-video-calls)
2. **按 App 注入**：TrollFools 是面向 TrollStore 的 in-place dylib/tweak 注入器，项目说明预期支持 iOS 14–17。可将我们的浮层插件注入被选中的普通第三方 App，在该 App 前台时创建同进程浮层；这不是所有 App 通用的一次安装方案，也不能把此能力延伸到 SpringBoard。[TrollFools](https://github.com/Lessica/TrollFools)
3. **SpringBoard 系统级浮层**：TrollStore 本身不能注入系统进程；RootHide Bootstrap 的 release notes 提供了 iOS 16.0–17.0 的 SpringBoard tweak injection 支持，Serotonin 项目也覆盖 iOS 16.0–16.6.1，并要求 TrollStore、Bootstrap 和 ElleKit。这是 iOS 16.1 上最接近真正全局浮窗的路，但会引入额外系统组件、重启/恢复流程和兼容性风险，不等于普通 IPA 功能。[RootHide Bootstrap releases](https://github.com/roothide/Bootstrap/releases)、[Serotonin](https://github.com/SerotoninApp/Serotonin)、[TrollStore 能力边界](https://github.com/opa334/TrollStore)

### 推荐 PoC 顺序

1. 针对已确认的 iPhone 13 Pro / iOS 16.1（arm64e），先做一个只显示/拖动/关闭面板的 SpringBoard 测试浮球，不调用模型、不抓屏；安装前确认实际使用的 rootless tweak 注入环境及版本。
2. 再做打开聊天面板、拖动、跨 App 返回/隐藏和重启恢复；如果 SpringBoard tweak 不稳定，改走 TrollFools 注入一个普通测试 App 的局部浮层。
3. 最后才验证“当前画面提问”。被注入的 App 可以尝试在用户点按后读取自己前台窗口的快照；这只覆盖该 App。全屏跨 App 画面在 iOS 16.1 上需要另行验证 ReplayKit/系统级方案，不能套用 iOS 27 的 ScreenCaptureKit 示例。
4. 每次采集都要求明确点按、显示预览、再发送；不后台连续采集，不默认自动上传。

若不进入 Bootstrap/系统 tweak 路线，可用 PiP 显示简短回答，并通过 Share Extension、快捷指令或从目标 App 注入插件提交截图/文本；这是更易维护但交互受限的后备方案。

## 推荐顺序

1. v0.2：会话持久化、流式回复、配置可靠性。
2. v0.3：Provider Adapter 与第二种原生 API 协议。
3. v0.4：用户选择图片后的视觉问答。
4. v0.5：小范围 Agent 工具调用。
5. 并行做屏幕采集和全局浮窗 PoC；按目标 iPhone 的真实 iOS 版本决定是否继续。

## 决策门槛

- 在选定正式 Bundle ID 前，先确认项目名和是否只用于个人 TrollStore 安装。
- 在开始屏幕/全局浮窗开发前，记录目标设备型号和完整 iOS 版本号。
- 每个阶段结束都通过 GitHub Actions 产出新 IPA，并在目标设备上安装验证后再进入下一阶段。
