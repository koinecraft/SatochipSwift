import UIKit
import os.log

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Create a logging subsystem for the app
    static let log = OSLog(subsystem: "com.gammastream.SimpleSato", category: "AppDelegate")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("🚀 AppDelegate: Application didFinishLaunchingWithOptions called")
        print("🔍 CONSOLE DEBUG: Simple app is starting up")
        os_log("🚀 AppDelegate: Application didFinishLaunchingWithOptions called", log: AppDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app is starting up", log: AppDelegate.log, type: .info)
        os_log("🔍 AppDelegate: Launch options: %{public}@", log: AppDelegate.log, type: .info, String(describing: launchOptions ?? [:]))
        
        // Set up global error handling
        NSSetUncaughtExceptionHandler { exception in
            os_log("🔍 CONSOLE DEBUG: ===== UNCAUGHT EXCEPTION =====", log: AppDelegate.log, type: .error)
            os_log("🔍 CONSOLE DEBUG: Exception name: %{public}@", log: AppDelegate.log, type: .error, exception.name.rawValue)
            os_log("🔍 CONSOLE DEBUG: Exception reason: %{public}@", log: AppDelegate.log, type: .error, exception.reason ?? "Unknown")
            os_log("🔍 CONSOLE DEBUG: Exception call stack: %{public}@", log: AppDelegate.log, type: .error, String(describing: exception.callStackSymbols))
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        os_log("🔍 AppDelegate: Configuration for connecting scene session called", log: AppDelegate.log, type: .info)
        os_log("🔍 AppDelegate: Scene session role: %{public}@", log: AppDelegate.log, type: .info, String(describing: connectingSceneSession.role))
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        os_log("🔍 AppDelegate: Scene sessions discarded: %d", log: AppDelegate.log, type: .info, sceneSessions.count)
        for session in sceneSessions {
            os_log("🔍 AppDelegate: Discarded session role: %{public}@", log: AppDelegate.log, type: .info, String(describing: session.role))
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        os_log("🔍 AppDelegate: applicationWillTerminate called", log: AppDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: ===== APPLICATION TERMINATING =====", log: AppDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app is shutting down", log: AppDelegate.log, type: .info)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        os_log("🔍 AppDelegate: applicationDidEnterBackground called", log: AppDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app entered background", log: AppDelegate.log, type: .info)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        os_log("🔍 AppDelegate: applicationWillEnterForeground called", log: AppDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app will enter foreground", log: AppDelegate.log, type: .info)
    }
}
