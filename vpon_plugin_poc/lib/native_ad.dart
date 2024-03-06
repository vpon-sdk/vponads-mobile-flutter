
// class NativeAd extends AdWithView {
//   /// Creates a [NativeAd].
//   ///
//   /// A valid [licenseKey], nonnull [listener], nonnull [request], and either
//   /// [factoryId] or [nativeTemplateStyle] is required.
//   /// Use [nativeAdOptions] to customize the native ad request.
//   /// Use [customOptions] to pass data to your native ad factory.
//   NativeAd({
//     required String licenseKey,
//     this.factoryId,
//     required this.listener,
//     required this.request,
//     this.customOptions,
//     this.nativeTemplateStyle,
//   })  : adManagerRequest = null,
//         assert(request != null),
//         assert(nativeTemplateStyle != null || factoryId != null),
//         super(adUnitId: adUnitId, listener: listener);

//   /// Creates a [NativeAd] with Ad Manager.
//   ///
//   /// A valid [adUnitId], nonnull [listener], nonnull [adManagerRequest], and
//   /// either [factoryId] or [nativeTemplateStyle] is required.
//   /// Use [nativeAdOptions] to customize the native ad request.
//   /// Use [customOptions] to pass data to your native ad factory.
//   NativeAd.fromAdManagerRequest({
//     required String adUnitId,
//     this.factoryId,
//     required this.listener,
//     this.customOptions,
//     this.nativeTemplateStyle,
//   })  : request = null,
//         assert(adManagerRequest != null),
//         assert(nativeTemplateStyle != null || factoryId != null),
//         super(adUnitId: adUnitId, listener: listener);

//   /// An identifier for the factory that creates the Platform view.
//   final String? factoryId;

//   /// A listener for receiving events in the ad lifecycle.
//   @override
//   final NativeAdListener listener;

//   /// Optional options used to create the [NativeAd].
//   ///
//   /// These options are passed to the platform's `NativeAdFactory`.
//   Map<String, Object>? customOptions;

//   /// Targeting information used to fetch an [Ad].
//   final AdRequest? request;


//   /// Optional [NativeTemplateStyle] for this ad.
//   ///
//   /// If this is non-null, the plugin will render a native ad template
//   /// with corresponding style. Otherwise any registered NativeAdFactory will be
//   /// used to render the native ad.
//   final NativeTemplateStyle? nativeTemplateStyle;

//   @override
//   Future<void> load() async {
//     await instanceManager.loadNativeAd(this);
//   }
// }