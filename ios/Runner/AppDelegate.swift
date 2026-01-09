import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var deepLinkChannel: FlutterMethodChannel?
    private var pendingDeepLink: String?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Setup deep link channel
        if let controller = window?.rootViewController as? FlutterViewController {
            deepLinkChannel = FlutterMethodChannel(
                name: "com.example.smartledger/deeplink",
                binaryMessenger: controller.binaryMessenger
            )
            
            deepLinkChannel?.setMethodCallHandler { [weak self] call, result in
                if call.method == "getInitialLink" {
                    // Check for Siri deep link first
                    if let siriLink = UserDefaults.standard.string(forKey: "pendingSiriDeepLink") {
                        UserDefaults.standard.removeObject(forKey: "pendingSiriDeepLink")
                        result(siriLink)
                    } else {
                        result(self?.pendingDeepLink)
                    }
                    self?.pendingDeepLink = nil
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
        
        // Check for Siri shortcut launch
        checkPendingSiriDeepLink()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle URL scheme deep links
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if url.scheme == "smartledger" {
            handleDeepLink(url.absoluteString)
            return true
        }
        return super.application(app, open: url, options: options)
    }
    
    // Handle Universal Links
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            handleDeepLink(url.absoluteString)
            return true
        }
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    private func handleDeepLink(_ urlString: String) {
        if let channel = deepLinkChannel {
            channel.invokeMethod("onDeepLink", arguments: urlString)
        } else {
            pendingDeepLink = urlString
        }
    }
    
    private func checkPendingSiriDeepLink() {
        if let siriLink = UserDefaults.standard.string(forKey: "pendingSiriDeepLink") {
            // Slight delay to ensure Flutter is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.handleDeepLink(siriLink)
                UserDefaults.standard.removeObject(forKey: "pendingSiriDeepLink")
            }
        }
    }
}
