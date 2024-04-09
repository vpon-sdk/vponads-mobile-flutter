package io.flutter.plugins.vponmobileads;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.platform.PlatformView;

class VponFlutterPlatformView implements PlatformView {

    @Nullable
    private View view;

    VponFlutterPlatformView(@NonNull View view) {
        this.view = view;
    }

    @Nullable
    @Override
    public View getView() {
        return view;
    }

    @Override
    public void dispose() {
        this.view = null;
    }

}
