import 'package:package_info/package_info.dart';
import 'package:postnow/enums/app_type_enum.dart';

const String POSTNOW_PACKAGE_NAME = "com.mali.postnow";
const String POSTNOW_DRIVER_PACKAGE_NAME = "com.mali.driver.postnow";
const String POSTNOW_FLEET_PACKAGE_NAME = "com.mali.postnowfleet";

class GlobalService {
  static Future<bool> isDriverApp() async {
    AppTypeEnum appType =  await getAppType();
    return appType == AppTypeEnum.DRIVER;
  }

  static Future<bool> isCustomerApp() async {
    AppTypeEnum appType =  await getAppType();
    return appType == AppTypeEnum.CUSTOMER;
  }

  static Future<bool> isFleetApp() async {
    AppTypeEnum appType =  await getAppType();
    return appType == AppTypeEnum.FLEET;
  }

  static Future<AppTypeEnum> getAppType() async {
    String packageName =  (await PackageInfo.fromPlatform()).packageName;
    switch (packageName) {
      case POSTNOW_PACKAGE_NAME:
        return AppTypeEnum.CUSTOMER;
      case POSTNOW_DRIVER_PACKAGE_NAME:
        return AppTypeEnum.DRIVER;
      case POSTNOW_FLEET_PACKAGE_NAME:
        return AppTypeEnum.FLEET;
    }
    return null;
  }
}