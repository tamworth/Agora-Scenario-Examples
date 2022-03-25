package io.agora.sample.club;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;

import com.yanzhenjie.permission.AndPermission;
import com.yanzhenjie.permission.runtime.Permission;

import java.util.List;
import java.util.Random;

import io.agora.example.base.BaseActivity;
import io.agora.sample.club.RoomManager.RoomInfo;
import io.agora.sample.club.databinding.ClubRoomListActivityBinding;
import io.agora.sample.club.databinding.ClubRoomListItemBinding;
import io.agora.uiwidget.basic.BindingViewHolder;
import io.agora.uiwidget.function.RoomListView;
import io.agora.uiwidget.utils.RandomUtil;

public class RoomListActivity extends BaseActivity<ClubRoomListActivityBinding> {
    private final String TAG = "RoomListActivity";

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        RoomManager.getInstance().init(this, getString(R.string.rtm_app_id), getString(R.string.rtm_app_token));

        mBinding.titleBar
                .setBgDrawable(R.drawable.club_main_title_bar_bg)
                .setDeliverVisible(false)
                .setTitleName(getString(R.string.club_room_list_title), getResources().getColor(R.color.club_title_bar_text_color))
                .setBackIcon(true, R.drawable.club_ic_arrow_24, v -> finish());
        mBinding.btnStartLive.setOnClickListener(v -> checkPermission(this::showRoomCreateDialog));
        mBinding.roomListView.setListAdapter(new RoomListView.CustRoomListAdapter<RoomInfo, ClubRoomListItemBinding>() {

            @Override
            protected void onItemUpdate(BindingViewHolder<ClubRoomListItemBinding> holder, RoomInfo item) {

                ImageView[] ivCrowns = new ImageView[]{
                        holder.binding.ivCrown01,
                        holder.binding.ivCrown02,
                        holder.binding.ivCrown03,
                        holder.binding.ivCrown04,
                        holder.binding.ivCrown05,
                };
                int crownValue = new Random().nextInt(ivCrowns.length);
                for (int i = 0; i < ivCrowns.length; i++) {
                    if (i > crownValue) {
                        ivCrowns[i].setVisibility(View.GONE);
                    } else {
                        ivCrowns[i].setVisibility(View.VISIBLE);
                    }
                }

                ImageView[] userIcons = new ImageView[]{
                        holder.binding.ivUser01,
                        holder.binding.ivUser02,
                        holder.binding.ivUser03,
                        holder.binding.ivUser04,
                        holder.binding.ivUser05,
                        holder.binding.ivUser06,
                        holder.binding.ivUser07,
                        holder.binding.ivUser08,
                };
                int userCount = new Random().nextInt(userIcons.length);
                for (int i = 0; i < userIcons.length; i++) {
                    if (i > userCount) {
                        userIcons[i].setVisibility(View.GONE);
                    } else {
                        userIcons[i].setVisibility(View.VISIBLE);
                        userIcons[i].setImageResource(RandomUtil.randomLiveRoomIcon());
                    }
                }

                holder.binding.tvName.setText(item.roomName);
                holder.itemView.setOnClickListener(v -> checkPermission(() -> gotoRoomDetailPage(item)));
            }

            @Override
            protected void onRefresh() {
                RoomManager.getInstance().getAllRooms(new RoomManager.DataListCallback<RoomInfo>() {
                    @Override
                    public void onSuccess(List<RoomInfo> dataList) {
                        runOnUiThread(() -> {
                            removeAll();
                            insertAll(dataList);
                            triggerDataListUpdateRun();
                        });
                    }

                    @Override
                    public void onFailed(Exception e) {
                        Log.e(TAG, "", e);
                        runOnUiThread(() -> {
                            triggerDataListUpdateRun();
                        });
                    }
                });
            }

            @Override
            protected void onLoadMore() {

            }
        });

    }

    private void checkPermission(Runnable granted) {
        String[] permissions = {Permission.CAMERA, Permission.RECORD_AUDIO};
        if (AndPermission.hasPermissions(this, permissions)) {
            if (granted != null) {
                granted.run();
            }
            return;
        }
        AndPermission.with(this)
                .runtime()
                .permission(permissions)
                .onGranted(data -> {
                    if (granted != null) {
                        granted.run();
                    }
                })
                .onDenied(data -> Toast.makeText(RoomListActivity.this, "The permission request failed.", Toast.LENGTH_SHORT).show())
                .start();
    }


    private void showRoomCreateDialog() {
        View contentView = LayoutInflater.from(this).inflate(R.layout.club_room_create_dialog, null);
        EditText contentEt = contentView.findViewById(R.id.et_content);
        ImageView refreshIv = contentView.findViewById(R.id.iv_refresh);
        refreshIv.setOnClickListener(v -> contentEt.setText(RandomUtil.randomLiveRoomName(RoomListActivity.this)));

        new AlertDialog.Builder(this)
                .setTitle(R.string.club_room_create_dialog_title)
                .setView(contentView)
                .setPositiveButton(R.string.common_create, (dialog, which) -> {
                    String roomName = contentEt.getText().toString();
                    if (TextUtils.isEmpty(roomName)) {
                        Toast.makeText(RoomListActivity.this, "Room name should not be null.", Toast.LENGTH_SHORT).show();
                        return;
                    }
                    dialog.dismiss();
                    // 创建房间
                    RoomManager.getInstance().createRoom(roomName, new RoomManager.DataCallback<RoomInfo>() {
                        @Override
                        public void onSuccess(RoomInfo data) {
                            gotoRoomDetailPage(data);
                        }

                        @Override
                        public void onFailed(Exception e) {
                            Toast.makeText(RoomListActivity.this, "Create room error : " + e.getMessage(), Toast.LENGTH_SHORT).show();
                        }
                    });
                })
                .setNegativeButton(R.string.common_cancel, (dialog, which) -> dialog.dismiss())
                .show();

    }

    private void gotoRoomDetailPage(RoomInfo roomInfo) {
        Intent intent = new Intent(this, RoomDetailActivity.class);
        intent.putExtra("roomInfo", roomInfo);
        startActivity(intent);
    }

}
