package io.flutter.plugins.vponmobileads;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.List;
import java.util.Set;

import io.flutter.plugin.common.StandardMessageCodec;

class VponAdMessageCodec extends StandardMessageCodec {

    private static final String TAG = "VponAdMessageCodec";

    // The type values below must be consistent for each platform.
    private static final byte VALUE_AD_SIZE = (byte) 128;
    private static final byte VALUE_SMART_BANNER_AD_SIZE = (byte) 143;
    private static final byte VALUE_AD_REQUEST = (byte) 129;

    private Context context = null;

    VponAdMessageCodec() {
    }
    VponAdMessageCodec(
            @NonNull Context context) {
        this.context = context;
    }

    @Override
    protected void writeValue(@NonNull ByteArrayOutputStream stream, @Nullable Object value) {
        if (value instanceof VponFlutterAdSize) {
            Log.e(TAG, "writeValue.case VponFlutterAdSize");
            writeAdSize(stream, (VponFlutterAdSize) value);
        } else if (value instanceof VponFlutterAdRequest) {
            Log.e(TAG, "writeValue.case VponFlutterAdRequest");
            stream.write(VALUE_AD_REQUEST);
            final VponFlutterAdRequest request = (VponFlutterAdRequest) value;
            writeValue(stream, request.getContentUrl());
            writeValue(stream, request.getContentData());
            writeValue(stream, request.getKeywords());
        } else {
            Log.e(TAG, "writeValue.case Others");
            super.writeValue(stream, value);
        }
    }

    /** @noinspection unchecked, DataFlowIssue */
    @Nullable
    @Override
    protected Object readValueOfType(byte type, @NonNull ByteBuffer buffer) {
        switch (type) {
            case VALUE_SMART_BANNER_AD_SIZE:
                Log.e(TAG, "readValueOfType.case VALUE_SMART_BANNER_AD_SIZE");
                return new VponFlutterAdSize.SmartBannerAdSize();
            case VALUE_AD_SIZE:
                Log.e(TAG, "readValueOfType.case VALUE_AD_SIZE");
                return new VponFlutterAdSize(
                        (Integer) readValueOfType(buffer.get(), buffer),
                        (Integer) readValueOfType(buffer.get(), buffer));
            case VALUE_AD_REQUEST:
                Log.e(TAG, "readValueOfType.case VALUE_AD_REQUEST");
                return new VponFlutterAdRequest.Builder()
                        .setContentUrl((String) readValueOfType(buffer.get(), buffer))
                        .setContentData((HashMap<String, Object>) readValueOfType(buffer.get(), buffer))
                        .setKeywords((List<String>) readValueOfType(buffer.get(), buffer))
                        .build();
            default:
                Log.e(TAG, "readValueOfType.case Others");
                return super.readValueOfType(type, buffer);
        }
    }

    protected void writeAdSize(ByteArrayOutputStream stream, VponFlutterAdSize value) {
        if (value instanceof VponFlutterAdSize.SmartBannerAdSize) {
            stream.write(VALUE_SMART_BANNER_AD_SIZE);
        } else {
            stream.write(VALUE_AD_SIZE);
            writeValue(stream, value.width);
            writeValue(stream, value.height);
        }
    }
}
