package io.agora.sample.rtegame.bean;

import androidx.annotation.NonNull;

public class GiftInfo {
//    gif名称, 列: SuperBell
    private final String gifName;
//    金币
    private final int coin;
//    礼物名称
    private final String title;
//    刷礼物的用户ID
    private final String userId;

    public GiftInfo(@NonNull String gifName, int coin, @NonNull String title, @NonNull String userId) {
        this.gifName = gifName;
        this.coin = coin;
        this.title = title;
        this.userId = userId;
    }

    @NonNull
    public String getGifName() {
        return gifName;
    }

    public int getCoin() {
        return coin;
    }

    @NonNull
    public String getTitle() {
        return title;
    }

    @NonNull
    public String getUserId() {
        return userId;
    }

    @NonNull
    @Override
    public String toString() {
        return "GiftInfo{" +
                "gifName='" + gifName + '\'' +
                ", coin=" + coin +
                ", title='" + title + '\'' +
                ", userId='" + userId + '\'' +
                '}';
    }
}
