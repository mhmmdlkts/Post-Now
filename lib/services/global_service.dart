import 'package:package_info/package_info.dart';

class GlobalService {
  Future<bool> isDriverApp() async {
    String packageName =  (await PackageInfo.fromPlatform()).packageName;
    return packageName == "com.mali.postnow";
  }
}