import 'package:package_info/package_info.dart';

const String POSTNOW_PACKAGE_NAME = "com.mali.postnow";
const String POSTNOW_DRIVER_PACKAGE_NAME = "com.mali.driver.postnow";

class GlobalService {
  Future<bool> isDriverApp() async {
    String packageName =  (await PackageInfo.fromPlatform()).packageName;
    return packageName == POSTNOW_DRIVER_PACKAGE_NAME;
  }
}