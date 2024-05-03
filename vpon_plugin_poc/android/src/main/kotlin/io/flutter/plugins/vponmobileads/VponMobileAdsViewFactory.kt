package io.flutter.plugins.vponmobileads;

import android.content.Context;
import android.graphics.Color;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.vpon_plugin_poc.BuildConfig;

import java.util.Locale;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

class VponMobileAdsViewFactory extends PlatformViewFactory {

    @NonNull
    private final VponAdInstanceManager manager;

    VponMobileAdsViewFactory(@NonNull VponAdInstanceManager manager) {
        super(StandardMessageCodec.INSTANCE);
        this.manager = manager;
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        if (args == null) {
            return getErrorView(context, 0);
        }
        final int adId = (Integer) args;
        VponFlutterAd ad = manager.adForId(adId);
        if (ad == null || ad.getPlatformView() == null) {
            return getErrorView(context, adId);
        }
        return ad.getPlatformView();
    }

    private static class ErrorTextView implements PlatformView {
        private final TextView textView;

        private ErrorTextView(Context context, String message) {
            textView = new TextView(context);
            textView.setText(message);
            textView.setBackgroundColor(Color.RED);
            textView.setTextColor(Color.YELLOW);
        }

        @Override
        public View getView() {
            return textView;
        }

        @Override
        public void dispose() {
        }
    }

    private static PlatformView getErrorView(@NonNull final Context context, int adId) {
        final String message =
                String.format(
                        Locale.getDefault(),
                        "This ad may have not been loaded or has been disposed. "
                                + "Ad with the following id could not be found: %d.",
                        adId);

        if (BuildConfig.DEBUG) {
            return new ErrorTextView(context, message);
        } else {
            Log.e(VponMobileAdsViewFactory.class.getSimpleName(), message);
            return new PlatformView() {
                @Override
                public View getView() {
                    return new View(context);
                }

                @Override
                public void dispose() {
                    // Do nothing.
                }
            };
        }
    }
}
