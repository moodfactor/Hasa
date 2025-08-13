import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Setup method channel for security features
    let controller = window?.rootViewController as! FlutterViewController
    let securityChannel = FlutterMethodChannel(
        name: "com.hasa.app/security",
        binaryMessenger: controller.binaryMessenger)
    
    securityChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let strongSelf = self else { return }
      
      if call.method == "enableSecureMode" {
        // Screen capture detection disabled - screenshots and screen recording now allowed
        // No action needed here
        result(true)
      } else if call.method == "disableSecureMode" {
        // Screen capture is already allowed
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // This function is kept but won't be called anymore
  private func showScreenCaptureAlert() {
    // Alert disabled - screenshots now allowed
  }
}
