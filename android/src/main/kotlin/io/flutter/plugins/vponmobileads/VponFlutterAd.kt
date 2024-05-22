package io.flutter.plugins.vponmobileads

import io.flutter.plugin.platform.PlatformView

internal abstract class VponFlutterAd(val adId: Int) {

    abstract fun load()
    abstract fun dispose()

    open fun getPlatformView(): PlatformView? {
        return null
    }

    abstract class VponFlutterOverlayAd(adId: Int) : VponFlutterAd(adId) {
        abstract fun show()
    }
}
