import UIKit

class PINManager {
    static let shared = PINManager()
    
    private var currentPIN: String?
    private var pinExpirationTimer: Timer?
    private let pinTimeoutInterval: TimeInterval = 600 // 10 minutes
    
    private init() {}
    
    // MARK: - PIN Management
    
    /// Checks if a valid PIN is currently stored and not expired
    var hasValidPIN: Bool {
        return currentPIN != nil && pinExpirationTimer?.isValid == true
    }
    
    /// Gets the current PIN if valid, nil otherwise
    var currentValidPIN: String? {
        return hasValidPIN ? currentPIN : nil
    }
    
    /// Prompts user for PIN and stores it with timeout
    func promptForPIN(from viewController: UIViewController, completion: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "Enter PIN", message: "Please enter your Satochip PIN (case-sensitive alphanumeric)", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter PIN"
            textField.isSecureTextEntry = true
            textField.autocapitalizationType = .allCharacters
            textField.autocorrectionType = .no
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let pin = textField.text,
                  !pin.isEmpty else {
                completion(nil)
                return
            }
            
            self?.setPIN(pin)
            completion(pin)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(nil)
        }
        
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        
        viewController.present(alert, animated: true)
    }
    
    /// Sets the PIN and starts the expiration timer
    private func setPIN(_ pin: String) {
        currentPIN = pin
        startExpirationTimer()
    }
    
    /// Starts or resets the PIN expiration timer
    func resetPINTimer() {
        guard currentPIN != nil else { return }
        startExpirationTimer()
    }
    
    /// Starts the expiration timer
    private func startExpirationTimer() {
        // Invalidate existing timer
        pinExpirationTimer?.invalidate()
        
        // Create new timer
        pinExpirationTimer = Timer.scheduledTimer(withTimeInterval: pinTimeoutInterval, repeats: false) { [weak self] _ in
            self?.clearPIN()
        }
    }
    
    /// Clears the PIN and stops the timer
    private func clearPIN() {
        currentPIN = nil
        pinExpirationTimer?.invalidate()
        pinExpirationTimer = nil
    }
    
    /// Manually clears the PIN (for logout, etc.)
    func clearPINManually() {
        clearPIN()
    }
    
    /// Gets the remaining time until PIN expires (in seconds)
    var timeUntilExpiration: TimeInterval? {
        guard let timer = pinExpirationTimer, timer.isValid else { return nil }
        return timer.fireDate.timeIntervalSinceNow
    }
    
    /// Gets a formatted string of remaining time
    var formattedTimeRemaining: String? {
        guard let timeRemaining = timeUntilExpiration, timeRemaining > 0 else { return nil }
        
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
