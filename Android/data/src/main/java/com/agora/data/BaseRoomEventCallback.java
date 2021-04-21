package com.agora.data;

import androidx.annotation.MainThread;
import androidx.annotation.NonNull;

import com.agora.data.model.Member;
import com.agora.data.model.Room;

@MainThread
public class BaseRoomEventCallback implements RoomEventCallback {

    @Override
    public void onOwnerLeaveRoom(@NonNull Room room) {

    }

    @Override
    public void onLeaveRoom(@NonNull Room room) {

    }

    @Override
    public void onMemberJoin(@NonNull Member member) {

    }

    @Override
    public void onMemberLeave(@NonNull Member member) {

    }

    @Override
    public void onRoleChanged(boolean isMine, @NonNull Member member) {

    }

    @Override
    public void onAudioStatusChanged(boolean isMine, @NonNull Member member) {

    }

    @Override
    public void onSDKVideoStatusChanged(@NonNull Member member) {

    }

    @Override
    public void onReceivedHandUp(@NonNull Member member) {

    }

    @Override
    public void onHandUpAgree(@NonNull Member member) {

    }

    @Override
    public void onHandUpRefuse(@NonNull Member member) {

    }

    @Override
    public void onReceivedInvite(@NonNull Member member) {

    }

    @Override
    public void onInviteAgree(@NonNull Member member) {

    }

    @Override
    public void onInviteRefuse(@NonNull Member member) {

    }

    @Override
    public void onEnterMinStatus() {

    }

    @Override
    public void onRoomError(int error) {

    }
}