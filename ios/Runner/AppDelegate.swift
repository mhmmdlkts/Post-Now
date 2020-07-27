import UIKit
import Flutter
import Firebase
import FirebaseAuth
import FirebaseCore
import GoogleMaps
import UserNotifications
import Braintree


 @UIApplicationMain
 @objc class AppDelegate: FlutterAppDelegate {
     
   override func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
     BTAppSwitch.setReturnURLScheme("com.mali.postnow.payments")
     GMSServices.provideAPIKey("AIzaSyDuKAn_iQ-QIFWxgf1AZD34yMZLMw7RP-c");
     GeneratedPluginRegistrant.register(with: self)
     paymentFlutter();
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
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme?.localizedCaseInsensitiveCompare("com.mali.postnow.payments") == .orderedSame {
            return BTAppSwitch.handleOpen(url, options: options)
        }
        return false
    }
   
   func registerForPushNotifications() {
     UNUserNotificationCenter.current()
       .requestAuthorization(options: [.alert, .badge, .sound]) {
         (granted, error) in
           print("Permission granted: \(granted)")
       }
   }
   
    func paymentFlutter() {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let paymentChannel = FlutterMethodChannel(name: "com.mali.postnow/payments",
                                                  binaryMessenger: controller.binaryMessenger)
        paymentChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "openPayMenu" else {
              result(FlutterMethodNotImplemented)
              return
            }
            guard let args = call.arguments as? Dictionary<String, Double>, let amount = args["amount"] else {
                result(FlutterError.init(code: "PAYMENU_NO_AMOUNT", message: "Failed to pay, there is no amount.", details: nil))
              return
            }
            self.payWithApplePay(amount: amount, result: result)
        })
    }
    
    private func payWithApplePay(amount: Double, result: FlutterResult) {
        result(-amount)
    }

 }
