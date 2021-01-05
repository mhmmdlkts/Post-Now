import UIKit
import Flutter
import Firebase
import FirebaseAuth
import FirebaseCore
import GoogleMaps
import UserNotifications
import PassKit



@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
     
   override func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
    GMSServices.provideAPIKey(Secrets.GOOGLE_API_KEY_IOS);
     GeneratedPluginRegistrant.register(with: self)
     if FirebaseApp.app() == nil {
         FirebaseApp.configure()
     }
    registerForPushNotifications()
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
   
   func registerForPushNotifications() {
     UNUserNotificationCenter.current()
       .requestAuthorization(options: [.alert, .badge, .sound]) {
         (granted, error) in
           print("Permission granted: \(granted)")
       }
   }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      if (url.host! == "payment-return") {
          let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
          let paymentId = queryItems?.filter({$0.name == "id"}).first

          return true;
      }

      return false;
    }
 }
