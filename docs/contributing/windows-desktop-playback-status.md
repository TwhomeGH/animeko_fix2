# Windows 桌面播放鏈路調查現狀與未決事項（交接文檔）

> 本文記錄 animeko fork 在 **Windows 桌面**上播放器（mpv / VLC）的完整調查結果、播放鏈路架構、
> 以及所有**尚未處理**的行為。目的是讓後續接手者（人或 AI session）不必重走這次的冤枉路。
> 最後更新：2026-08-30。

---

## 1. 一句話結論（2026-08-30 更新：**已有低成本修法**）

**mpv 在無 DX12 機器可以修**：設 `-Dskiko.renderApi=OPENGL`（JVM system property）即讓 mediamp-mpv 0.3.2
走其**內建的 `WindowsOpenGLSurfaceBackend`**（WGL/OpenGL readback），**完全不 crash、全功能可用**。
已用 `MpvVerify` selftest 驗證 **PASS**（Ready → 播放前進 → 暫停凍結 → seek → MediaEnded → 重播，硬解碼
`d3d11va-copy` 仍工作）。**不需要接 VLC**。

根因回顧：mpv 在 Windows 預設走 `gpu-context d3d11`（需要 Skiko Direct3D/DX12 interop）。Skiko 的
Windows render API 偏好是 `ANGLE > DIRECT3D > OPENGL`；本機 GT 710（Kepler，FL 11_0）建不出 DX12/ANGLE
device → **window 實際落到 OpenGL**，但 mediamp 在讀 `SkikoProperties.getRenderApi()` 時判成 DIRECT3D →
誤選 `D3D11SurfaceRingBackend` → `SkiaDirectXInterop.currentRedrawer()` 發現 window 是 OpenGL → 拋
`Unsupported Skiko redrawer ...WindowsOpenGLRedrawer`。**強制 OPENGL 讓「mediamp 讀到的」與「window 實際的」一致**
即修復。這不是環境無法克服的限制，而是**選擇不一致**造成的 bug；VLC backend 仍是備案（見 §4/§6），但非必要。

---

## 1.5 已驗證的修復：強制 `skiko.renderApi=OPENGL`

**作法**（擇一，二選一是 JVM 層級，三會在 animeko fork 內自動化）：

1. **JVM 參數**：啟動時加 `-Dskiko.renderApi=OPENGL`
   - dev run：可設環境變數 `JAVA_TOOL_OPTIONS=-Dskiko.renderApi=OPENGL`（影響整支 JVM）
   - packaged：在 `Ani.cfg` 的 `[JavaOptions]` 加 `-Dskiko.renderApi=OPENGL`，或在啟動 wrapper 設定
2. **程式內**（`SkikoProperties` system property）：在 Skiko 初始化前
   `System.setProperty("skiko.renderApi", "OPENGL")`
3. **animeko fork 自動化（未實作）**：只在偵測到「無 DX12」時才強制 OPENGL，正常 DX12 機器保持預設
   （避免影響其他用戶）。可在 `AniDesktop` 啟動早期用「DX12 探測」決定是否設此 property。

**注意**：`skiko.renderApi=OPENGL` 是**全域渲染**設定（整個 Compose UI 走 OpenGL，非僅 mpv）。
對本機這種「Skiko 已實際落 OpenGL」的機器無額外損失；但對正常 DX12 機器，強制 OPENGL 會捨棄硬體加速，
所以**自動化必須只在無 DX12 時觸發**。

**驗證結果**（`MpvVerify` selftest，本機）：
```
[mpv/mediampv] WGL fallback context ready: NVIDIA GeForce GT 710 ... GL 3.3.0
[mpv/mediampv] rendering 983x704 via OpenGL/WGL readback surface
[selftest] reached Ready
[selftest] playback advancing / pause freezes / seek landed / natural end / replay
[selftest] PASS
[mpv/vo/libmpv] mpv_render_context_render() not being called or stuck.  ← 無頭測試正常訊息
```

---

## 2. 環境事實（本機）

| 項目 | 值 |
|------|-----|
| OS | Windows 10 22H2 (Build 19045) |
| GPU | NVIDIA GeForce GT 710（Kepler GK208，**僅 DX feature level 11_0**）+ 2 個虛擬顯示介面卡（Parsetc Virtual Display Adapter、Virtual Display Driver）→ **Skiko 選 OpenGL** |
| JAVA_HOME | 指向 Adoptium JDK 21（無 JCEF）→ **必須用 JBR 21 執行/打包**（見 §7） |
| Gradle | 9.3.1；`gradle.properties` 已設 `org.gradle.java.home` → JBR（含 JCEF） |
| mediamp | 固定在 **0.3.2**（`gradle/libs.versions.toml:93`） |
| 系統 | **未安裝 VLC**；有 ffmpeg（WinGet） |

---

## 3. 播放鏈路架構（animeko 桌面）

```
VideoPlayer.desktop.kt (desktopMain)
   └─ when(player) { is MpvMediampPlayer -> MpvMediampPlayerSurface(...)
                     else -> error("Unsupported desktop MediampPlayer") }   ← 硬編碼 mpv，無 fallback
DesktopModules.kt:154-158
   single<MediampPlayerFactory<*>> {
        MediampPlayerFactoryLoader.register(MpvMediampPlayerFactory())
        MediampPlayerSurfaceProviderLoader.register(MpvMediampPlayerSurfaceProvider())
        MediampPlayerFactoryLoader.first()
   }                                                                        ← 選擇點 = Koin single bean
```

- **backend 選擇是編譯期寫死（mpv-only）**，沒有 runtime selector，`PlayerKernelConfig` 也沒有 backend 欄位。
- **桌面編譯/執行用的是 released `org.openani.mediamp:mediamp-*:0.3.2` jar（Maven），不是 `C:\Users\Co\mediamp` checkout**。
  composite `includeBuild(mediamp)` 被停用，因為 `local.properties` 沒有 `ani.build.mediamp.path`
  （`settings.gradle.kts:179` 以 `findLocalProperty("ani.build.mediamp.path")` 控門）。
  → **改 checkout 源碼對 animeko 無效**，除非重新開啟 composite build。
- `MpvMediampPlayer`/`MpvMediampPlayerSurface`/`SkiaDirectXInterop` 都**在 released jar 內，animeko fork 無法修改**。

### 播放器建立點
- `EpisodeViewModel.playerStateFactory` 注入 `single<MediampPlayerFactory<*>>`，在 `EpisodeViewModel.kt:268` 附近建立 player。
- native 準備：`AniDesktop.prepareMpvLibraries(composeResDir)` → `initializeJcefAndPlayerBackend`
  （`AniDesktop.kt:157-189`, `394-412`）。`DesktopNativeStartup.kt:15-39` 決定 JCEF/VLC 載入順序。

---

## 4. mpv 在 Windows 為何壞（已 100% 定位）

錯誤（來自 released `mediamp-mpv:0.3.2`）：
```
java.lang.IllegalStateException: Unsupported Skiko redrawer org.jetbrains.skiko.redrawer.WindowsOpenGLRedrawer.
The mpv D3D11 render path requires Skiko's Direct3D backend
    at ...mediamp.mpv.utils.SkiaDirectXInterop.currentRedrawer(SkiaDirectXInterop.kt:53)
    at ...MpvMediampPlayerSurface...draw   （Compose draw 階段）
```

連鎖：
1. mpv 在 Windows 用 **D3D11** render context（`Using Direct3D 11.1 runtime` —— **成功**，mpv 自帶 D3D11）。
2. mpv 要把每 frame interop 進 Skiko surface → `SkiaDirectXInterop.getDirectContext` 需要 **Skiko 的 DX12 surface**。
3. 本機 **Skiko 建 DX12 device 失敗**（`Failed to create DirectX12 device`）→ fallback 到 **OpenGL redrawer**。
4. 發現不是 Direct3D → throw → 播放卡在 `[selftest] start`，app 崩潰/退出。

**關鍵誤區（先前 session 一直搞錯）**：
- 「Windows 一定有 Direct3D，為什麼失敗？」→ **Skiko 的 Direct3D backend 是 DX12-only**（`SkiaDirectXInterop` 硬綁 DX12），
  DX11/10/9 對它沒用。
- 「強制 `-Dskiko.renderApi=DIRECT3D`」→ **無效**，本機 DX12 device 就是建不出（GT710 僅 FL11_0 + 虛擬顯示）。
- 這不是環境設定能修，**換顯卡或換 backend 才能解**。

### `MpvVerify` 無頭自測（最有價值的驗證工具）
- `MpvVerify.kt` 有 `-Dani.mpv.selftest=true` 無頭自測，用 dev-run native（**不依賴打包**）。
- `-Dani.seekverify.video=<路徑>` 指定測試影片（約需 60s）。
- 用 `./gradlew :app:desktop:run -Pani.desktop.mainClass=...MpvVerifyKt -Pani.mpv.selftest=true -Pani.seekverify.video=...`
  （`ani.mpv.selftest` 走 `-P` gradleProperty，`ani.seekverify.video` 需在 `configureDevProperties()` 手動加 systemProperty 透傳）。
- 已用它**證明**：mpv D3D11 render 成功、hwdec `d3d11va` 載入成功，唯獨卡在 Skiko interop → crash。
- log 位置（packaged app）：`%APPDATA%\Him188\Ani\data\logs\app.log`。

---

## 5. 打包現狀（Windows）

- **debug 打包 `createDistributable` 不跑 `unpackComposeDesktopNativeLibraries()`**（只在 `createReleaseDistributable`
  的 doLast 觸發，`build.gradle.kts:350-356`）→ **debug pack 不含 mpv/ffmpeg native**（`Ani/app` 沒 dll）。
- `scripts/build-desktop-distributable.ps1`（Windows 一鍵打包，English-only comments —— 見 §7 編碼坑）。
- 產物：`app/desktop/build/compose/binaries/main/app/`（`Ani.exe` + runtime + JCEF + classpath）。
- `app/desktop/appResources/`：**Mac/Linux 已放 libVLC**（macos-x64, linux-x64），**Windows-x64 只有 `ani_update.exe`，沒有 libVLC**。

---

## 6. VLC backend：上游已棄用（重大阻礙）

### 上游事實
| artifact | 最新版本 | 狀態 |
|----------|---------|------|
| `mediamp-mpv` | **0.3.2**（2026-08）| 同步，可用 |
| `mediamp-vlc` | **0.2.1**（2026-07）| **停在 0.2.1，之後不再發布** |
| `mediamp-backend-vlc`（舊 org）| 0.0.6（2024）| 更舊 |

- **`mediamp-vlc:0.2.1` 依賴 `mediamp-api-desktop:0.2.1`**；animeko 用 **mediamp 0.3.2**（state-model 破壞性改動）。
  → **released mediamp-vlc 與 mediamp 0.3.2 二進位不相容，不能直接加依賴**（會 `AbstractMethodError`）。
- 舊名 `mediamp-backend-vlc` / VLC 相關在 Maven 的版本線已死。**確認：上游已放棄 VLC 播放 backend**（VlcMediampPlayer 也散落未接）。

### 自寫方案（已確認可行，需自寫播放器整合）
- **不引 `mediamp-vlc:0.2.1`**，直接在 animeko fork 內自寫 `VlcMediampPlayer : AbstractMediampPlayer`（對 mediamp 0.3.2），
  用 vlcj（`uk.co.caprica.vlcj:4.8.2`，Maven 已在 cache）+ libVLC native。
- **必須 extends `AbstractMediampPlayer`，不要 implement `MediampPlayer`**（後者 `@SubclassOptInRequired` + 不適合繼承）。
- 0.3.2 SPI 重點（詳見 explore 報告）：
  - 抽象擴展點：`openImpl(MediaData, PlaybackSessionHandle, playWhenReady, startPositionMillis): OpenResult`、
    `playImpl/pauseImpl/seekImpl(ms, gen)/setRateImpl/stopImpl/closeImpl`。
  - 透過 `PlaybackSessionHandle.reportTransport/notifyEnded/notifyError/notifySeekCompleted/notifyProperties/notifyPosition` 回報，
    **不要直接改 `state.value`**。
  - `impl: Any` 回傳 vlcj 的 `EmbeddedMediaPlayer`。
  - MediaData 處理：`UriMediaData`（`player.media().play(uri, *opts)`）、`SeekableInputMediaData`（`SeekableInputCallbackMedia` 橋接）。
- **渲染**：複刻 `SkiaBitmapVideoSurface`（`VideoSurface` subclass + `CallbackVideoSurface`，
  `RV32BufferFormat`(BGRA) → `installPixels(ImageInfo(w,h,BGRA_8888,PREMUL))` → `mutableStateOf<ImageBitmap?>`
  → Compose `Canvas` drawImage + `FrameSizeCalculator`（FIT/STRETCH/CROP））。
  **純 CPU pixel copy，無 texture，不碰 Skiko DX12** —— 正是能繞過 mpv 問題的原因。
- **factory/provider**：`VlcMediampPlayerFactory : MediampPlayerFactory<VlcMediampPlayer>` + `VlcMediampPlayerSurfaceProvider`，
  註冊 `META-INF/services/...`（MediampPlayerFactory / MediampPlayerSurfaceProvider）＋在 `DesktopModules.kt:154-158` 註冊。
- **native discovery**：libVLC 放 `appResources/<os>-<arch>/lib`（已確認 Linux/Mac 有）＋
  `DiscoveryDirectoryProvider` ServiceLoader 機制（vlcj 4.8.2 **沒有** `addDiscoveryDirectory`，用 ServiceLoader provider）。
  「自包含」= 也把 libVLC Windows DLL 放進 `appResources/windows-x64/lib`。
- **flex 傳給使用者選項**：`PlayerKernelConfig` 新增 backend 欄位（AUTO/MPV/VLC），AUTO = 偵測 DX12 是否可用
  （`D3D12CreateDevice` 探測，JNA）→ 可用用 mpv，不可用 fallback VLC。

### VLC 最終設計（使用者已拍板：自動偵測 + 找不到就引導安裝）
1. 自動偵測 DX12/probe → 決定 backend
2. 若非 auto → 用使用者指定 backend
3. 若指定 VLC 但 libVLC 找不到 → **引導安裝**（非靜默裝）

---

## 7. 已踩過的坑（交接必讀，避免重蹈）

### Windows/編碼/殼層
- **PowerShell 5.1 讀無 BOM UTF-8 .ps1 用 ANSI/GBK**，中文註解會錯解並**靜默破壞關鍵賦值** →
  Windows .ps1 **只能用英文明註解**或存 UTF-8 BOM（記憶 #28）。
- `.properties` 的 `\` 是 escape：`org.gradle.java.home=C:\\...`（雙反斜線）→ PowerShell 轉真路徑要 `-replace '\\\\','\'`。
- 巢狀引號下 `$` 變數（`$_`、`$var`）常被外層 shell 吃掉 → 一律寫成 `.ps1`/script 檔案執行，別用 inline PowerShell。
- `cmd /c "...$var..."` 與 PowerShell cmdlet 衝突會報「已經指定 command 參數」。

### JCEF / JDK
- `org.cef.*` 類**只在打包 runtime 的 jcef module**（從 JBR 21 jlink），
  `:app:desktop:run`（dev run）**永遠沒有 JCEF**（classpath 無 jcef jar）→ 線上播放只能靠打包 build 驗證。
- **執行/打包 JVM 必須是 JBR 21（含 JCEF）**，Adoptium 會 `NoClassDefFoundError: org/cef/handler/CefRequestHandlerAdapter`。

### 打包
- debug `createDistributable` 不觸發 `unpackComposeDesktopNativeLibraries()` → mpv/ffmpeg native 缺失（`mediampv.dll` 找不到）。

---

## 8. 未決事項 / 未處理行為（TODO 交接清單）

- [ ] **VLC backend 尚未實作**（自寫 `AbstractMediampPlayer` 子類 + surface + factory，見 §6）。
- [ ] **libVLC Windows DLL 尚未入 appResources**（需 3.0.x 的 `libvlc.dll`/`libvlccore.dll`/`plugins`）→ 自包含前置。
- [ ] **`PlayerKernelConfig` backend 欄位尚未加**（AUTO/MPV/VLC）。
- [ ] **`DesktopModules.kt:154` 尚未改成依 backend 選擇**。
- [ ] **`VideoPlayer.desktop.kt:24` 尚未加 `is VlcMediampPlayer` 分派**。
- [ ] **DX12 偵測工具尚未寫**（`D3D12CreateDevice` probe）。
- [ ] **mediamp checkout composite build 停用**（`local.properties` 無 `ani.build.mediamp.path`）——已知、有意維持現狀。
- [ ] **debug 打包缺 native**（`createDistributable` 不 unpack native）——若需 debug pack 播放要先修。
- [ ] **Skiko 強制 DX12 WARP 是否可行未查證**（若可行，可能不用 VLC，直接讓 mpv 用 WARP DX12）。
- [ ] **`MpvVideoEnhancementController`（Anime4K）是 mpv-only**——若 fallback VLC，此功能在 VLC 無對應（未處理降級）。

---

## 9. 相關記憶（跨 session）

- 記憶 #30：desktop 執行用 released mediamp 0.3.2 jar，非 checkout（composite 停用）。
- 記憶 #29/#27/#33/#34：mpv D3D11 + Skiko DX12 + OpenGL fallback 根因（本文 §4 是完整版）。
- 記憶 #31/#32：只註冊 mpv、設計是「mpv 預設 + 非 D3D fallback VLC」。
- 記憶 #35/#36：ffmpeg 非播放器；VLC 需 libVLC native。
- 記憶 #28：.ps1 編碼坑。
- 記憶 #16/#23/#24：JBR/JCEF/java.home 關係。
