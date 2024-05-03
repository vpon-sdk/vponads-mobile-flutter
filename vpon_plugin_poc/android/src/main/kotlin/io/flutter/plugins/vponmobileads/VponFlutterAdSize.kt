package io.flutter.plugins.vponmobileads;

import androidx.annotation.NonNull;

import com.vpon.ads.VponAdSize;

class VponFlutterAdSize {
    @NonNull final VponAdSize size;
    final int width;
    final int height;

    static class SmartBannerAdSize extends VponFlutterAdSize {

        @SuppressWarnings("deprecation") // Smart banner is already deprecated in Dart.
        SmartBannerAdSize() {
            super(VponAdSize.SMART_BANNER);
        }
    }

    VponFlutterAdSize(int width, int height) {
        this(new VponAdSize(width, height, width+"x"+height+"_mb"));
    }

    VponFlutterAdSize(@NonNull VponAdSize size) {
        this.size = size;
        this.width = size.getWidth();
        this.height = size.getHeight();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        } else if (!(o instanceof VponFlutterAdSize)) {
            return false;
        }

        final VponFlutterAdSize that = (VponFlutterAdSize) o;

        if (width != that.width) {
            return false;
        }
        return height == that.height;
    }

    @Override
    public int hashCode() {
        int result = width;
        result = 31 * result + height;
        return result;
    }

    public VponAdSize getAdSize() {
        return size;
    }
}
