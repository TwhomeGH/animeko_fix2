# 自動連播跳過無源劇集 (Auto-Next Episode Fallback)

## 問題

當自動連播切換到下一集，但該集在所有數據源都找不到可用的媒體時，應用會**永久卡死在載入狀態**：

1. 當前集播放完畢 → `SwitchNextEpisodeExtension` 呼叫 `switchEpisode` 切到下一集
2. 新集數的 `EpisodeSession` 建立，`MediaSelectorAutoSelectUseCase` 執行所有自動選擇策略
3. 所有策略返回 `null`（無可用媒體源）
4. `mediaSelector.selected` 永遠不發射 → `LoadMediaOnSelectExtension` 不觸發
5. `MediaLoadedEvent` 永不廣播
6. `SwitchNextEpisodeExtension.onStart` 卡在 `mediaLoaded.await()`
7. 播放器保持已停止狀態，UI 顯示無限載入 → **應用無回應**

### 發生情境

- 番劇列表包含 SP（特別篇）或 OVA，但資料源未收錄對應資源
- 數據源臨時失效（如 403、Cloudflare 驗證）
- 用戶手動點擊無源劇集時也會觸發相同問題

## 修正

在 `SwitchNextEpisodeExtension.onStart` 中對 `mediaLoaded.await()` 加入 **20 秒逾時**：

```kotlin
try {
    withTimeout(20_000L) {
        mediaLoaded.await()
    }
} catch (_: TimeoutCancellationException) {
    logger.info("劇集 ${episodeSession.episodeId} 無法載入媒體，嘗試跳過")
    val nextEpisode = getNextEpisode(episodeSession.episodeId)
    if (nextEpisode != null && nextEpisode != episodeSession.episodeId) {
        context.switchEpisode(nextEpisode)
    }
    return@launch
}
```

### 行為流程

```
集A 播放完畢 → switchEpisode(集B)
  ├─ 集B 有源 → MediaLoadedEvent 20 秒內送達 → 正常繼續連播
  └─ 集B 無源 → 20 秒逾時
       └─ getNextEpisode(集B) → 集C
            ├─ 集C 有源 → 正常播放
            └─ 集C 無源 → 再次逾時跳過 → ... 直到有源或無更多集數
```

### 安全機制

- `nextEpisode != episodeSession.episodeId` 防止 `getNextEpisode` 回傳同一集造成無限迴圈
- 逾時僅 20 秒，避免用戶等待過久
- `switchEpisode` 內部的切換邏輯在 `backgroundScope`（非 session scope）執行，即使目前的 session scope 被取消，切換仍會完成

## 更動檔案

| 檔案 | 變更 |
|------|------|
| `app-data/.../SwitchNextEpisodeExtension.kt` | `onStart` 的 `mediaLoaded.await()` 包上 `withTimeout(20s)`，逾時時呼叫 `getNextEpisode` 跳過 |
| `app-data/.../SwitchNextEpisodeExtensionTest.kt` | 更新測試斷言以反映新的逾時呼叫次數 |
