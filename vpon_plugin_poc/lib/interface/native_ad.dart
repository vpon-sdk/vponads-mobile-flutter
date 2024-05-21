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

  final String? factoryId;

  @override
  final NativeAdListener listener;

  final VponAdRequest? request;

  @override
  Future<void> load() async {
    await instanceManager.loadNativeAd(this);
  }
}
