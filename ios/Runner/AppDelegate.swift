import Flutter
import UIKit
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import os.log

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var memoryChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAnD3vjZ8lHSHzALc3OTfC2iJNmLS7eMtk")
    FirebaseApp.configure()

    if #available(iOS 10.0, *) {
      let notificationCenter = UNUserNotificationCenter.current()
      notificationCenter.delegate = self
      notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
        if granted {
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        }
      }
    }
    Messaging.messaging().delegate = self
#if !targetEnvironment(macCatalyst)
    if #available(iOS 10.0, *) {
      // handled in requestAuthorization above
    } else {
      let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }
#endif

    GeneratedPluginRegistrant.register(with: self)
    
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // Setup memory monitoring channel after window is ready
    DispatchQueue.main.async { [weak self] in
      self?.setupMemoryChannel()
    }
    
    return result
  }
  
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    Messaging.messaging().apnsToken = deviceToken
    let tokenString = hexString(from: deviceToken)
    os_log("APNs device token registered: %@", log: .default, type: .info, tokenString)
  }
  
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    os_log("Failed to register for remote notifications: %@", log: .default, type: .error, error.localizedDescription)
  }
  
  // MARK: - Universal Links handling
  // This is CRITICAL for Universal Links to work properly
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    // Log Universal Link received
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      os_log("🔗 Universal Link received: %@", log: .default, type: .info, url.absoluteString)
    }
    
    // IMPORTANT: Call super to let Flutter's app_links package handle the link
    // This MUST return true for iOS to consider the link as handled
    let handled = super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    os_log("🔗 Universal Link handled by Flutter: %@", log: .default, type: .info, handled ? "YES" : "NO")
    
    // Always return true to tell iOS we handled the link
    // This prevents iOS from falling back to Safari
    return true
  }
  
  // MARK: - URL Scheme handling (for custom schemes like mandw://)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    os_log("🔗 Custom URL scheme received: %@", log: .default, type: .info, url.absoluteString)
    
    // Let Flutter handle it
    let handled = super.application(app, open: url, options: options)
    os_log("🔗 Custom URL handled by Flutter: %@", log: .default, type: .info, handled ? "YES" : "NO")
    
    return handled
  }
  
  private func setupMemoryChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      // Retry if window is not ready yet
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.setupMemoryChannel()
      }
      return
    }
    
    memoryChannel = FlutterMethodChannel(
      name: "memory_info",
      binaryMessenger: controller.binaryMessenger
    )
    
    memoryChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getIOSMemoryInfo" {
        self?.getIOSMemoryInfo(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func getIOSMemoryInfo(result: @escaping FlutterResult) {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_,
                  task_flavor_t(MACH_TASK_BASIC_INFO),
                  $0,
                  &count)
      }
    }
    
    if kerr == KERN_SUCCESS {
      let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0 // MB
      let totalMemory = ProcessInfo.processInfo.physicalMemory / 1024 / 1024 // MB
      let memoryUsage = usedMemory / Double(totalMemory)
      
      // Consider low memory if usage is above 80%
      let isLowMemory = memoryUsage > 0.8
      
      result([
        "isLowMemory": isLowMemory,
        "usedMemory": usedMemory,
        "totalMemory": totalMemory,
        "memoryUsage": memoryUsage
      ])
    } else {
      result([
        "isLowMemory": false,
        "usedMemory": 0,
        "totalMemory": 0,
        "error": "Failed to get memory info"
      ])
    }
  }
  
  override func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    super.applicationDidReceiveMemoryWarning(application)
    
    // Notify Flutter about memory warning
    memoryChannel?.invokeMethod("didReceiveMemoryWarning", arguments: nil)
    
    // Clear image cache on memory warning
    if let controller = window?.rootViewController as? FlutterViewController {
      // Image cache clearing will be handled by Flutter side
      os_log("Memory warning received - notifying Flutter", log: .default, type: .info)
    }
  }
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    
    // Optimize memory when app enters background
    memoryChannel?.invokeMethod("didEnterBackground", arguments: nil)
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    
    // Restore normal memory settings when app enters foreground
    memoryChannel?.invokeMethod("willEnterForeground", arguments: nil)
  }
  
  private func hexString(from data: Data) -> String {
    data.map { String(format: "%02.2hhx", $0) }.joined()
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken = fcmToken else {
      os_log("FCM registration token is nil", log: .default, type: .error)
      return
    }
    
    os_log("FCM registration token: %@", log: .default, type: .info, fcmToken)
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: ["token": fcmToken]
    )
  }
}
