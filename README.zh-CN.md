<!-- 翻译自 README.md @ docs/readme-template-v2。只翻译 "For AI agents" 之前的章节，英文版更新时一起改。 -->

<div align="center">

<h1>shake</h1>

<p><strong>晃一晃光标，下面的界面元素就会亮起来，交给你的 SwiftUI 组件。</strong></p>

[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?style=flat-square&logo=apple)](Package.swift)
[![License](https://img.shields.io/github/license/zyx1121/shake?style=flat-square)](LICENSE)

[English](README.md) | [繁體中文](README.zh-TW.md) | **简体中文**

</div>

```
shake (≥4 reversals, ≥200px, under 0.4s) → dim + spotlight → left-click captures → right-click pins

[DebugLog] shake #1 overlay=shown
[DebugLog] captured #1 text: "Export to PDF"
[DebugLog] overlay pinned=true
```

macOS 只把晃动光标拿来放大指针。shake 给这个手势新的用途：在任何地方晃一晃，光标下的元素就会亮起来，交给你接上的 SwiftUI 组件处理。内置的参考组件是点击捕获。它是 Google Magic Pointer 的本地版本，用的是你自己的技术栈。

## 功能

- **检测晃动**：0.4 秒内方向改变 4 次以上，光标移动 200 px 以上。
- **变暗并打光**：所有屏幕变暗，一个打光框跟着光标下的元素。
- **点击捕获**：左键点击会捕获元素，有文字就存文字，没有就用 ScreenCaptureKit 截图。
- **右键固定**：浮层会保留，让你移到捕获栏整理内容。
- **待在菜单栏**：状态图标会打开调试面板，显示状态、权限和事件记录。

## 快速开始

```sh
git clone https://github.com/zyx1121/shake && cd shake
make run
```

`make run` 会构建、打包，并用钥匙串里的 Apple Development 证书签名。要用自己的证书，修改 Makefile 里的 `SIGN_ID`。macOS 询问时允许辅助功能和屏幕录制，再到任何窗口上晃一晃光标。

构建需要 Xcode 26、Swift 6 和 macOS 14 以上。

## 使用方法

加上你自己的组件：

1. 写一个接收 `env: OverlayEnvironment` 的 SwiftUI view，并提供 `component(env:)` 工厂：

   ```swift
   // Sources/Shake/Overlay/Components/AskAI.swift
   struct AskAI: View {
       let env: OverlayEnvironment
       static let height: CGFloat = 64
       static func component(env: OverlayEnvironment) -> AnyOverlayComponent {
           AnyOverlayComponent(height: { height }, view: { AskAI(env: env) })
       }
       var body: some View {
           // read env.currentElement and env.session.assets here
       }
   }
   ```

2. 在 `OverlayEnvironment` 的 `removeAsset`、`copyAsset` 旁边加上你需要的状态或命令。
3. 在 `ShakeCoordinator.init` 把组件加进数组：

   ```swift
   self.overlay = FollowOverlayController(
       env: env,
       components: [
           ElementHeader.component(env: env),
           CaptureTray.component(env: env),
           AskAI.component(env: env),
       ]
   )
   ```

高度会自动叠加，面板也会自己调整大小。组件不会碰到 coordinator 或其他组件。

## 配置

| 权限 | 用途 |
|------|------|
| 辅助功能 | 点击拦截用的 `CGEventTap`，以及读取光标下元素的 `AXUIElementCopyElementAtPosition` |
| 屏幕录制 | 截取没有文字的元素用的 `SCScreenshotManager` |

调试面板会显示两项权限，并附上前往“系统设置”的链接。固定的 Team ID 让重新构建后不必重新授权。

## 工作原理

```
Sources/Shake/
├── App/        coordinator, app delegate and entry point
├── Core/       Asset, OverlayInfo, SelectionSession, DebugLog, PermissionMonitor
├── Capture/    ShakeDetector, ClickInterceptor, AXProbe, Capturer
├── Overlay/    OverlayPanel, OverlayEnvironment, OverlayView, DimOverlayController, FollowOverlayController
│   └── Components/   ElementHeader, CaptureTray: your components go here
└── Status/     DebugMonitorView
```

`Overlay/Components/` 以外都是框架。组件只会用到 `OverlayEnvironment` 和 `AnyOverlayComponent`。

## 限制

- 这是 fork 下来直接运行的应用，不是可以 import 的 Swift 包。
- 个人项目，只有一位贡献者，不保证 API 稳定。

## 其他

给 AI agent 的结构化信息与开发说明见[英文版](README.md#for-ai-agents)。

## 许可证

[MIT](LICENSE)
