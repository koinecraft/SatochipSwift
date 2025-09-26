import UIKit
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    // Create a logging subsystem for the scene delegate
    static let log = OSLog(subsystem: "com.gammastream.SimpleSato", category: "SceneDelegate")

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        os_log("🔍 SceneDelegate: Scene willConnectTo called", log: SceneDelegate.log, type: .info)
        os_log("🔍 SceneDelegate: Scene session role: %{public}@", log: SceneDelegate.log, type: .info, String(describing: session.role))
        guard let windowScene = (scene as? UIWindowScene) else { 
            os_log("🔍 SceneDelegate: Failed to cast scene to UIWindowScene", log: SceneDelegate.log, type: .error)
            return 
        }
        
        os_log("🔍 SceneDelegate: Creating window and view controller", log: SceneDelegate.log, type: .info)
        window = UIWindow(windowScene: windowScene)
        let viewController = ViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        os_log("🔍 SceneDelegate: Window setup complete", log: SceneDelegate.log, type: .info)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        os_log("🔍 SceneDelegate: Scene didDisconnect called", log: SceneDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app scene disconnected", log: SceneDelegate.log, type: .info)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        os_log("🔍 SceneDelegate: Scene didBecomeActive called", log: SceneDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app became active", log: SceneDelegate.log, type: .info)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        os_log("🔍 SceneDelegate: Scene willResignActive called", log: SceneDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app will resign active", log: SceneDelegate.log, type: .info)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        os_log("🔍 SceneDelegate: Scene willEnterForeground called", log: SceneDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app will enter foreground", log: SceneDelegate.log, type: .info)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        os_log("🔍 SceneDelegate: Scene didEnterBackground called", log: SceneDelegate.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Simple app entered background", log: SceneDelegate.log, type: .info)
    }
}