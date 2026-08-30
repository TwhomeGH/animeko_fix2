# 磁碟與記憶體診斷工具（Windows 開發環境）

本目錄收錄幾個小型的 PowerShell 腳本，用來診斷並釋放這台 Windows 機器上由
Gradle / Kotlin 工具鏈所佔用的磁碟與記憶體空間。它們純屬開發環境工具，與 app
本身的建置無關。

所有腳本**只做診斷、不刪除任何東西**。實際的清理指令請見下方
[清理指南](#清理指南)。

## 使用方法

在任意目錄執行（或帶完整路徑）：

```powershell
powershell -ExecutionPolicy Bypass -File .\system-diag.ps1
```

> 註：只有當機器的執行原則（execution policy）擋住本機腳本時才需要
> `-ExecutionPolicy Bypass`。**讀取**下列路徑不需管理員權限，刪除
> `C:\Users\Co\.gradle\...` 下的東西也不需要；但刪除 `C:\pagefile.sys` /
> `C:\hiberfil.sys` 則需要（這些腳本不會碰它們）。

## 腳本一覽

| 腳本 | 報告內容 | 何時使用 |
|------|----------|----------|
| `system-diag.ps1` | 總/可用 RAM、PageFile（配置 / 目前 / 峰值用量）、`C:\pagefile.sys` / `hiberfil.sys` / `swapfile.sys` 大小，以及 `~/.gradle` 下每個頂層目錄的大小 | 當 Java 記憶體看起來吃很兇，或 C 碟空間偏低時——先看整體概況 |
| `jdk-diag.ps1` | `~/.gradle/jdks` 下每個 JDK 的大小、`C:\Program Files\...` 常見位置已安裝的 JVM、專案宣告的 toolchain、以及 `%JAVA_HOME%` | 刪除任何 JDK 之前，確認哪些 Java 版本真的被引用 |
| `gradle-cache-diag.ps1` | `~/.gradle/caches` 下每個頂層目錄的大小，按 Gradle 版本分桶（`9.3.1`、`9.2.1`…），以及共用的 `modules-2` 等 | 清理 `~/.gradle/caches` 之前——判斷哪些分版本的 cache 已經過時 |
| `disk-space.ps1` | 快速顯示 C 碟已用 / 可用 GB，以及 `~/.gradle/jdks` 仍殘留的 JDK | 清理後快速確認空間 |

## 清理指南

以下是 C 碟剩下約 8 GB 時實際採用的流程。**務必先診斷，再只清掉真正沒用到的。**

### 1. 關閉駐留的 Gradle / Kotlin daemon（釋放 RAM）

build 結束後，Gradle 與 Kotlin daemon 仍會駐留並保留它們的 heap。在 24 GB 的機器上，
它們可能同時佔用數 GB。停止它們來釋放 RAM：

```powershell
cd C:\Users\Co\animeko
.\gradlew --stop
```

如果還有 Kotlin compiler daemon 存活，也一併強制結束（先查它的 PID）：

```powershell
taskkill /F /PID <kotlin-daemon-pid>
```

### 2. 限制 Gradle / Kotlin daemon 的 heap（避免 C 碟 pagefile 爆掉）

在 `gradle.properties` 中，daemon heap 已經從預設值調低：

```
org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8 -Dkotlin.daemon.jvm.options="-Xmx2048M"
```

這樣能讓 daemon 記憶體維持在較小範圍，build 期間不會把 C 碟的 pagefile
（`C:\pagefile.sys`，約配置 2.8 GB）推到緊繃。build 後用 `system-diag.ps1` 再次確認
pagefile **峰值**維持在低位。

### 3. 刪除 `~/.gradle/jdks` 下未使用的 JDK toolchain

Gradle 會為 build 碰到的每個 `jvm.toolchain.*` 自動下載對應的 toolchain JVM。
過時的就純粹是磁碟浪費（每個約 300 MB 到 1 GB）。判斷哪些能安全刪除：

1. 執行 `jdk-diag.ps1`，記下目前有哪些 JDK。
2. 檢查各專案實際需要的版本：
   - animeko：全部都是 `jvm.toolchain.version=21` 且 `vendor=jetbrains`
     （`app/desktop` 需要內含 JCEF 的 JetBrains Runtime 21）。
   - mediamp（以 composite build 被引入、跑在 animeko 的 Gradle 上）在
     build 腳本裡引用了 Java 11（`mediamp-test`、`mediamp-vlc-loader`）與 17
     （`ci-helper`、`buildSrc`），**但**這些模組不在 Windows 桌面的編譯路徑上——
     成功的 `:app:desktop:assemble` 從未要求過它們。
3. 保留 JetBrains 21（`jetbrains_s_r_o_-21-amd64-windows.2`，約 976 MB）。
4. 刪除未使用的 Adoptium 11 / 17：

```powershell
Remove-Item "C:\Users\Co\.gradle\jdks\eclipse_adoptium-11-amd64-windows.2" -Recurse -Force
Remove-Item "C:\Users\Co\.gradle\jdks\eclipse_adoptium-17-amd64-windows.2" -Recurse -Force
```

若未來真有 build 需要 11/17，早已啟用的 `foojay-resolver-convention` 外掛會自動
重新下載。

### 4. 刪除 `~/.gradle/caches` 下過時的 Gradle 版本 cache

`~/.gradle/caches/<版本>` 存放各 Gradle 版本的狀態。只有目前專案正在用的 Gradle
版本才重要；較舊的版本目錄是過時殘留。

先執行 `gradle-cache-diag.ps1`，再對照 wrapper 版本：

```powershell
Get-Content C:\Users\Co\animeko\gradle\wrapper\gradle-wrapper.properties
Get-Content C:\Users\Co\mediamp\gradle\wrapper\gradle-wrapper.properties
```

目前的版本對照：

| 目錄      | 大小      | 狀態 |
|-----------|-----------|------|
| `9.3.1`      | 約 1.1 GB | **保留** — animeko 目前使用的 Gradle |
| `modules-2`  | 約 1.1 GB | **保留** — 跨版本共用的依賴 artifact cache；刪掉會導致所有依賴重新下載 |
| `9.2.1`      | 約 1.1 GB | **刪除** — 沒有任何專案用 9.2.1 |
| `9.1.0`      | 約 820 MB | **刪除** — mediamp 的 wrapper 雖是 9.1.0，但作為 composite build 是跑在 animeko 的 9.3.1 上，所以它的 9.1.0 cache 用不到（若你日後單獨 build mediamp 會重新下載） |
| `build-cache-1` / `jars-9` / `journal-1` | 很小 | 保留 |

```powershell
Remove-Item "C:\Users\Co\.gradle\caches\9.2.1" -Recurse -Force
Remove-Item "C:\Users\Co\.gradle\caches\9.1.0" -Recurse -Force
```

### 5. 驗證釋放的空間

```powershell
powershell -ExecutionPolicy Bypass -File .\disk-space.ps1
```

### 清理後重新建置

若移除了任何快取的建置狀態，下次 `./gradlew` 會稍微慢一點（一次性重新解析依賴）。
本次清理後驗證過的桌面目標：

```powershell
cd C:\Users\Co\animeko
.\gradlew :app:desktop:assemble --console=plain
```

## 備註

- **本 session 已套用的變更**（記錄在此，方便日後審計）：
  - `animeko/gradle.properties`：daemon heap 已按第 2 步調低。
  - `mediamp/settings.gradle.kts`：移除了 `// include(":mediamp-mpv")` 的註解，
    讓 animeko 的 composite build 能解析到 `:mediamp-mpv`（這是本機未提交的變更，
    pull mediamp 時可能被覆蓋——若 `:mediamp-mpv not found` 重現，需重新套用）。
  - 已刪除 `~/.gradle/jdks/eclipse_adoptium-11-*` 與 `-17-*`（約 610 MB）。
  - 已刪除 `~/.gradle/caches/9.2.1` 與 `9.1.0`（約 1.9 GB）。
