package io.agora.scene.rtegame.repo;

import android.webkit.WebView;

import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.IOException;

import io.agora.example.base.BaseUtil;
import io.agora.scene.rtegame.GlobalViewModel;
import io.agora.scene.rtegame.bean.AgoraGame;
import io.agora.scene.rtegame.bean.GiftInfo;
import io.agora.scene.rtegame.bean.LocalUser;
import io.agora.scene.rtegame.util.GameUtil;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class GameRepo {

    @Nullable
    public static AgoraGame getGameDetail(int gameId){
        if (gameId == 1){
            return new AgoraGame(gameId, "10020", "你画我猜",
                    "https://imgsecond.yuanqiyouxi.com/test/DrawAndGuess/index.html",
                    "https://testgame.yuanqihuyu.com/guess/leave",
                    "https://testgame.yuanqihuyu.com/guess/gift",
                    "https://testgame.yuanqihuyu.com/guess/barrage");
        } else return null;
    }

    public static void endThisGame(int targetRoomId){
        if (GameUtil.currentGame == null) return;
        BaseUtil.logD("endThisGame:"+targetRoomId);
        int userId = Integer.parseInt(GlobalViewModel.localUser.getUserId());
        int appId = Integer.parseInt(GameUtil.currentGame.getAppId());
        String timestamp = String.valueOf(System.currentTimeMillis()/1000);

        String endUrl = GameUtil.currentGame.getGameEndUrl();

        YuanQiHttp.getAPI().gameEnd(endUrl, userId,appId, 1, targetRoomId, "123456789", timestamp, "123").enqueue(new EmptyRetrofitCallBack<>());
        BaseUtil.logD("end complete");
    }

    @MainThread
    public static void gameStart(@NonNull WebView webView, @NonNull LocalUser user, boolean isOrganizer, int targetRoomId){
        if (GameUtil.currentGame == null) return;
        int userId = Integer.parseInt(user.getUserId());
        int appId = Integer.parseInt(GameUtil.currentGame.getAppId());

        String url = YuanQiHttp.getAPI().gameStart(
                GameUtil.currentGame.getGameStartUrl(),
                userId, appId, targetRoomId, isOrganizer ? 1 : 2,123456789,user.getName(), user.getAvatar()
        ).request().url().toString();

        BaseUtil.logD("url:"+url);
        webView.loadUrl(url);
    }

    public static void sendGift(@NonNull LocalUser user, int roomId, int playerId, @NonNull GiftInfo gift){
        if (GameUtil.currentGame == null) return;
        int userId = Integer.parseInt(user.getUserId());
        int appId = Integer.parseInt(GameUtil.currentGame.getAppId());
        String timestamp = String.valueOf(System.currentTimeMillis()/1000);

        String giftUrl = GameUtil.currentGame.getGameGiftUrl();

        YuanQiHttp.getAPI().gameGift(giftUrl, userId, appId,roomId, user.getName(), "token123", timestamp, YuanQiHttp.nonStr(), gift.getGiftType(), 1, playerId).enqueue(new EmptyRetrofitCallBack<>());
    }

    static class EmptyRetrofitCallBack<T> implements Callback<T>{

        @Override
        public void onResponse(@NonNull Call<T> call, Response<T> response) {
            ResponseBody body = (ResponseBody) response.body();
            if (body != null) {
                try {
                    BaseUtil.logD(body.string());
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        @Override
        public void onFailure(@NonNull Call<T> call, @NonNull Throwable t) {
            BaseUtil.logD(t.getMessage());
        }
    }
}