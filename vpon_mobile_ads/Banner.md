## Banner

### Load ad

Please refer to the following implementation to load a banner ad:
1. Declare a banner ad object

```dart
BannerAd? _bannerAd;
```
2. Load banner

In additional to `onAdloaded`, you can listen for ad events by implementing `BannerAdListener`.
```dart
void _loadBannerAd() async {
    await _bannerAd?.dispose();
    setState(() {
    _bannerAd = null;
    });

    String key = 'Your License Key';
    VponAdRequest request = VponAdRequest();

    _bannerAd = BannerAd(
        licenseKey: key,
        size: BannerAdSize.banner,
        request: request,
        autoRefresh: false,
        listener: BannerAdListener(
            onAdLoaded: (Ad ad) async {
            BannerAd bannerAd = (ad as BannerAd);
                setState(() {
                    _bannerAd = bannerAd;
                    adWidgetKey = UniqueKey();
                });
            },
            onAdFailedToLoad: (Ad ad, Map error) {
                ad.dispose();
            },
            onAdImpression: (Ad ad) {
                // handle impression
            },
            onAdClicked: (Ad ad) {
                // handle click
            },
        ),
    );
    await _bannerAd?.load();
}
```

### Banner Format

Vpon supports the following banner formats:

| Size (WxH)  | Description  | BannerAdSize |
|---|---|---|
| 320x50  | Standard Banner  | banner  |
| 320x100 | Large Banner | largeBanner |
| 300x250  | IAB Medium Recangle  |  mediumRectangle |
| 320x480  | Large Rectangle Banner  | largeRectangle  |
| 468x60 | IAB Full-Size Banner | fullBanner |
| 728x90 | IAB Leaderboard | leaderboard |