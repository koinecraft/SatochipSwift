import UIKit
import SatochipSwift
import CoreNFC

class ViewController: UIViewController, UITextViewDelegate {

    // MARK: - UI Elements
    let messageInputTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 5.0
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.text = "Enter your message here..." // Placeholder
        textView.textColor = UIColor.lightGray
        textView.tag = 0 // Tag for input
        textView.returnKeyType = .done
        textView.enablesReturnKeyAutomatically = true
        return textView
    }()

    let processedMessageTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 5.0
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false
        textView.text = "Processed messages will appear here." // Placeholder
        textView.textColor = UIColor.lightGray
        textView.tag = 1 // Tag for output
        return textView
    }()

    let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Clear", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5.0
        return button
    }()

    let signButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5.0
        return button
    }()
    
    let pinStatusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.text = "PIN: Not set"
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        messageInputTextView.delegate = self
        setupKeyboardDismissal()
        updatePINStatus()
        startPINStatusTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePINStatus()
    }

    // MARK: - UI Setup
    func setupUI() {
        view.backgroundColor = .white
        title = "Satochip Signer"

        // Add subviews
        view.addSubview(messageInputTextView)
        view.addSubview(processedMessageTextView)
        view.addSubview(pinStatusLabel)
        view.addSubview(clearButton)
        view.addSubview(signButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Message Input TextView - Fixed height for 2 lines
            messageInputTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            messageInputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageInputTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageInputTextView.heightAnchor.constraint(equalToConstant: 60), // Reduced to ~2 lines

            // Processed Message TextView - Takes remaining space
            processedMessageTextView.topAnchor.constraint(equalTo: messageInputTextView.bottomAnchor, constant: 20),
            processedMessageTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            processedMessageTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            processedMessageTextView.bottomAnchor.constraint(equalTo: pinStatusLabel.topAnchor, constant: -10),

            // PIN Status Label - Above buttons
            pinStatusLabel.bottomAnchor.constraint(equalTo: clearButton.topAnchor, constant: -10),
            pinStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pinStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pinStatusLabel.heightAnchor.constraint(equalToConstant: 20),

            // Clear Button - Fixed at bottom
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            clearButton.widthAnchor.constraint(equalToConstant: 100),
            clearButton.heightAnchor.constraint(equalToConstant: 44),

            // Sign Button - Fixed at bottom
            signButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            signButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            signButton.widthAnchor.constraint(equalToConstant: 100),
            signButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Add button actions
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        signButton.addTarget(self, action: #selector(signButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc func clearButtonTapped() {
        messageInputTextView.text = "Enter your message here..."
        messageInputTextView.textColor = UIColor.lightGray
        processedMessageTextView.text = "Processed messages will appear here."
        processedMessageTextView.textColor = UIColor.lightGray
        messageInputTextView.resignFirstResponder() // Dismiss keyboard
        
        // Clear PIN and update status
        PINManager.shared.clearPINManually()
        updatePINStatus()
    }

    @objc func signButtonTapped() {
        showMessage("🔍 DEBUG: signButtonTapped called")
        print("🔍 CONSOLE DEBUG: signButtonTapped called")
        
        let message = messageInputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        showMessage("🔍 DEBUG: Message text: '\(message)'")
        print("🔍 CONSOLE DEBUG: Message text: '\(message)'")
        
        if message == "Enter your message here..." || message.isEmpty {
            showMessage("🔍 DEBUG: Message is empty or placeholder, showing alert")
            print("🔍 CONSOLE DEBUG: Message is empty or placeholder, showing alert")
            let alert = UIAlertController(title: "Input Required", message: "Please enter a message to sign.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        showMessage("🔍 DEBUG: Checking PIN status...")
        showMessage("🔍 DEBUG: hasValidPIN: \(PINManager.shared.hasValidPIN)")
        print("🔍 CONSOLE DEBUG: Checking PIN status...")
        print("🔍 CONSOLE DEBUG: hasValidPIN: \(PINManager.shared.hasValidPIN)")
        
        // Check if we have a valid PIN, if not prompt for one
        if !PINManager.shared.hasValidPIN {
            showMessage("🔍 DEBUG: No valid PIN, prompting user...")
            print("🔍 CONSOLE DEBUG: No valid PIN, prompting user...")
            PINManager.shared.promptForPIN(from: self) { [weak self] pin in
                if let pin = pin {
                    self?.showMessage("🔍 DEBUG: PIN entered successfully: '\(pin)'")
                    print("🔍 CONSOLE DEBUG: PIN entered successfully: '\(pin)'")
                    // PIN entered successfully, proceed with signing
                    self?.performSigning(message: message, pin: pin)
                } else {
                    self?.showMessage("🔍 DEBUG: User cancelled PIN entry")
                    print("🔍 CONSOLE DEBUG: User cancelled PIN entry")
                    // User cancelled PIN entry
                    self?.showMessage("Signing cancelled - PIN required")
                }
            }
        } else {
            showMessage("🔍 DEBUG: Valid PIN exists, proceeding with signing")
            print("🔍 CONSOLE DEBUG: Valid PIN exists, proceeding with signing")
            // We have a valid PIN, proceed with signing
            if let pin = PINManager.shared.currentValidPIN {
                showMessage("🔍 DEBUG: Using existing PIN: '\(pin)'")
                print("🔍 CONSOLE DEBUG: Using existing PIN: '\(pin)'")
                performSigning(message: message, pin: pin)
            } else {
                showMessage("❌ DEBUG: hasValidPIN is true but currentValidPIN is nil")
                print("❌ CONSOLE DEBUG: hasValidPIN is true but currentValidPIN is nil")
            }
        }
    }
    
    private func performSigning(message: String, pin: String) {
        showMessage("🔍 DEBUG: Starting performSigning function")
        showMessage("🔍 DEBUG: Message: '\(message)'")
        showMessage("🔍 DEBUG: PIN: '\(pin)'")
        
        // Reset PIN timer since we're using it
        PINManager.shared.resetPINTimer()
        updatePINStatus()
        showMessage("🔍 DEBUG: PIN timer reset and status updated")
        
        // Check NFC availability using SatochipSwift
        showMessage("🔍 DEBUG: Checking SatocardController.isAvailable...")
        showMessage("🔍 DEBUG: NFCTagReaderSession.readingAvailable: \(NFCTagReaderSession.readingAvailable)")
        
        // Additional console-only debug info
        print("🔍 CONSOLE DEBUG: Device info - iOS version: \(UIDevice.current.systemVersion)")
        print("🔍 CONSOLE DEBUG: Device model: \(UIDevice.current.model)")
        print("🔍 CONSOLE DEBUG: Device name: \(UIDevice.current.name)")
        
        guard SatocardController.isAvailable else {
            showMessage("❌ DEBUG: SatocardController.isAvailable returned false")
            showMessage("❌ DEBUG: NFCTagReaderSession.readingAvailable: \(NFCTagReaderSession.readingAvailable)")
            showMessage("NFC is not available on this device.")
            
            // Console-only additional info
            print("❌ CONSOLE DEBUG: NFC not available - check device capabilities and entitlements")
            print("❌ CONSOLE DEBUG: Make sure device supports NFC and app has proper entitlements")
            return
        }
        showMessage("✅ DEBUG: SatocardController.isAvailable returned true")
        print("✅ CONSOLE DEBUG: NFC is available on this device")
        
        // Start NFC session to detect Satochip card using SatochipSwift
        showMessage("🔍 DEBUG: Creating SatocardController...")
        showMessage("Starting NFC session... Hold your Satochip card near the device")
        
        let alertMessages = SatocardController.defaultAlertMessages
        showMessage("🔍 DEBUG: Using default alert messages: \(alertMessages)")
        print("🔍 CONSOLE DEBUG: Alert messages: \(alertMessages)")
        
        guard let controller = SatocardController(
            alertMessages: alertMessages,
            onConnect: { [weak self] cardChannel in
                DispatchQueue.main.async {
                    self?.showMessage("🔍 DEBUG: onConnect callback triggered")
                    self?.showMessage("🔍 DEBUG: CardChannel type: \(type(of: cardChannel))")
                    self?.showMessage("Satochip card connected! Starting communication...")
                    
                    // Console-only additional info
                    print("🔍 CONSOLE DEBUG: onConnect callback triggered")
                    print("🔍 CONSOLE DEBUG: CardChannel type: \(type(of: cardChannel))")
                    print("🔍 CONSOLE DEBUG: CardChannel description: \(cardChannel)")
                    
                    self?.handleSatochipConnection(cardChannel: cardChannel, message: message, pin: pin)
                }
            },
            onFailure: { [weak self] error in
                DispatchQueue.main.async {
                    self?.showMessage("🔍 DEBUG: onFailure callback triggered")
                    self?.showMessage("🔍 DEBUG: Error type: \(type(of: error))")
                    self?.showMessage("🔍 DEBUG: Error domain: \(error._domain)")
                    self?.showMessage("🔍 DEBUG: Error code: \(error._code)")
                    self?.showMessage("NFC Error: \(error.localizedDescription)")
                    
                    // Console-only additional error info
                    print("🔍 CONSOLE DEBUG: onFailure callback triggered")
                    print("🔍 CONSOLE DEBUG: Error type: \(type(of: error))")
                    print("🔍 CONSOLE DEBUG: Error domain: \(error._domain)")
                    print("🔍 CONSOLE DEBUG: Error code: \(error._code)")
                    print("🔍 CONSOLE DEBUG: Error description: \(error.localizedDescription)")
                    // Note: userInfo not available on generic Error type
                }
            }
        ) else {
            showMessage("❌ DEBUG: SatocardController initialization failed")
            showMessage("Failed to initialize NFC session. Please try again.")
            print("❌ CONSOLE DEBUG: SatocardController initialization failed")
            print("❌ CONSOLE DEBUG: This could be due to NFC not being available or session creation issues")
            return
        }
        
        showMessage("✅ DEBUG: SatocardController created successfully")
        showMessage("🔍 DEBUG: Starting NFC session...")
        print("✅ CONSOLE DEBUG: SatocardController created successfully")
        print("🔍 CONSOLE DEBUG: Starting NFC session with alert message")
        
                controller.start(alertMessage: "Hold your Satochip card near the device to begin signing")
                messageInputTextView.resignFirstResponder() // Dismiss keyboard
                
                showMessage("🔍 DEBUG: NFC session started, waiting for card detection...")
                print("🔍 CONSOLE DEBUG: NFC session started, waiting for card detection...")
                print("🔍 CONSOLE DEBUG: User should now hold Satochip card near the device")
                
                // Add a small delay to check if session becomes active
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.showMessage("🔍 DEBUG: Checking session status after 2 seconds...")
                    print("🔍 CONSOLE DEBUG: Checking session status after 2 seconds...")
                    // If we haven't seen any callbacks by now, there might be an issue
                }
                
                // Add a timeout after 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                    self.showMessage("⏰ DEBUG: NFC session timeout - no activity detected")
                    print("⏰ CONSOLE DEBUG: NFC session timeout - no activity detected")
                    print("⏰ CONSOLE DEBUG: This might indicate NFC is disabled or app lacks permissions")
                }
    }
    
    private func handleSatochipConnection(cardChannel: CardChannel, message: String, pin: String) {
        showMessage("🔍 DEBUG: handleSatochipConnection called")
        showMessage("🔍 DEBUG: CardChannel type: \(type(of: cardChannel))")
        print("🔍 CONSOLE DEBUG: handleSatochipConnection called")
        print("🔍 CONSOLE DEBUG: CardChannel type: \(type(of: cardChannel))")
        print("🔍 CONSOLE DEBUG: CardChannel description: \(cardChannel)")
        
        // Create SatochipCommandSet for communication
        showMessage("🔍 DEBUG: Creating SatocardCommandSet...")
        let commandSet = SatocardCommandSet(cardChannel: cardChannel)
        showMessage("✅ DEBUG: SatocardCommandSet created successfully")
        print("🔍 CONSOLE DEBUG: Creating SatocardCommandSet...")
        print("✅ CONSOLE DEBUG: SatocardCommandSet created successfully")
        
        showMessage("Card connected! Identifying card type...")
        print("🔍 CONSOLE DEBUG: Card connected! Starting identification...")
        
        // Perform card identification
        showMessage("🔍 DEBUG: Attempting to select applet with .anycard...")
        print("🔍 CONSOLE DEBUG: Attempting to select applet with .anycard...")
        do {
            let (response, cardType) = try commandSet.selectApplet(cardType: .anycard)
            showMessage("🔍 DEBUG: selectApplet succeeded")
            showMessage("🔍 DEBUG: Response status word: 0x\(String(response.sw, radix: 16, uppercase: true))")
            showMessage("🔍 DEBUG: Response data length: \(response.data.count) bytes")
            showMessage("🔍 DEBUG: Detected card type: \(cardType)")
            
            // Console-only additional response info
            print("🔍 CONSOLE DEBUG: selectApplet succeeded")
            print("🔍 CONSOLE DEBUG: Response status word: 0x\(String(response.sw, radix: 16, uppercase: true))")
            print("🔍 CONSOLE DEBUG: Response data length: \(response.data.count) bytes")
            print("🔍 CONSOLE DEBUG: Response data (hex): \(response.data.map { String(format: "%02X", $0) }.joined(separator: " "))")
            print("🔍 CONSOLE DEBUG: Detected card type: \(cardType)")
            
            switch cardType {
            case .satochip:
                showMessage("✅ Satochip card detected!")
                showMessage("Card Type: \(cardType.rawValue)")
                
                if let status = commandSet.cardStatus {
                    showMessage("📊 Card Status:")
                    showMessage("  • Setup Done: \(status.setupDone ? "✅" : "❌")")
                    showMessage("  • Is Seeded: \(status.isSeeded ? "✅" : "❌")")
                    showMessage("  • Needs Secure Channel: \(status.needsSecureChannel ? "✅" : "❌")")
                    showMessage("  • Protocol Version: \(status.protocolMajorVersion).\(status.protocolMinorVersion)")
                    showMessage("  • Applet Version: \(status.appletMajorVersion).\(status.appletMinorVersion)")
                    showMessage("  • PIN0 Remaining Tries: \(status.pin0RemainingTries)")
                } else {
                    showMessage("⚠️ Card status information not available")
                }
                
                // Continue with Satochip-specific operations
                handleSatochipOperations(commandSet: commandSet, message: message, pin: pin)
                
            case .satodime:
                showMessage("⚠️ Satodime card detected (not Satochip)")
                showMessage("This app requires a Satochip card for message signing.")
                showMessage("Please use a Satochip card instead.")
                
            case .seedkeeper:
                showMessage("⚠️ Seedkeeper card detected (not Satochip)")
                showMessage("This app requires a Satochip card for message signing.")
                showMessage("Please use a Satochip card instead.")
                
            case .unknown, .nocard:
                showMessage("❌ Unknown or unsupported card type")
                showMessage("Please ensure you're using a Satochip, Satodime, or Seedkeeper card.")
                
            case .anycard:
                showMessage("❌ Card identification failed")
                showMessage("Unable to determine card type.")
            }
            
        } catch {
            showMessage("❌ DEBUG: selectApplet failed with error")
            showMessage("🔍 DEBUG: Error type: \(type(of: error))")
            showMessage("🔍 DEBUG: Error description: \(error.localizedDescription)")
            if let satocardError = error as? SatocardError {
                showMessage("🔍 DEBUG: SatocardError case: \(satocardError)")
            }
            showMessage("❌ Card identification failed: \(error.localizedDescription)")
            showMessage("Please ensure you're using a compatible Satochip card.")
            
            // Console-only additional error info
            print("❌ CONSOLE DEBUG: selectApplet failed with error")
            print("🔍 CONSOLE DEBUG: Error type: \(type(of: error))")
            print("🔍 CONSOLE DEBUG: Error description: \(error.localizedDescription)")
            // Note: userInfo not available on generic Error type
            if let satocardError = error as? SatocardError {
                print("🔍 CONSOLE DEBUG: SatocardError case: \(satocardError)")
            }
            print("❌ CONSOLE DEBUG: Card identification failed - check card compatibility")
        }
    }
    
    private func handleSatochipOperations(commandSet: SatocardCommandSet, message: String, pin: String) {
        showMessage("🔍 DEBUG: handleSatochipOperations called")
        showMessage("🔍 DEBUG: CommandSet type: \(type(of: commandSet))")
        showMessage("Starting Satochip operations...")
        showMessage("Message to sign: \(message)")
        showMessage("PIN: \(pin)")
        
        // TODO: Implement the next steps:
        // 1. Secure channel establishment
        // 2. PIN verification
        // 3. Message hashing and signing
        
        showMessage("Satochip operations ready for next implementation phase...")
    }
    
    private func showMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        let fullMessage = "[\(timestamp)] \(message)"
        
        // Log to console for easy copy/paste
        print(fullMessage)
        
        // Display in UI
        processedMessageTextView.textColor = .black
        processedMessageTextView.text = "\(fullMessage)\n" + processedMessageTextView.text
    }

    // MARK: - UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = textView.tag == 0 ? "Enter your message here..." : "Processed messages will appear here."
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Dismiss keyboard when user presses "Done" or "Return"
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    // MARK: - Keyboard Handling
    func setupKeyboardDismissal() {
        // Add tap gesture to dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - PIN Status Management
    private func updatePINStatus() {
        DispatchQueue.main.async { [weak self] in
            if PINManager.shared.hasValidPIN {
                if let timeRemaining = PINManager.shared.formattedTimeRemaining {
                    self?.pinStatusLabel.text = "PIN: Active (expires in \(timeRemaining))"
                    self?.pinStatusLabel.textColor = .systemGreen
                } else {
                    self?.pinStatusLabel.text = "PIN: Active"
                    self?.pinStatusLabel.textColor = .systemGreen
                }
            } else {
                self?.pinStatusLabel.text = "PIN: Not set"
                self?.pinStatusLabel.textColor = .systemRed
            }
        }
    }
    
    private func startPINStatusTimer() {
        // Update PIN status every 10 seconds to show countdown
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updatePINStatus()
        }
    }
}
