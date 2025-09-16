# SatochipSwift Usage Examples and Integration Guide

## Table of Contents
1. [Basic Setup](#basic-setup)
2. [Satochip Examples](#satochip-examples)
3. [Satodime Examples](#satodime-examples)
4. [Seedkeeper Examples](#seedkeeper-examples)
5. [Error Handling](#error-handling)
6. [Best Practices](#best-practices)
7. [Integration Patterns](#integration-patterns)

---

## Basic Setup

### Adding the Package Dependency

Add SatochipSwift to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SatochipSwift.git", from: "0.2.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version and add to your target

### Basic NFC Setup

```swift
import SatochipSwift
import CoreNFC

class ViewController: UIViewController {
    private var satocardController: SatocardController?
    private var commandSet: SatocardCommandSet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNFC()
    }
    
    private func setupNFC() {
        guard SatocardController.isAvailable else {
            print("NFC not available on this device")
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
}
```

---

## Satochip Examples

### Card Detection and Setup

```swift
private func detectCardType() {
    guard let commandSet = commandSet else { return }
    
    do {
        let (response, cardType) = try commandSet.selectApplet(cardType: .anycard)
        print("Detected card type: \(cardType)")
        
        switch cardType {
        case .satochip:
            handleSatochipCard()
        case .satodime:
            handleSatodimeCard()
        case .seedkeeper:
            handleSeedkeeperCard()
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
        let pin = "123456".bytes
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
        let pin = "123456".bytes
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
```

### BIP32 Key Derivation

```swift
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
        
        // Derive an Ethereum address (m/44'/60'/0'/0/0)
        let ethereumPath = "m/44'/60'/0'/0/0"
        let (ethPubkey, ethChaincode) = try commandSet.cardBip32GetExtendedkey(path: ethereumPath)
        let ethereumAddress = Crypto.shared.secp256k1PublicToEthereumAddress(ethPubkey)
        print("Ethereum address: \(ethereumAddress.bytesToHex)")
        
    } catch SatocardError.pathTooLongForBip32Derivation(let length, let expected) {
        print("BIP32 path too long: \(length), expected max: \(expected)")
    } catch {
        print("Error performing secure operations: \(error)")
    }
}
```

### Transaction Signing

```swift
private func signTransaction() {
    guard let commandSet = commandSet else { return }
    
    do {
        // This would typically be called through the secure channel
        // The actual implementation depends on the specific transaction format
        
        // Example: Sign a message hash
        let messageHash = "Hello, Satochip!".data(using: .utf8)!.sha256
        let signature = try commandSet.cardSignMessage(messageHash: messageHash)
        print("Message signed successfully")
        
    } catch {
        print("Error signing transaction: \(error)")
    }
}
```

---

## Satodime Examples

### Satodime Card Setup

```swift
private func handleSatodimeCard() {
    guard let commandSet = commandSet else { return }
    
    do {
        // Get Satodime status
        let statusResponse = try commandSet.satodimeGetStatus()
        let satodimeStatus = commandSet.satodimeStatus
        
        if !satodimeStatus.setupDone {
            setupSatodimeCard()
        } else {
            print("Satodime card is already set up")
            print("Max keys: \(satodimeStatus.maxNumKeys)")
            print("Is owner: \(satodimeStatus.isOwner)")
        }
    } catch {
        print("Error handling Satodime card: \(error)")
    }
}

private func setupSatodimeCard() {
    guard let commandSet = commandSet else { return }
    
    do {
        let response = try commandSet.satodimeCardSetup()
        print("Satodime setup completed")
        
        // Store the unlock secret securely
        let unlockSecret = commandSet.satodimeStatus.unlockSecret
        print("Unlock secret generated. Store this securely!")
        
    } catch {
        print("Error setting up Satodime: \(error)")
    }
}
```

### Key Slot Management

```swift
private func manageKeySlots() {
    guard let commandSet = commandSet else { return }
    
    do {
        let keySlotNumber: UInt8 = 0
        
        // Get key slot status
        let keyslotResponse = try commandSet.satodimeGetKeyslotStatus(keyNbr: keySlotNumber)
        print("Key slot \(keySlotNumber) status retrieved")
        
        // Configure key slot for Bitcoin
        let slip44Bitcoin: UInt32 = 0 // Bitcoin SLIP-44
        let contractAddress: [UInt8] = [] // Empty for Bitcoin
        let tokenId: [UInt8] = [] // Empty for Bitcoin
        
        try commandSet.satodimeSetKeyslotStatusPart0(
            keyNbr: keySlotNumber,
            RFU1: 0,
            RFU2: 0,
            keyAsset: 0, // Bitcoin
            keySlip44: slip44Bitcoin,
            keyContract: contractAddress,
            keyTokenid: tokenId
        )
        
        // Generate key data (this would typically be done with proper entropy)
        let keyData = Crypto.shared.random(count: 66) // 64 bytes + 2 bytes for size
        try commandSet.satodimeSetKeyslotStatusPart1(keyNbr: keySlotNumber, keyData: keyData)
        
        print("Key slot \(keySlotNumber) configured for Bitcoin")
        
    } catch SatodimeApiError.wrongSlip44Size(let length, let expected) {
        print("SLIP-44 size error: \(length), expected: \(expected)")
    } catch {
        print("Error managing key slots: \(error)")
    }
}

private func sealAndUnsealKey() {
    guard let commandSet = commandSet else { return }
    
    do {
        let keySlotNumber: UInt8 = 0
        
        // Seal the key with user entropy
        let userEntropy = Crypto.shared.random(count: 32)
        try commandSet.satodimeSealKey(keyNbr: keySlotNumber, entropyUser: userEntropy)
        print("Key slot \(keySlotNumber) sealed")
        
        // Later, unseal the key
        try commandSet.satodimeUnsealKey(keyNbr: keySlotNumber)
        print("Key slot \(keySlotNumber) unsealed")
        
        // Get the private key
        let privkeyResponse = try commandSet.satodimeGetPrivkey(keyNbr: keySlotNumber)
        print("Private key retrieved")
        
    } catch {
        print("Error sealing/unsealing key: \(error)")
    }
}
```

### Ownership Transfer

```swift
private func transferOwnership() {
    guard let commandSet = commandSet else { return }
    
    do {
        // Current owner initiates transfer
        let response = try commandSet.satodimeInitiateOwnershipTransfer()
        print("Ownership transfer initiated")
        
        // The new owner would need to complete the transfer process
        // This involves providing the unlock secret and completing the handshake
        
    } catch {
        print("Error initiating ownership transfer: \(error)")
    }
}
```

---

## Seedkeeper Examples

### Seedkeeper Setup and Status

```swift
private func handleSeedkeeperCard() {
    guard let commandSet = commandSet else { return }
    
    do {
        // Get Seedkeeper status
        let (statusResponse, seedkeeperStatus) = try commandSet.seedkeeperGetStatus()
        print("Seedkeeper status:")
        print("  Secrets stored: \(seedkeeperStatus.nbSecrets)")
        print("  Total memory: \(seedkeeperStatus.totalMemory)")
        print("  Free memory: \(seedkeeperStatus.freeMemory)")
        print("  Available logs: \(seedkeeperStatus.nbLogsAvail)")
        
        // List existing secrets
        let secretHeaders = try commandSet.seedkeeperListSecretHeaders()
        print("Found \(secretHeaders.count) secrets:")
        for header in secretHeaders {
            print("  - \(header.label) (ID: \(header.sid), Type: \(header.type))")
        }
        
    } catch {
        print("Error handling Seedkeeper card: \(error)")
    }
}
```

### Secret Generation

```swift
private func generateSecrets() {
    guard let commandSet = commandSet else { return }
    
    do {
        // Generate a master seed
        let (response, header) = try commandSet.seedkeeperGenerateRandomSecret(
            stype: .masterseed,
            subtype: 0,
            size: 32,
            saveEntropy: true,
            entropy: Crypto.shared.random(count: 32),
            exportRights: .exportBoth,
            label: "My Bitcoin Wallet"
        )
        
        print("Master seed generated with ID: \(header[0].sid)")
        
        // Generate a 2FA secret
        let (faResponse, faHeader) = try commandSet.seedkeeperGenerateRandomSecret(
            stype: .secret2FA,
            subtype: 0,
            size: 20,
            saveEntropy: false,
            entropy: [],
            exportRights: .exportPlaintext,
            label: "Google Authenticator"
        )
        
        print("2FA secret generated with ID: \(faHeader[0].sid)")
        
    } catch SeedkeeperApiError.wrongSecretSize(let size) {
        print("Invalid secret size: \(size). Must be between 16-64 bytes.")
    } catch {
        print("Error generating secrets: \(error)")
    }
}
```

### Secret Import and Export

```swift
private func importAndExportSecrets() {
    guard let commandSet = commandSet else { return }
    
    do {
        // Create a secret object to import
        let secretData = Crypto.shared.random(count: 32)
        let secretHeader = SeedkeeperSecretHeader(
            sid: 0, // Will be assigned by the card
            type: .masterseed,
            subtype: 0,
            origin: .importedPlaintext,
            exportRights: .exportBoth,
            nbExportPlaintext: 0,
            nbExportEncrypted: 0,
            useCounter: 0,
            fingerprintBytes: [],
            label: "Imported Wallet"
        )
        
        let secretObject = SeedkeeperSecretObject(
            secretBytes: secretData,
            secretHeader: secretHeader,
            isEncrypted: false
        )
        
        // Import the secret
        let (importResponse, secretId, fingerprint) = try commandSet.seedkeeperImportSecret(
            secretObject: secretObject
        )
        print("Secret imported with ID: \(secretId)")
        
        // Later, export the secret
        let exportedSecret = try commandSet.seedkeeperExportSecret(sid: secretId)
        print("Secret exported successfully")
        print("Label: \(exportedSecret.secretHeader.label)")
        
    } catch {
        print("Error importing/exporting secrets: \(error)")
    }
}
```

### BIP32 Derivation with Seedkeeper

```swift
private func deriveKeysFromSeedkeeper() {
    guard let commandSet = commandSet else { return }
    
    do {
        // First, get the secret ID from the list
        let secretHeaders = try commandSet.seedkeeperListSecretHeaders()
        guard let masterSeedHeader = secretHeaders.first(where: { $0.type == .masterseed }) else {
            print("No master seed found")
            return
        }
        
        let secretId = masterSeedHeader.sid
        
        // Derive Bitcoin keys using the master seed
        let bitcoinPath = "m/44'/0'/0'/0/0"
        let (pubkey, chaincode) = try commandSet.cardBip32GetExtendedkey(
            path: bitcoinPath,
            sid: secretId
        )
        print("Bitcoin public key derived: \(pubkey.bytesToHex)")
        
        // Get extended private key (Seedkeeper only)
        let xprv = try commandSet.cardBip32GetXprv(
            path: bitcoinPath,
            xtype: 0x0488ADE4, // Bitcoin mainnet xprv
            sid: secretId
        )
        print("Bitcoin xprv: \(xprv)")
        
    } catch {
        print("Error deriving keys: \(error)")
    }
}
```

### Password Derivation

```swift
private func derivePasswords() {
    guard let commandSet = commandSet else { return }
    
    do {
        // Find a master password secret
        let secretHeaders = try commandSet.seedkeeperListSecretHeaders()
        guard let masterPasswordHeader = secretHeaders.first(where: { $0.type == .masterPassword }) else {
            print("No master password found")
            return
        }
        
        let secretId = masterPasswordHeader.sid
        
        // Derive a password for a specific service
        let serviceSalt = "github.com".data(using: .utf8)!
        let (response, derivedSecret) = try commandSet.seedkeeperDeriveMasterPassword(
            salt: serviceSalt.bytes,
            sid: secretId
        )
        
        print("Derived password for GitHub: \(derivedSecret.secret.bytesToHex)")
        
    } catch {
        print("Error deriving password: \(error)")
    }
}
```

---

## Error Handling

### Comprehensive Error Handling

```swift
private func handleCardOperations() {
    guard let commandSet = commandSet else { return }
    
    do {
        try performCardOperation()
    } catch SatocardError.pinRequired {
        print("PIN is required for this operation")
        // Prompt user for PIN
    } catch SatocardError.wrongCardType {
        print("Wrong card type detected")
        // Handle wrong card type
    } catch SatocardError.wrongResponseLength(let length, let expected) {
        print("Response length mismatch: got \(length), expected \(expected)")
    } catch SatocardError.pathTooLongForBip32Derivation(let length, let expected) {
        print("BIP32 path too long: \(length), max allowed: \(expected)")
    } catch CardError.wrongPIN(let retryCounter) {
        print("Wrong PIN entered. Retries remaining: \(retryCounter)")
        // Update UI to show remaining retries
    } catch CardError.pinBlocked {
        print("PIN is blocked. Use PUK to unblock.")
        // Show PUK entry dialog
    } catch SatodimeApiError.wrongSlip44Size(let length, let expected) {
        print("SLIP-44 size error: \(length), expected: \(expected)")
    } catch SeedkeeperApiError.wrongSecretSize(let size) {
        print("Invalid secret size: \(size). Must be 16-64 bytes.")
    } catch MnemonicError.wrongBip39Word(let word) {
        print("Invalid BIP39 word: \(word)")
    } catch MnemonicError.wrongBip39Checksum {
        print("BIP39 checksum validation failed")
    } catch {
        print("Unexpected error: \(error)")
    }
}
```

### Retry Logic

```swift
private func performOperationWithRetry<T>(_ operation: () throws -> T, maxRetries: Int = 3) -> T? {
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            return try operation()
        } catch {
            lastError = error
            print("Attempt \(attempt) failed: \(error)")
            
            if attempt < maxRetries {
                // Wait before retry
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
    }
    
    print("Operation failed after \(maxRetries) attempts. Last error: \(lastError!)")
    return nil
}

// Usage
private func secureOperation() {
    let result = performOperationWithRetry {
        try commandSet?.cardBip32GetExtendedkey(path: "m/44'/0'/0'/0/0")
    }
    
    if let (pubkey, chaincode) = result {
        print("Operation successful: \(pubkey.bytesToHex)")
    }
}
```

---

## Best Practices

### 1. Always Check NFC Availability

```swift
private func checkNFCAvailability() -> Bool {
    guard SatocardController.isAvailable else {
        showAlert(title: "NFC Not Available", 
                 message: "This device does not support NFC or NFC is disabled.")
        return false
    }
    return true
}
```

### 2. Handle Background/Foreground Transitions

```swift
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Stop NFC session when leaving the view
    satocardController?.stop(alertMessage: "Session ended")
    commandSet?.cardDisconnect()
}

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Restart NFC if needed
    if commandSet == nil {
        setupNFC()
    }
}
```

### 3. Secure PIN Handling

```swift
private func promptForPIN() -> [UInt8]? {
    let alert = UIAlertController(title: "Enter PIN", message: "Enter your card PIN", preferredStyle: .alert)
    
    alert.addTextField { textField in
        textField.isSecureTextEntry = true
        textField.keyboardType = .numberPad
    }
    
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
        if let pinText = alert.textFields?.first?.text {
            let pin = pinText.data(using: .utf8)?.bytes ?? []
            self.authenticateWithPIN(pin)
        }
    })
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    present(alert, animated: true)
    return nil
}
```

### 4. Memory Management

```swift
deinit {
    // Clean up resources
    satocardController?.stop(alertMessage: nil)
    commandSet?.cardDisconnect()
}
```

### 5. Logging and Debugging

```swift
private func logCardOperation(_ operation: String, success: Bool, error: Error? = nil) {
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    let status = success ? "SUCCESS" : "FAILED"
    let errorInfo = error != nil ? " - Error: \(error!)" : ""
    
    print("[\(timestamp)] \(operation): \(status)\(errorInfo)")
    
    // In production, you might want to send this to a logging service
}
```

---

## Integration Patterns

### 1. Wallet Integration

```swift
class SatochipWalletManager {
    private var commandSet: SatocardCommandSet?
    private var isAuthenticated = false
    
    func connectToCard() -> Promise<CardType> {
        return Promise { seal in
            // NFC connection logic
            // Resolve with card type
        }
    }
    
    func authenticate(pin: String) -> Promise<Void> {
        return Promise { seal in
            // PIN authentication logic
            // Resolve on success
        }
    }
    
    func deriveAddress(path: String, coinType: CoinType) -> Promise<String> {
        return Promise { seal in
            // BIP32 derivation logic
            // Resolve with address
        }
    }
    
    func signTransaction(transaction: Transaction) -> Promise<Data> {
        return Promise { seal in
            // Transaction signing logic
            // Resolve with signature
        }
    }
}
```

### 2. Secret Management Integration

```swift
class SecretManager {
    private var commandSet: SatocardCommandSet?
    
    func storeSecret(_ secret: Data, label: String, type: SecretType) -> Promise<Int> {
        return Promise { seal in
            // Secret storage logic
            // Resolve with secret ID
        }
    }
    
    func retrieveSecret(id: Int) -> Promise<Data> {
        return Promise { seal in
            // Secret retrieval logic
            // Resolve with secret data
        }
    }
    
    func derivePassword(masterPasswordId: Int, service: String) -> Promise<String> {
        return Promise { seal in
            // Password derivation logic
            // Resolve with derived password
        }
    }
}
```

### 3. Multi-Card Support

```swift
class MultiCardManager {
    private var connectedCards: [CardType: SatocardCommandSet] = [:]
    
    func connectToAllCards() -> Promise<[CardType]> {
        return Promise { seal in
            // Connect to all available card types
            // Resolve with list of connected card types
        }
    }
    
    func getCardManager(for type: CardType) -> SatocardCommandSet? {
        return connectedCards[type]
    }
    
    func performOperation<T>(on cardType: CardType, operation: (SatocardCommandSet) throws -> T) -> Promise<T> {
        return Promise { seal in
            guard let commandSet = connectedCards[cardType] else {
                seal.reject(CardError.cardNotConnected)
                return
            }
            
            do {
                let result = try operation(commandSet)
                seal.fulfill(result)
            } catch {
                seal.reject(error)
            }
        }
    }
}
```

This comprehensive documentation provides detailed examples and integration patterns for using the SatochipSwift library in real-world applications. The examples cover all three card types and demonstrate proper error handling, security practices, and integration patterns.
