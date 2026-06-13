# 硬體加速解碼 (Hardware-Accelerated Video Decoding)

## 概述

Ani 的 Desktop 版本使用 VLC (libvlc + vlcj) 作為播放後端，預設**未啟用** GPU 硬體加速。這表示影片解碼完全由 CPU 負責（軟解），對於 GPU 較弱的機器（如 NVIDIA GT 710）或較低階的 CPU，可能導致播放不流暢或 CPU 使用率偏高。

此功能在 VLC 的 `MediaPlayerFactory` 初始參數中加入 `--avcodec-hw=xxx`，讓 VLC 嘗試使用 GPU 進行影片解碼，以減輕 CPU 負擔。

## 適用平台

- **僅 Desktop (Windows/macOS/Linux)**
- Android / iOS 使用各自平台的播放器（ExoPlayer / AVKit），不受此設定影響

## 設定方式

1. 開啟 Ani → 設定 → **播放器**
2. 找到 **「硬體加速影片解碼」** 開關
3. 開啟後可選擇解碼模式：
   - **DXVA2**（Windows 舊版，相容性較好）
   - **D3D11VA**（Windows 新版，效能較好）
   - **自動**（讓 VLC 自行選擇）
4. **需重新啟動應用程式**後生效

## 技術實作

### 修改的專案

| 專案 | 修改內容 |
|------|---------|
 | `mediamp-vlc` | `VlcMediampPlayer` 建構子新增 `factoryArgs` 參數，傳遞給 `MediaPlayerFactory` |
 | `mediamp-vlc` | `VlcMediampPlayerFactory` 建構子新增 `factoryArgs` 參數 |
 | `animeko` | 新增 `VideoPlayerSettings` data class（含 `enableHardwareDecoding`、`hwdecMode`） |
 | `animeko` | `SettingsRepository` 新增 `videoPlayerSettings` |
 | `animeko` | `DesktopModules.kt` 改用動態 Factory，每次建立 Player 時讀取目前設定 |
 | `animeko` | 設定 UI 新增硬解開關 + 模式下拉選單（桌面版限定） |

### VLC 參數

- 啟用硬解：`--avcodec-hw=dxva2` 或 `--avcodec-hw=d3d11va`
- 關閉硬解：不傳入任何 `--avcodec-hw` 參數（VLC 預設為 `none`）
- 參數作為 **LibVLC 全域初始化參數**（傳給 `MediaPlayerFactory`），非 per-media 選項

### Composite Build

Ani（animeko）透過 Gradle Composite Build 使用本地修改的 `mediamp-vlc`：

```properties
# local.properties
ani.build.mediamp.path=C:/path/to/mediamp
```

```kotlin
// settings.gradle.kts
findLocalProperty("ani.build.mediamp.path")?.let { mediampPath ->
    includeBuild(mediampPath) {
        dependencySubstitution {
            substitute(module("org.openani.mediamp:mediamp-vlc"))
                .using(project(":mediamp-vlc"))
        }
    }
}
```

## 注意事項

1. **GT 710 限制**：僅支援 **H.264** DXVA2 硬解。不支援 HEVC (H.265)、VP9、AV1 硬解。
2. **Callback Surface 相容性**：Ani 使用 `SkiaBitmapVideoSurface`（VLC callback 模式），硬解仍可正常運作——VLC 會將 GPU 解碼後的 frame copy-back 到系統記憶體，再交給 Skia 渲染。
3. **設定需重啟**：因 `VlcMediampPlayer` 在建構時就建立 `MediaPlayerFactory`，改變設定後需重啟 App 才能套用新的 VLC init 參數。
4. **僅對 VLC 後端有效**：若未來 Ani 改用 mpv 或其他後端，需另外實作對應的硬解支援。
