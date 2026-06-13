/*
 * Copyright (C) 2024-2026 OpenAni and contributors.
 *
 * 此源代码的使用受 GNU AFFERO GENERAL PUBLIC LICENSE version 3 许可证的约束, 可以在以下链接找到该许可证.
 * Use of this source code is governed by the GNU AGPLv3 license, which can be found at the following link.
 *
 * https://github.com/open-ani/ani/blob/main/LICENSE
 */

package me.him188.ani.app.data.models.preference

import kotlinx.serialization.Serializable

@Serializable
data class VideoPlayerSettings(
    /**
     * 启用 VLC 硬體解碼 (DXVA2/D3D11VA)。
     * 可以減輕 CPU 解碼負擔，將解碼工作交給 GPU。
     * 僅對 Desktop VLC 後端有效。
     */
    val enableHardwareDecoding: Boolean = true,
    /**
     * 硬體解碼模式。
     * - auto: 自動選擇 (嘗試 D3D11VA → DXVA2 → 軟解，不支援的編碼器會自動降級)
     * - dxva2: 使用 DXVA2 (舊版，相容性較好)
     * - d3d11va: 使用 D3D11VA (新版，性能更好)
     */
    val hwdecMode: HardwareDecodeMode = HardwareDecodeMode.AUTO,
) {
    companion object {
        val Default = VideoPlayerSettings()
    }

    val vlcFactoryArgs: List<String>
        get() = if (enableHardwareDecoding) {
            listOf("--avcodec-hw=${hwdecMode.vlcArg}")
        } else {
            emptyList()
        }
}

@Serializable
enum class HardwareDecodeMode(val displayName: String, val vlcArg: String) {
    DXVA2("DXVA2", "dxva2"),
    D3D11VA("D3D11VA", "d3d11va"),
    AUTO("Auto (建議)", "auto"),
}
