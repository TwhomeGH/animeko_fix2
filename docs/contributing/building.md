# 构建打包

如果遇到问题，请查看 [常见构建和运行问题](#常见构建和运行问题)。

## 配置秘钥

Ani 依赖一些外部服务，因此你需要有这些服务的秘钥等信息才能正常使用功能。打包之前需要在
`local.properties`
中配置这些信息。如果不配置，打包仍然会成功，但运行时无法使用对应功能。

```properties
ani.dandanplay.app.id=aaaaaaaaa
ani.dandanplay.app.secret=aaaaaaaaaaaaaaa
```

## 打包 Android APP

默认只构建 `arm64-v8a`。如果你需要完整 APK 集合，可在 `local.properties` 中加入
`ani.android.abis=all`。

在 IDE 中双击 Ctrl，可用的命令：

- `./gradlew assembleRelease` - 编译发布版
- `./gradlew assembleDebug` - 编译测试版
- `./gradlew installRelease` - 构建发布版并安装到模拟器
- `./gradlew installDebug` - 构建测试版并安装到模拟器

在 IDE 上也可以选择 `Build -> Build Bundle(s) / APK(s) -> Build APK(s)` 来构建 APK。

## 打包 iOS APP

默认不启用 iOS 构建。打包之前，请先在 `local.properties` 中加入：

```properties
ani.enable.ios=true
ani.build.framework=true
```

然后运行以下命令初始化项目：

1. `./gradlew podInstall`。如果找不到 pod，可以自行 `cd app/ios && pod install`。
2. `./gradlew patchInfoPlist`

在 IDE 中双击 Ctrl，可用的命令：

- `./gradlew buildDebugIpa` - 构建测试版（安装需要自签）
- `./gradlew buildReleaseIpa` - 构建发布版（安装需要自签）

## 打包桌面应用

要构建桌面应用，请参考 [Compose for Desktop]
官方文档，或简单执行 `./gradlew createReleaseDistributable`
，结果保存在 `app/desktop/build/compose/binaries` 中。

一个操作系统只能构建对应的桌面应用，例如 Windows 只能构建 Windows 应用，而不能构建 macOS 应用。

> [!IMPORTANT]
> **桌面端必须使用 JetBrains Runtime (JBR) 21，且必须带 JCEF**
>
> 桌面端内置浏览器基于 [JCEF](https://github.com/jetbrains/jcef)，需要 JBR（附 JCEF）
> 才能打包与运行。使用 Adoptium 等不带 JCEF 的 JDK 会报
> `NoClassDefFoundError: org/cef/handler/CefRequestHandlerAdapter`，且无法解析网页视频 URL。
>
> - 编译 Kotlin 时，Gradle 会根据 `gradle.properties` 的 `jvm.toolchain.vendor=jetbrains`
>   自动下载并使用正确的 JBR 21。
> - **打包/运行桌面应用**时，需要把 `org.gradle.java.home`（或 `JAVA_HOME` /
>   `ANI_COMPOSE_JAVA_HOME`）指向带 JCEF 的 JBR，否则 Gradle daemon 用不带 JCEF 的 JDK 时
>   无法 jlink `jcef` module。

### Windows 一键打包（本地测试/调试版）

项目提供 `scripts/build-desktop-distributable.ps1`，一键产出可执行目录（含 `Ani.exe` +
JBR runtime + JCEF），适合本地测试与调试：

```powershell
# 生成可执行目录 (portable, 含 jcef.config 方便调试)
powershell -File scripts/build-desktop-distributable.ps1

# 指定本地后端 API 地址 (开发调试常用)
powershell -File scripts/build-desktop-distributable.ps1 -ApiServer http://localhost:4394

# 明确指定 JBR
powershell -File scripts/build-desktop-distributable.ps1 -Jbr "C:\path\to\jbr"

# 生成精简的 release 版 (不含 jcef.config 调试辅助)
powershell -File scripts/build-desktop-distributable.ps1 -Release
```

脚本会依次从 `-Jbr`、`ANI_COMPOSE_JAVA_HOME`、`gradle.properties` 的
`org.gradle.java.home`、`~/.gradle/jdks/*`（探测含 `jmods/jcef.jmod` 者）自动解析 JBR。

产出的可执行目录位于 `app/desktop/build/compose/binaries/main/app/`，直接执行其中的
`Ani.exe` 即可。

#### Windows 本地调试：为什么 `:app:desktop:run` 没有 JCEF，不能播在线视频

`./gradlew :app:desktop:run` 能启动 app（mpv、anitorrent、ffmpeg 都会加载、界面正常），
但 **`org.cef.*` (JCEF) 的 class 在 dev run 的 classpath 上天生不存在**——JCEF 只通过
`nativeDistributions.modules("jcef", ...)` 在打包时 jlink 进 runtime image。因此 dev run
时会看到：

```
NoClassDefFoundError: org/cef/handler/CefRequestHandlerAdapter
WebViewVideoExtractor: Failed to get video url.
```

这是 upstream 的既有设计，不是 bug。要用 JCEF 解析网页视频 URL 并验证完整播放，**必须
用打包后的可执行文件**（见上方一键脚本），而不是 dev run。

> [!TIP]
> 若只是想快速验证 app 能否启动、mpv/播放器骨架是否正常（不依赖 JCEF 解析的来源），
> `./gradlew :app:desktop:run` 仍可用。

> [!NOTE]
> 本 fork 的 Windows 桌面播放链路的完整调查现状、mpv-D3D11/Skiko-DX12 根因、
> 以及所有**尚未处理**的事项（含 VLC backend 上游已弃用），见
> [windows-desktop-playback-status](windows-desktop-playback-status.md)。

## 运行测试版应用

参考 [testing](testing.md)。

## 运行测试

在 IDE 中双击 Ctrl，执行 `./gradlew check` 可以运行所有测试，包括单元测试和 UI 测试。

默认配置下，macOS 上不会包含 iOS 测试；如果启用了 iOS 目标，测试总数会到 11,000+。Windows 上只能运行安卓和
JVM 平台测试，无法运行 iOS 测试。

> [!TIP]
> **重复运行测试**
>
> 由于启用了 Gradle build cache，如果代码没有修改，test 就不会执行。
>
> 可使用 `./gradlew clean check` 清空缓存并重新运行所有测试。

## 常见构建和运行问题

### 编译报错找不到 `Res.*`

这是 Compose 的 bug，请生成 Compose Multiplatform 资源：

执行 `./gradlew generateComposeResClass` 即可生成一个 `Res` 类，用于在 `:app:shared` 访问资源文件。

### Android 触发断点恢复运行后，APP 无响应

打开 `app.android` 的配置，将 Debugger -> Debug type 改为 Java only。

### 启动 PC 版时报错 `ClassNotDefFoundError`

打开 `Run Desktop` 的配置，复制一份，将 "Use classpath of module" 改为 `ani.app.desktop.test`。
如果又遇到了，则改回来 `ani.app.desktop.main`。
