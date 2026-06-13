package me.him188.ani.app.domain.player.extension

/**
 * 跨集數持續存在的來源級黑名單註冊表。
 *
 * 當某個 media source 的媒體播放失敗時，其 [Media.mediaSourceId] 會被加入此集合。
 * 所有擴展（如 [SwitchMediaOnPlayerErrorExtension]、[MediaSelectorAutoSelectUseCase]）
 * 都可讀取此集合，以在初始選取時跳過已知故障的來源。
 */
object BlockedMediaSourceRegistry {
    val blockedMediaSourceIds = mutableSetOf<String>()
}
