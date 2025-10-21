import UIKit
import SatochipSwift
import CoreNFC

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.systemBackground
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8.0
        textView.isEditable = false
        textView.text = "Ready to verify...\n"
        return textView
    }()
    
    private let verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Verify", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8.0
        button.addTarget(self, action: #selector(verifyButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - NFC Properties
    private var satocardController: SatocardController?
    private var commandSet: SatocardCommandSet?
    private var isNFCSessionActive = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNFC()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        title = "Verify"
        
        view.addSubview(textView)
        view.addSubview(verifyButton)
        
        NSLayoutConstraint.activate([
            // Text view constraints
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: verifyButton.topAnchor, constant: -20),
            
            // Button constraints
            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            verifyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            verifyButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func verifyButtonTapped() {
        logMessage("Starting verification process...")
        startNFCSession()
    }
    
    // MARK: - Logging
    private func logMessage(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let logEntry = "\(timestamp) - \(message)\n"
        
        // Append the message to the text view
        textView.text += logEntry
        
        // Scroll to the bottom to show the most recent message
        let bottom = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(bottom)
    }
    
    // MARK: - NFC Setup
    private func setupNFC() {
        print("🔍 CONSOLE DEBUG: setupNFC called")
        guard SatocardController.isAvailable else {
            print("🔍 CONSOLE DEBUG: NFC not available on this device")
            logMessage("NFC not available on this device")
            return
        }
        
        print("🔍 CONSOLE DEBUG: Creating SatocardController...")
        satocardController = SatocardController(
            alertMessages: SatocardController.defaultAlertMessages,
            onConnect: { [weak self] cardChannel in
                self?.handleCardConnection(cardChannel)
            },
            onFailure: { [weak self] error in
                self?.handleCardError(error)
            }
        )
        print("🔍 CONSOLE DEBUG: SatocardController created successfully")
        
        logMessage("NFC setup complete")
    }
    
    private func handleCardConnection(_ cardChannel: CardChannel) {
        print("🔍 CONSOLE DEBUG: handleCardConnection called on thread: \(Thread.current)")
        DispatchQueue.main.async {
            print("🔍 CONSOLE DEBUG: handleCardConnection executing on main thread")
            self.commandSet = SatocardCommandSet(cardChannel: cardChannel)
            self.logMessage("Card connected successfully")
            self.detectCardType()
        }
    }
    
    private func handleCardError(_ error: Error) {
        print("🔍 CONSOLE DEBUG: handleCardError called with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isNFCSessionActive = false
            self.logMessage("Card error: \(error.localizedDescription)")
        }
    }
    
    private func detectCardType() {
        print("🔍 CONSOLE DEBUG: detectCardType called")
        guard let commandSet = commandSet else { 
            print("🔍 CONSOLE DEBUG: detectCardType - commandSet is nil")
            return 
        }
        
        print("🔍 CONSOLE DEBUG: detectCardType - calling selectApplet on background thread (required by SatochipSwift)")
        
        // The selectApplet method internally calls send() which has a dispatchPrecondition
        // that requires it to be called on a background thread, not the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let (_, cardType) = try commandSet.selectApplet(cardType: .satochip)
                print("🔍 CONSOLE DEBUG: selectApplet completed successfully, cardType: \(cardType)")
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self?.logMessage("Detected card type: \(cardType)")
                    
                    switch cardType {
                    case .satochip:
                        self?.logMessage("Satochip card detected")
                    case .satodime:
                        self?.logMessage("Satodime card detected")
                    case .seedkeeper:
                        self?.logMessage("Seedkeeper card detected")
                    case .unknown:
                        self?.logMessage("Unknown card type detected")
                    case .nocard:
                        self?.logMessage("No card type detected")
                    case .anycard:
                        self?.logMessage("Any card type detected")
                    @unknown default:
                        self?.logMessage("Unknown card type detected (default case)")
                    }
                }
            } catch {
                print("🔍 CONSOLE DEBUG: detectCardType - error: \(error.localizedDescription)")
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self?.logMessage("Error detecting card type: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func startNFCSession() {
        print("🔍 CONSOLE DEBUG: startNFCSession called")
        
        guard !isNFCSessionActive else {
            print("🔍 CONSOLE DEBUG: NFC session already active, ignoring request")
            logMessage("NFC session already active")
            return
        }
        
        guard let controller = satocardController else {
            print("🔍 CONSOLE DEBUG: satocardController is nil")
            logMessage("NFC controller not available")
            return
        }
        
        print("🔍 CONSOLE DEBUG: Starting NFC session...")
        isNFCSessionActive = true
        controller.start(alertMessage: "Hold your Satochip card near the device")
        logMessage("NFC session started")
        
        // Set a timeout to stop the session if no card is detected
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
            if self?.isNFCSessionActive == true {
                print("🔍 CONSOLE DEBUG: NFC session timeout - stopping session")
                self?.stopNFCSession()
                self?.logMessage("NFC session timed out")
            }
        }
    }
    
    private func stopNFCSession() {
        print("🔍 CONSOLE DEBUG: stopNFCSession called")
        guard isNFCSessionActive else {
            print("🔍 CONSOLE DEBUG: No active NFC session to stop")
            return
        }
        
        satocardController?.stop(errorMessage: "Session stopped")
        isNFCSessionActive = false
        logMessage("NFC session stopped")
    }
}
