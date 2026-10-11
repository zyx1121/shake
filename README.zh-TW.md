<!-- 翻譯自 README.md @ docs/readme-template-v2。只翻 "For AI agents" 以上的章節，英文版更新時一起改。 -->

<div align="center">

<h1>shake</h1>

<p><strong>搖一搖游標，底下的介面元素就會亮起來，交給你的 SwiftUI 元件。</strong></p>

[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?style=flat-square&logo=apple)](Package.swift)
[![License](https://img.shields.io/github/license/zyx1121/shake?style=flat-square)](LICENSE)

[English](README.md) | **繁體中文** | [简体中文](README.zh-CN.md)

</div>

```
shake (≥4 reversals, ≥200px, under 0.4s) → dim + spotlight → left-click captures → right-click pins

[DebugLog] shake #1 overlay=shown
[DebugLog] captured #1 text: "Export to PDF"
[DebugLog] overlay pinned=true
```

macOS 只把搖晃游標拿來放大指標。shake 給這個手勢新的用途：在任何地方搖一搖，游標底下的元素就會亮起來，交給你接上的 SwiftUI 元件處理。內建的參考元件是點擊擷取。它是 Google Magic Pointer 的本機版本，用的是你自己的技術。

## 功能

- **偵測搖晃**：0.4 秒內方向改變 4 次以上，游標移動 200 px 以上。
- **變暗並打光**：所有螢幕變暗，一個打光框跟著游標底下的元素。
- **點擊擷取**：左鍵點擊會擷取元素，有文字就存文字，沒有就用 ScreenCaptureKit 截圖。
- **右鍵釘住**：浮層會留著，讓你移到擷取列整理內容。
- **待在選單列**：狀態圖示會打開除錯面板，顯示狀態、權限和事件紀錄。

## 快速開始

```sh
git clone https://github.com/zyx1121/shake && cd shake
make run
```

`make run` 會建置、打包，並用鑰匙圈裡的 Apple Development 憑證簽章。要用自己的憑證，改 Makefile 裡的 `SIGN_ID`。macOS 詢問時允許輔助使用和螢幕錄製，再到任何視窗上搖一搖游標。

建置需要 Xcode 26、Swift 6 和 macOS 14 以上。

## 使用方式

加上你自己的元件：

1. 寫一個接收 `env: OverlayEnvironment` 的 SwiftUI view，並提供 `component(env:)` 工廠：

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

2. 在 `OverlayEnvironment` 的 `removeAsset`、`copyAsset` 旁邊加上你需要的狀態或指令。
3. 在 `ShakeCoordinator.init` 把元件加進陣列：

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

高度會自動疊加，面板也會自己調整大小。元件不會碰到 coordinator 或其他元件。

## 設定

| 權限 | 用途 |
|------|------|
| 輔助使用 | 點擊攔截用的 `CGEventTap`，以及讀取游標底下元素的 `AXUIElementCopyElementAtPosition` |
| 螢幕錄製 | 截取沒有文字的元素用的 `SCScreenshotManager` |

除錯面板會顯示兩項權限，並附上前往「系統設定」的連結。固定的 Team ID 讓重新建置後不必重新授權。

## 運作方式

```
Sources/Shake/
├── App/        coordinator, app delegate and entry point
├── Core/       Asset, OverlayInfo, SelectionSession, DebugLog, PermissionMonitor
├── Capture/    ShakeDetector, ClickInterceptor, AXProbe, Capturer
├── Overlay/    OverlayPanel, OverlayEnvironment, OverlayView, DimOverlayController, FollowOverlayController
│   └── Components/   ElementHeader, CaptureTray: your components go here
└── Status/     DebugMonitorView
```

`Overlay/Components/` 以外都是框架。元件只會用到 `OverlayEnvironment` 和 `AnyOverlayComponent`。

## 限制

- 這是 fork 下來直接跑的 App，不是可以 import 的 Swift 套件。
- 個人專案，只有一位貢獻者，不保證 API 穩定。

## 其他

給 AI agent 的結構化資訊與開發說明在[英文版](README.md#for-ai-agents)。

## 授權

[MIT](LICENSE)
