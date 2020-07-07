import UIKit
import Flutter
import Firebase
import FirebaseAuth
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDuKAn_iQ-QIFWxgf1AZD34yMZLMw7RP-c");
    GeneratedPluginRegistrant.register(with: self)
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
             let firebaseAuth = Auth.auth()
             firebaseAuth.setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)
   }

   override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
             let firebaseAuth = Auth.auth()
             if (firebaseAuth.canHandleNotification(userInfo)){
                 print(userInfo)
                 return
             }
  }
}
