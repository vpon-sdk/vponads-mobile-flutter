## Interstitial

### Load ad

Please refer to the following implementation to load an interstitial ad:
1. Declare an interstitial ad object

```dart
InterstitialAd? _interstitialAd;
```
2. Load interstitial

In additional to `onAdloaded`, you can listen for ad events by implementing `InterstitialAdLoadCallback`.
```dart
 void _loadInterstitialAd() {
    VponAdRequest request = VponAdRequest();

    InterstitialAd.load(
        licenseKey: 'Your license key',
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
                _interstitialAd = ad;
            },
            onAdFailedToLoad: (Map error) {
                _interstitialAd = null;
            },
            onAdImpression: (InterstitialAd ad) {
                // handle impression
            },
            onAdClicked: (InterstitialAd ad) {
                // handle click
            },
            onAdWillDismissFullScreenContent: (InterstitialAd ad) {
                // handle callback
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
                // handle callback
            },
            onAdWillShowFullScreenContent: (InterstitialAd ad) {
                // handle callback
            },
        ),
    );
  }
```

3. Show interstitial

After loading the ad, you can decide when to display it by calling `show()`.
```dart
_interstitialAd.show();
```