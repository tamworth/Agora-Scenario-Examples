package io.agora.example.base;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.Objects;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;
import okhttp3.logging.HttpLoggingInterceptor;

public class TokenGenerator {
    private final String TAG = "TokenGenerator";
    private final static OkHttpClient client;

    static {
        HttpLoggingInterceptor interceptor = new HttpLoggingInterceptor();
        interceptor.setLevel(HttpLoggingInterceptor.Level.BODY);
        client = new OkHttpClient.Builder()
                .addInterceptor(interceptor)
                .build();
    }

    public static void gen(Context context, String channelName,  int uid, OnTokenGenCallback<String> onGetToken){
        gen(context.getString(R.string.rtc_app_id), context.getString(R.string.rtc_certificate), channelName, uid, ret -> {
            if(onGetToken != null){
                new Handler(Looper.getMainLooper()).post(() -> {
                    onGetToken.onTokenGen(ret);
                });
            }
        }, ret -> {
            Log.e("TAG", "for requesting token error, use config token instead.");
            if (onGetToken != null) {
                new Handler(Looper.getMainLooper()).post(() -> {
                    onGetToken.onTokenGen("");
                });
            }
        });
    }

    private static void gen(String appId, String certificate, String channelName, int uid, OnTokenGenCallback<String> onGetToken, OnTokenGenCallback<Exception> onError)  {
        if(TextUtils.isEmpty(appId) || TextUtils.isEmpty(certificate) || TextUtils.isEmpty(channelName)){
            if(onError != null){
                onError.onTokenGen(new IllegalArgumentException("appId=" + appId + ", certificate=" + certificate + ", channelName=" + channelName));
            }
            return;
        }
        JSONObject postBody = new JSONObject();
        try {
            postBody.put("appId", appId);
            postBody.put("appCertificate", certificate);
            postBody.put("channelName", channelName);
            postBody.put("expire", 900);
            postBody.put("src", "iOS");
            postBody.put("ts", System.currentTimeMillis() + "");
            postBody.put("type", 1);
            postBody.put("uid", uid + "");
        } catch (JSONException e) {
            if(onError != null){
                onError.onTokenGen(e);
            }
        }

        Request request = new Request.Builder()
                .url("https://test-toolbox.bj2.agoralab.co/v1/token/generate")
                .addHeader("Content-Type", "application/json")
                .post(RequestBody.create(postBody.toString(), null))
                .build();
        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                if(onError != null){
                    onError.onTokenGen(e);
                }
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                ResponseBody body = response.body();
                if (body != null) {
                    try {
                        JSONObject jsonObject = new JSONObject(body.string());
                        JSONObject data = jsonObject.optJSONObject("data");
                        String token = Objects.requireNonNull(data).optString("token");
                        if(onGetToken != null){
                            onGetToken.onTokenGen(token);
                        }
                    } catch (Exception e) {
                        if(onError != null){
                            onError.onTokenGen(e);
                        }
                    }
                }
            }
        });
    }

    public interface OnTokenGenCallback<T> {
        void onTokenGen(T ret);
    }

}