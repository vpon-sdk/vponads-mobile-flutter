## Get Started

### Import SDK

#### Depend on it
Run this command:
```
$ flutter pub add vpon_mobile_ads
```
This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get):
```
dependencies:
  vpon_mobile_ads: ^0.0.1
```

Alternatively, your editor might support flutter pub get. Check the docs for your editor to learn more.


#### Import it
Now in your Dart code, you can use:
```
import 'package:vpon_mobile_ads/vpon_ad_sdk.dart';
```

### Initialize SDK

Please initialize Vpon SDK by calling `VponAdSDK.instance.initialize()` before loading ads:

```dart
import 'package:vpon_mobile_ads/vpon_ad_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VponAdSDK.instance.initialize();
  runApp(MyApp());
}
```