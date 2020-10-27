import UIKit
import Flutter
import Firebase
import FirebaseAuth
import FirebaseCore
import GoogleMaps
import UserNotifications
//import Braintree
import PassKit



@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
     
   override func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
     //BTAppSwitch.setReturnURLScheme("com.mali.postnow.payments")
     GMSServices.provideAPIKey("AIzaSyDuKAn_iQ-QIFWxgf1AZD34yMZLMw7RP-c");
     GeneratedPluginRegistrant.register(with: self)
     //paymentFlutter();
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
    
    /*override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme?.localizedCaseInsensitiveCompare("com.mali.postnow.payments") == .orderedSame {
            return BTAppSwitch.handleOpen(url, options: options)
        }
        return false
    }*/
   
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

          // Optional: Do stuff with the payment ID

          return true;
      }

      return false;
    }
   
    /*func paymentFlutter() {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let paymentChannel = FlutterMethodChannel(name: "com.mali.postnow/payments",
                                                  binaryMessenger: controller.binaryMessenger)
        paymentChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "applePay" else {
              result(FlutterMethodNotImplemented)
              return
            }
            guard let args = call.arguments as? Dictionary<String, String>, let amount = args["amount"], let clientAuthorization = args["authorization"] else {
                result(FlutterError.init(code: "PAYMENU_INVALID_ARGUMENT", message: "Failed to pay, invalid arguments.", details: nil))
              return
            }
            self.payWithApplePay(amount: amount, authorization: clientAuthorization, result: result)
        })
    }
    var braintreeClient: BTAPIClient?
    
    private func payWithApplePay(amount: String, authorization: String, result: FlutterResult) {
        braintreeClient = BTAPIClient(authorization: authorization)
        self.setupPaymentRequest(completion: self.setupPaymentCompletion(paymentRequest:error:))
        result(amount)
    }
    
    func setupPaymentCompletion(paymentRequest: PKPaymentRequest?, error: Error?) {
        guard error == nil else {
            print("Error: Payment request is invalid.")
           return
        }
        if let paymentRequest = paymentRequest {
            if let vc = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
                as PKPaymentAuthorizationViewController?
            {
                vc.delegate = self
                // present(vc, animated: true, completion: nil)
            } else {
                print("Error: Payment request is invalid.")
            }
        } else {
            print("Error: Payment request is invalid.")
        }
    }
        
    func setupPaymentRequest(completion: @escaping (PKPaymentRequest?, Error?) -> Void) {
        
        if let braintreeClient = self.braintreeClient {
            let price = "6.60"
            let applePayClient = BTApplePayClient(apiClient: braintreeClient)

            applePayClient.paymentRequest { (paymentRequest, error) in
                guard let paymentRequest = paymentRequest else {
                    completion(nil, error)
                    return
                }

                if #available(iOS 11.0, *) {
                    paymentRequest.requiredBillingContactFields = [.postalAddress]
                }
                paymentRequest.merchantCapabilities = .capability3DS
                paymentRequest.paymentSummaryItems =
                [
                    PKPaymentSummaryItem(label: "Post Now", amount: NSDecimalNumber(string: price)),
                ]
                completion(paymentRequest, nil)
            }
        } else {
            print("Error: Payment token request is invalid.")
        }
    }*/
 }
