import 'ad_containers.dart';
import 'ad_instance_manager.dart';
import 'ad_listeners.dart';
import 'ad_request.dart';

class NativeAd extends AdWithView {
  NativeAd({
    required String licenseKey,
    required this.factoryId,
    required this.listener,
    required this.request,
  })  : assert(request != null),
        assert(factoryId != null),
        super(licenseKey: licenseKey, listener: listener);

  /// An identifier for the factory that creates the Platform view.
  final String? factoryId;

  /// A listener for receiving events in the ad lifecycle.
  @override
  final NativeAdListener listener;

  /// Targeting information used to fetch an [Ad].
  final AdRequest? request;

  @override
  Future<void> load() async {
    await instanceManager.loadNativeAd(this);
  }
}
