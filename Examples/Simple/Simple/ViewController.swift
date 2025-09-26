import UIKit
import SatochipSwift
import os.log
import CoreNFC

class ViewController: UIViewController, UITextViewDelegate {

    // MARK: - Logging
    static let log = OSLog(subsystem: "com.gammastream.SimpleSato", category: "ViewController")

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

    private var satocardController: SatocardController?
    private var commandSet: SatocardCommandSet?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("🔍 ViewController: viewDidLoad called", log: ViewController.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: ViewController is loading", log: ViewController.log, type: .info)
        setupUI()
        messageInputTextView.delegate = self
        setupKeyboardDismissal()
        updatePINStatus()
        startPINStatusTimer()
        os_log("🔍 ViewController: viewDidLoad setup complete", log: ViewController.log, type: .info)
        setupNFC()
    }
    
   private func setupNFC() {
        os_log("🔍 ViewController: setupNFC called", log: ViewController.log, type: .info)
        guard SatocardController.isAvailable else {
            print("NFC not available on this device")
            os_log("🔍 ViewController: NFC not available on this device", log: ViewController.log, type: .info)
            return
        }
        
        satocardController = SatocardController(
            alertMessages: SatocardController.defaultAlertMessages,
            onConnect: { [weak self] cardChannel in
                self?.handleCardConnection(cardChannel)
            },
            onFailure: { [weak self] error in
                self?.handleCardError(error)
            }
        )
    }
    
    // private func handleCardOperations() {
    //     guard let commandSet = commandSet else { return }
        
    //     do {
    //         try performCardOperation()
    //     } catch SatocardError.pinRequired {
    //         print("PIN is required for this operation")
    //         // Prompt user for PIN
    //     } catch SatocardError.wrongCardType {
    //         print("Wrong card type detected")
    //         // Handle wrong card type
    //     } catch SatocardError.wrongResponseLength(let length, let expected) {
    //         print("Response length mismatch: got \(length), expected \(expected)")
    //     } catch SatocardError.pathTooLongForBip32Derivation(let length, let expected) {
    //         print("BIP32 path too long: \(length), max allowed: \(expected)")
    //     } catch CardError.wrongPIN(let retryCounter) {
    //         print("Wrong PIN entered. Retries remaining: \(retryCounter)")
    //         // Update UI to show remaining retries
    //     } catch CardError.pinBlocked {
    //         print("PIN is blocked. Use PUK to unblock.")
    //         // Show PUK entry dialog
    //     } catch SatodimeApiError.wrongSlip44Size(let length, let expected) {
    //         print("SLIP-44 size error: \(length), expected: \(expected)")
    //     } catch SeedkeeperApiError.wrongSecretSize(let size) {
    //         print("Invalid secret size: \(size). Must be 16-64 bytes.")
    //     } catch MnemonicError.wrongBip39Word(let word) {
    //         print("Invalid BIP39 word: \(word)")
    //     } catch MnemonicError.wrongBip39Checksum {
    //         print("BIP39 checksum validation failed")
    //     } catch {
    //         print("Unexpected error: \(error)")
    //     }
    // }

    private func signTransaction() {
        guard let commandSet = commandSet else { return }
        
        do {
            // This would typically be called through the secure channel
            // The actual implementation depends on the specific transaction format
            
            // Example: Sign a message hash
            let messageHash = "Hello, Satochip!".data(using: .utf8)!.sha256
            // let signature = try commandSet.cardSignMessage(messageHash: messageHash)
            print("Message signed successfully")
            
        } catch {
            print("Error signing transaction: \(error)")
        }
    }

    private func checkNFCAvailability() -> Bool {
        guard SatocardController.isAvailable else {
            showMessage("NFC Not Available - This device does not support NFC or NFC is disabled.")
            return false
        }
        return true
    }

    private func handleCardConnection(_ cardChannel: CardChannel) {
        DispatchQueue.main.async {
            self.commandSet = SatocardCommandSet(cardChannel: cardChannel)
            self.detectCardType()
        }
    }
    
    private func handleCardError(_ error: Error) {
        DispatchQueue.main.async {
            print("Card error: \(error.localizedDescription)")
        }
    }
    
    private func startNFCSession() {
        satocardController?.start(alertMessage: "Hold your Satochip card near the device")
    }

private func detectCardType() {
    guard let commandSet = commandSet else { return }
    
    do {
        let (response, cardType) = try commandSet.selectApplet(cardType: .anycard)
        print("Detected card type: \(cardType)")
        
        switch cardType {
        case .satochip:
            handleSatochipCard()
//        case .satodime:
//            handleSatodimeCard()
//        case .seedkeeper:
//            handleSeedkeeperCard()
        default:
            print("Unknown card type")
        }
    } catch {
        print("Error detecting card: \(error)")
    }
}

private func handleSatochipCard() {
    guard let commandSet = commandSet else { return }
    
    do {
        // Get card status
        let statusResponse = try commandSet.cardGetStatus()
        print("Card status retrieved")
        
        // Check if card needs setup
        if let cardStatus = commandSet.cardStatus, !cardStatus.setupDone {
            setupSatochipCard()
        } else {
            // Card is already set up, proceed with operations
            authenticateWithCard()
        }
    } catch {
        print("Error handling Satochip card: \(error)")
    }
}

private func setupSatochipCard() {
    guard let commandSet = commandSet else { return }
    
    do {
        let pin = "qqqqqq".bytes
        let response = try commandSet.cardSetup(pin_tries0: 3, pin0: pin)
        print("Card setup completed successfully")
        
        // Now authenticate with the new PIN
        authenticateWithCard()
    } catch {
        print("Error setting up card: \(error)")
    }
}

private func authenticateWithCard() {
    guard let commandSet = commandSet else { return }
    
    do {
        let pin = "qqqq".bytes
        let response = try commandSet.cardVerifyPIN(pin: pin)
        print("PIN verification successful")
        
        // Now you can perform secure operations
        performSecureOperations()
    } catch CardError.wrongPIN(let retryCounter) {
        print("Wrong PIN. Retries remaining: \(retryCounter)")
    } catch CardError.pinBlocked {
        print("PIN is blocked. Use PUK to unblock.")
    } catch {
        print("Authentication error: \(error)")
    }
}
  
private func performSecureOperations() {
    guard let commandSet = commandSet else { return }
    
    do {
        // Derive a Bitcoin address (m/44'/0'/0'/0/0)
        let bitcoinPath = "m/44'/0'/0'/0/0"
        let (pubkey, chaincode) = try commandSet.cardBip32GetExtendedkey(path: bitcoinPath)
        print("Bitcoin public key: \(pubkey.bytesToHex)")
        
        // Get extended public key
        let xpub = try commandSet.cardBip32GetXpub(path: bitcoinPath, xtype: 0x0488B21E) // Bitcoin mainnet
        print("Bitcoin xpub: \(xpub)")
                
    } catch SatocardError.pathTooLongForBip32Derivation(let length, let expected) {
        print("BIP32 path too long: \(length), expected max: \(expected)")
    } catch {
        print("Error performing secure operations: \(error)")
    }
}
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        os_log("🔍 ViewController: viewWillAppear called", log: ViewController.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: ViewController will appear", log: ViewController.log, type: .info)
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
        print("🔍 ViewController: ===== SIGN BUTTON TAPPED =====")
        os_log("🔍 CONSOLE DEBUG: signButtonTapped called", log: ViewController.log, type: .info)
        os_log("🔍 ViewController: ===== SIGN BUTTON TAPPED =====", log: ViewController.log, type: .info)
        
        let message = messageInputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        showMessage("🔍 DEBUG: Message text: '\(message)'")
        os_log("🔍 CONSOLE DEBUG: Message text: '%{public}@'", log: ViewController.log, type: .info, message)
        os_log("🔍 ViewController: Message to sign: '%{public}@'", log: ViewController.log, type: .info, message)
        os_log("🔍 CONSOLE DEBUG: ===== SIGN BUTTON PRESSED =====", log: ViewController.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: Message to be signed: '%{public}@'", log: ViewController.log, type: .info, message)
        os_log("🔍 CONSOLE DEBUG: Message length: %d characters", log: ViewController.log, type: .info, message.count)
        
        if message == "Enter your message here..." || message.isEmpty {
            showMessage("🔍 DEBUG: Message is empty or placeholder, showing alert")
            os_log("🔍 CONSOLE DEBUG: Message is empty or placeholder, showing alert", log: ViewController.log, type: .info)
            os_log("🔍 ViewController: ❌ Message validation failed - empty or placeholder text", log: ViewController.log, type: .info)
            let alert = UIAlertController(title: "Input Required", message: "Please enter a message to sign.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        os_log("🔍 ViewController: ✅ Message validation passed", log: ViewController.log, type: .info)

        showMessage("🔍 DEBUG: Checking PIN status...")
        showMessage("🔍 DEBUG: hasValidPIN: \(PINManager.shared.hasValidPIN)")
        os_log("🔍 CONSOLE DEBUG: Checking PIN status...", log: ViewController.log, type: .info)
        os_log("🔍 CONSOLE DEBUG: hasValidPIN: %{public}@", log: ViewController.log, type: .info, String(PINManager.shared.hasValidPIN))
        os_log("🔍 ViewController: Checking PIN status - hasValidPIN: %{public}@", log: ViewController.log, type: .info, String(PINManager.shared.hasValidPIN))
        
        // Check if we have a valid PIN, if not prompt for one
        if !PINManager.shared.hasValidPIN {
            showMessage("🔍 DEBUG: No valid PIN, prompting user...")
            os_log("🔍 CONSOLE DEBUG: No valid PIN, prompting user...", log: ViewController.log, type: .info)
            os_log("🔍 ViewController: No valid PIN found, prompting user for PIN", log: ViewController.log, type: .info)
            PINManager.shared.promptForPIN(from: self) { [weak self] pin in
                if let pin = pin {
                    self?.showMessage("🔍 DEBUG: PIN entered successfully: '\(pin)'")
                    os_log("🔍 CONSOLE DEBUG: PIN entered successfully: '%{public}@'", log: ViewController.log, type: .info, pin)
                    os_log("🔍 ViewController: ✅ PIN entered successfully, proceeding with signing", log: ViewController.log, type: .info)
                    // PIN entered successfully, proceed with signing
                    self?.performSigning(message: message, pin: pin)
                } else {
                    self?.showMessage("🔍 DEBUG: User cancelled PIN entry")
                    os_log("🔍 CONSOLE DEBUG: User cancelled PIN entry", log: ViewController.log, type: .info)
                    os_log("🔍 ViewController: ❌ User cancelled PIN entry", log: ViewController.log, type: .info)
                    // User cancelled PIN entry
                    self?.showMessage("Signing cancelled - PIN required")
                }
            }
        } else {
            showMessage("🔍 DEBUG: Valid PIN exists, proceeding with signing")
            os_log("🔍 CONSOLE DEBUG: Valid PIN exists, proceeding with signing", log: ViewController.log, type: .info)
            os_log("🔍 ViewController: ✅ Valid PIN exists, proceeding with signing", log: ViewController.log, type: .info)
            // We have a valid PIN, proceed with signing
            if let pin = PINManager.shared.currentValidPIN {
                showMessage("🔍 DEBUG: Using existing PIN: '\(pin)'")
                os_log("🔍 CONSOLE DEBUG: Using existing PIN: '%{public}@'", log: ViewController.log, type: .info, pin)
                os_log("🔍 ViewController: Using existing PIN for signing", log: ViewController.log, type: .info)
                performSigning(message: message, pin: pin)
            } else {
                showMessage("❌ DEBUG: hasValidPIN is true but currentValidPIN is nil")
                os_log("❌ CONSOLE DEBUG: hasValidPIN is true but currentValidPIN is nil", log: ViewController.log, type: .error)
                os_log("🔍 ViewController: ❌ ERROR: hasValidPIN is true but currentValidPIN is nil", log: ViewController.log, type: .error)
            }
        }
    }
    
    private func performSigning(message: String, pin: String) {
        showMessage("🔍 DEBUG: Starting performSigning function")
        showMessage("🔍 DEBUG: Message: '\(message)'")
        showMessage("🔍 DEBUG: PIN: '\(pin)'")
        os_log("🔍 ViewController: ===== PERFORMING SIGNING =====", log: ViewController.log, type: .info)
        os_log("🔍 ViewController: Message: '%{public}@'", log: ViewController.log, type: .info, message)
        os_log("🔍 ViewController: PIN: '%{public}@'", log: ViewController.log, type: .info, pin)
        
        // Reset PIN timer since we're using it
        PINManager.shared.resetPINTimer()
        updatePINStatus()
        showMessage("🔍 DEBUG: PIN timer reset and status updated")
        os_log("🔍 ViewController: PIN timer reset and status updated", log: ViewController.log, type: .info)
        
        // Check NFC availability using SatochipSwift
        showMessage("🔍 DEBUG: Checking SatocardController.isAvailable...")
        showMessage("🔍 DEBUG: NFCTagReaderSession.readingAvailable: \(NFCTagReaderSession.readingAvailable)")
        os_log("🔍 ViewController: Checking NFC availability...", log: ViewController.log, type: .info)
        os_log("🔍 ViewController: NFCTagReaderSession.readingAvailable: %{public}@", log: ViewController.log, type: .info, String(NFCTagReaderSession.readingAvailable))
        
        // Additional console-only debug info
        os_log("🔍 CONSOLE DEBUG: Device info - iOS version: %{public}@", log: ViewController.log, type: .info, UIDevice.current.systemVersion)
        os_log("🔍 CONSOLE DEBUG: Device model: %{public}@", log: ViewController.log, type: .info, UIDevice.current.model)
        os_log("🔍 CONSOLE DEBUG: Device name: %{public}@", log: ViewController.log, type: .info, UIDevice.current.name)
        os_log("🔍 ViewController: Device info - iOS: %{public}@, Model: %{public}@", log: ViewController.log, type: .info, UIDevice.current.systemVersion, UIDevice.current.model)
        
        guard SatocardController.isAvailable else {
            showMessage("❌ DEBUG: SatocardController.isAvailable returned false")
            showMessage("❌ DEBUG: NFCTagReaderSession.readingAvailable: \(NFCTagReaderSession.readingAvailable)")
            showMessage("NFC is not available on this device.")
            
            // Console-only additional info
            os_log("❌ CONSOLE DEBUG: NFC not available - check device capabilities and entitlements", log: ViewController.log, type: .error)
            os_log("❌ CONSOLE DEBUG: Make sure device supports NFC and app has proper entitlements", log: ViewController.log, type: .error)
            os_log("🔍 ViewController: ❌ NFC not available - SatocardController.isAvailable returned false", log: ViewController.log, type: .error)
            return
        }
        showMessage("✅ DEBUG: SatocardController.isAvailable returned true")
        os_log("✅ CONSOLE DEBUG: NFC is available on this device", log: ViewController.log, type: .info)
        os_log("🔍 ViewController: ✅ NFC is available - SatocardController.isAvailable returned true", log: ViewController.log, type: .info)
        
        // Start NFC session to detect Satochip card using SatochipSwift
        showMessage("🔍 DEBUG: Creating SatocardController...")
        showMessage("Starting NFC session... Hold your Satochip card near the device")
        os_log("🔍 ViewController: Creating SatocardController...", log: ViewController.log, type: .info)
        os_log("🔍 ViewController: Starting NFC session to detect Satochip card", log: ViewController.log, type: .info)
        
        let alertMessages = SatocardController.defaultAlertMessages
        showMessage("🔍 DEBUG: Using default alert messages: \(alertMessages)")
        print("🔍 CONSOLE DEBUG: Alert messages: \(alertMessages)")
        print("🔍 ViewController: Using default alert messages: \(alertMessages)")
        
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
                    print("🔍 ViewController: ===== CARD CONNECTED =====")
                    print("🔍 ViewController: CardChannel type: \(type(of: cardChannel))")
                    print("🔍 ViewController: CardChannel description: \(cardChannel)")
                    
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
                    print("🔍 ViewController: ===== NFC FAILURE =====")
                    print("🔍 ViewController: Error type: \(type(of: error))")
                    print("🔍 ViewController: Error domain: \(error._domain)")
                    print("🔍 ViewController: Error code: \(error._code)")
                    print("🔍 ViewController: Error description: \(error.localizedDescription)")
                    // Note: userInfo not available on generic Error type
                }
            }
        ) else {
            showMessage("❌ DEBUG: SatocardController initialization failed")
            showMessage("Failed to initialize NFC session. Please try again.")
            print("❌ CONSOLE DEBUG: SatocardController initialization failed")
            print("❌ CONSOLE DEBUG: This could be due to NFC not being available or session creation issues")
            print("🔍 ViewController: ❌ SatocardController initialization failed")
            return
        }
        
        showMessage("✅ DEBUG: SatocardController created successfully")
        showMessage("🔍 DEBUG: Starting NFC session...")
        print("✅ CONSOLE DEBUG: SatocardController created successfully")
        print("🔍 CONSOLE DEBUG: Starting NFC session with alert message")
        print("🔍 ViewController: ✅ SatocardController created successfully")
        print("🔍 ViewController: Starting NFC session...")
        
        controller.start(alertMessage: "Hold your Satochip card near the device to begin signing")
        messageInputTextView.resignFirstResponder() // Dismiss keyboard
        
        showMessage("🔍 DEBUG: NFC session started, waiting for card detection...")
        print("🔍 CONSOLE DEBUG: NFC session started, waiting for card detection...")
        print("🔍 CONSOLE DEBUG: User should now hold Satochip card near the device")
        print("🔍 ViewController: ✅ NFC session started, waiting for card detection...")
        print("🔍 ViewController: User should now hold Satochip card near the device")
        
        // Add a small delay to check if session becomes active
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showMessage("🔍 DEBUG: Checking session status after 2 seconds...")
            print("🔍 CONSOLE DEBUG: Checking session status after 2 seconds...")
            print("🔍 ViewController: Checking session status after 2 seconds...")
            // If we haven't seen any callbacks by now, there might be an issue
        }
        
        // Add a timeout after 30 seconds to give users time to position their card
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            self.showMessage("⏰ DEBUG: NFC session timeout - no activity detected")
            print("⏰ CONSOLE DEBUG: NFC session timeout - no activity detected")
            print("⏰ CONSOLE DEBUG: This might indicate NFC is disabled or app lacks permissions")
            print("🔍 ViewController: ⏰ NFC session timeout - no activity detected")
        }
    }
    
    private func handleSatochipConnection(cardChannel: CardChannel, message: String, pin: String) {
        showMessage("🔍 DEBUG: handleSatochipConnection called")
        showMessage("🔍 DEBUG: CardChannel type: \(type(of: cardChannel))")
        print("🔍 CONSOLE DEBUG: handleSatochipConnection called")
        print("🔍 CONSOLE DEBUG: CardChannel type: \(type(of: cardChannel))")
        print("🔍 CONSOLE DEBUG: CardChannel description: \(cardChannel)")
        print("🔍 ViewController: ===== HANDLING SATOCHIP CONNECTION =====")
        print("🔍 ViewController: CardChannel type: \(type(of: cardChannel))")
        print("🔍 ViewController: CardChannel description: \(cardChannel)")
        
        // Create SatochipCommandSet for communication
        showMessage("🔍 DEBUG: Creating SatocardCommandSet...")
        let commandSet = SatocardCommandSet(cardChannel: cardChannel)
        showMessage("✅ DEBUG: SatocardCommandSet created successfully")
        print("🔍 CONSOLE DEBUG: Creating SatocardCommandSet...")
        print("✅ CONSOLE DEBUG: SatocardCommandSet created successfully")
        print("🔍 ViewController: Creating SatocardCommandSet...")
        print("🔍 ViewController: ✅ SatocardCommandSet created successfully")
        
        showMessage("Card connected! Identifying card type...")
        print("🔍 CONSOLE DEBUG: Card connected! Starting identification...")
        print("🔍 ViewController: Card connected! Starting identification...")
        
        // Perform card identification
        showMessage("🔍 DEBUG: Attempting to select applet with .anycard...")
        print("🔍 CONSOLE DEBUG: Attempting to select applet with .anycard...")
        print("🔍 ViewController: Attempting to select applet with .anycard...")
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
            print("🔍 ViewController: ✅ selectApplet succeeded")
            print("🔍 ViewController: Response status word: 0x\(String(response.sw, radix: 16, uppercase: true))")
            print("🔍 ViewController: Response data length: \(response.data.count) bytes")
            print("🔍 ViewController: Response data (hex): \(response.data.map { String(format: "%02X", $0) }.joined(separator: " "))")
            print("🔍 ViewController: Detected card type: \(cardType)")
            
            switch cardType {
            case .satochip:
                showMessage("✅ Satochip card detected!")
                showMessage("Card Type: \(cardType.rawValue)")
                print("🔍 ViewController: ✅ Satochip card detected!")
                print("🔍 ViewController: Card Type: \(cardType.rawValue)")
                
                if let status = commandSet.cardStatus {
                    showMessage("📊 Card Status:")
                    showMessage("  • Setup Done: \(status.setupDone ? "✅" : "❌")")
                    showMessage("  • Is Seeded: \(status.isSeeded ? "✅" : "❌")")
                    showMessage("  • Needs Secure Channel: \(status.needsSecureChannel ? "✅" : "❌")")
                    showMessage("  • Protocol Version: \(status.protocolMajorVersion).\(status.protocolMinorVersion)")
                    showMessage("  • Applet Version: \(status.appletMajorVersion).\(status.appletMinorVersion)")
                    showMessage("  • PIN0 Remaining Tries: \(status.pin0RemainingTries)")
                    
                    print("🔍 ViewController: 📊 Card Status:")
                    print("🔍 ViewController:   • Setup Done: \(status.setupDone ? "✅" : "❌")")
                    print("🔍 ViewController:   • Is Seeded: \(status.isSeeded ? "✅" : "❌")")
                    print("🔍 ViewController:   • Needs Secure Channel: \(status.needsSecureChannel ? "✅" : "❌")")
                    print("🔍 ViewController:   • Protocol Version: \(status.protocolMajorVersion).\(status.protocolMinorVersion)")
                    print("🔍 ViewController:   • Applet Version: \(status.appletMajorVersion).\(status.appletMinorVersion)")
                    print("🔍 ViewController:   • PIN0 Remaining Tries: \(status.pin0RemainingTries)")
                } else {
                    showMessage("⚠️ Card status information not available")
                    print("🔍 ViewController: ⚠️ Card status information not available")
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
            print("🔍 ViewController: ❌ selectApplet failed with error")
            print("🔍 ViewController: Error type: \(type(of: error))")
            print("🔍 ViewController: Error description: \(error.localizedDescription)")
            // Note: userInfo not available on generic Error type
            if let satocardError = error as? SatocardError {
                print("🔍 CONSOLE DEBUG: SatocardError case: \(satocardError)")
                print("🔍 ViewController: SatocardError case: \(satocardError)")
            }
            print("❌ CONSOLE DEBUG: Card identification failed - check card compatibility")
            print("🔍 ViewController: ❌ Card identification failed - check card compatibility")
        }
    }
    
    private func handleSatochipOperations(commandSet: SatocardCommandSet, message: String, pin: String) {
        showMessage("🔍 DEBUG: handleSatochipOperations called")
        showMessage("🔍 DEBUG: CommandSet type: \(type(of: commandSet))")
        showMessage("Starting Satochip operations...")
        showMessage("Message to sign: \(message)")
        showMessage("PIN: \(pin)")
        print("🔍 ViewController: ===== HANDLING SATOCHIP OPERATIONS =====")
        print("🔍 ViewController: CommandSet type: \(type(of: commandSet))")
        print("🔍 ViewController: Starting Satochip operations...")
        print("🔍 ViewController: Message to sign: \(message)")
        print("🔍 ViewController: PIN: \(pin)")
        
        // TODO: Implement the next steps:
        // 1. Secure channel establishment
        // 2. PIN verification
        // 3. Message hashing and signing
        
        showMessage("Satochip operations ready for next implementation phase...")
        print("🔍 ViewController: Satochip operations ready for next implementation phase...")
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
        // Update PIN status every 60 seconds to show countdown
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updatePINStatus()
        }
    }
}
