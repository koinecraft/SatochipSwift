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
        let isValid = currentPIN != nil && pinExpirationTimer?.isValid == true
        print("🔍 PINManager: hasValidPIN check - currentPIN: \(currentPIN != nil ? "set" : "nil"), timer valid: \(pinExpirationTimer?.isValid ?? false), result: \(isValid)")
        return isValid
    }
    
    /// Gets the current PIN if valid, nil otherwise
    var currentValidPIN: String? {
        return hasValidPIN ? currentPIN : nil
    }
    
    /// Prompts user for PIN and stores it with timeout
    func promptForPIN(from viewController: UIViewController, completion: @escaping (String?) -> Void) {
        print("🔍 PINManager: promptForPIN called")
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
                print("🔍 PINManager: PIN submission failed - empty or nil PIN")
                completion(nil)
                return
            }
            
            print("🔍 PINManager: PIN submitted successfully, setting PIN")
            self?.setPIN(pin)
            completion(pin)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("🔍 PINManager: PIN entry cancelled by user")
            completion(nil)
        }
        
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        
        print("🔍 PINManager: Presenting PIN entry alert")
        viewController.present(alert, animated: true)
    }
    
    /// Sets the PIN and starts the expiration timer
    private func setPIN(_ pin: String) {
        print("🔍 PINManager: setPIN called with PIN length: \(pin.count)")
        currentPIN = pin
        startExpirationTimer()
        print("🔍 PINManager: PIN set and expiration timer started")
    }
    
    /// Starts or resets the PIN expiration timer
    func resetPINTimer() {
        print("🔍 PINManager: resetPINTimer called")
        guard currentPIN != nil else { 
            print("🔍 PINManager: resetPINTimer - no current PIN, skipping reset")
            return 
        }
        print("🔍 PINManager: resetPINTimer - resetting timer for existing PIN")
        startExpirationTimer()
    }
    
    /// Starts the expiration timer
    private func startExpirationTimer() {
        print("🔍 PINManager: startExpirationTimer called")
        // Invalidate existing timer
        pinExpirationTimer?.invalidate()
        
        // Create new timer
        pinExpirationTimer = Timer.scheduledTimer(withTimeInterval: pinTimeoutInterval, repeats: false) { [weak self] _ in
            print("🔍 PINManager: PIN expiration timer fired - clearing PIN")
            self?.clearPIN()
        }
        print("🔍 PINManager: PIN expiration timer started with \(pinTimeoutInterval) second timeout")
    }
    
    /// Clears the PIN and stops the timer
    private func clearPIN() {
        print("🔍 PINManager: clearPIN called")
        currentPIN = nil
        pinExpirationTimer?.invalidate()
        pinExpirationTimer = nil
        print("🔍 PINManager: PIN cleared and timer stopped")
    }
    
    /// Manually clears the PIN (for logout, etc.)
    func clearPINManually() {
        print("🔍 PINManager: clearPINManually called")
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
