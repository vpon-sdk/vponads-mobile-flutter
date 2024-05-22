package io.flutter.plugins.vponmobileads

import com.vpon.ads.VponAdSize

internal open class VponFlutterAdSize(val vponAdSize: VponAdSize) {

    constructor(width: Int, height: Int) : this(
        VponAdSize(
            width, height, width.toString() + "x" + height.toString() + "_mb"
        )
    )

    val width = vponAdSize.width
    val height = vponAdSize.height

    override fun equals(other: Any?): Boolean {
        if (this === other) {
            return true
        } else if (other !is VponFlutterAdSize) {
            return false
        }

        if (width != other.width) {
            return false
        }
        return height == other.height
    }

    override fun hashCode(): Int {
        var result = width
        result = 31 * result + height
        return result
    }

    class SmartBannerAdSize : VponFlutterAdSize(VponAdSize.SMART_BANNER)

}
