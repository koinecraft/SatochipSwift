import UIKit
import CoreNFC

class NFCManager: NSObject {
    static let shared = NFCManager()
    
    private var nfcSession: NFCNDEFReaderSession?
    private var completionHandler: ((Bool, String?) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - NFC Session Management
    
    /// Checks if NFC is available on the device
    var isNFCAvailable: Bool {
        return NFCNDEFReaderSession.readingAvailable
    }
    
    /// Starts an NFC session to detect and read tags
    func startNFCSession(completion: @escaping (Bool, String?) -> Void) {
        print("🔍 NFCManager: startNFCSession called")
        print("🔍 NFCManager: Checking NFC availability...")
        
        guard isNFCAvailable else {
            let errorMsg = "NFC is not available on this device"
            print("❌ NFCManager: \(errorMsg)")
            completion(false, errorMsg)
            return
        }
        
        print("✅ NFCManager: NFC is available")
        completionHandler = completion
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "Hold your Satochip card near the iPhone to begin communication"
        
        print("🔍 NFCManager: Starting NFC session with message: '\(nfcSession?.alertMessage ?? "nil")'")
        nfcSession?.begin()
        print("🔍 NFCManager: NFC session started successfully")
    }
    
    /// Stops the current NFC session
    func stopNFCSession() {
        print("🔍 NFCManager: stopNFCSession called")
        nfcSession?.invalidate()
        nfcSession = nil
        completionHandler = nil
        print("🔍 NFCManager: NFC session stopped and cleaned up")
    }
    
    /// Shows an alert if NFC is not available
    func showNFCNotAvailableAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "NFC Not Available",
            message: "This device does not support NFC or NFC is disabled. Please enable NFC in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension NFCManager: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("🔍 NFCManager: readerSession didInvalidateWithError called")
        print("🔍 NFCManager: Error type: \(type(of: error))")
        print("🔍 NFCManager: Error description: \(error.localizedDescription)")
        
        DispatchQueue.main.async { [weak self] in
            if let nfcError = error as? NFCReaderError {
                print("🔍 NFCManager: NFCReaderError code: \(nfcError.code.rawValue)")
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    let msg = "User cancelled NFC session"
                    print("🔍 NFCManager: \(msg)")
                    self?.completionHandler?(false, msg)
                case .readerSessionInvalidationErrorSessionTimeout:
                    let msg = "NFC session timed out"
                    print("🔍 NFCManager: \(msg)")
                    self?.completionHandler?(false, msg)
                case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                    let msg = "NFC session terminated unexpectedly"
                    print("🔍 NFCManager: \(msg)")
                    self?.completionHandler?(false, msg)
                default:
                    let msg = "NFC error: \(nfcError.localizedDescription)"
                    print("🔍 NFCManager: \(msg)")
                    self?.completionHandler?(false, msg)
                }
            } else {
                let msg = "NFC error: \(error.localizedDescription)"
                print("🔍 NFCManager: \(msg)")
                self?.completionHandler?(false, msg)
            }
            self?.completionHandler = nil
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("🔍 NFCManager: readerSession didDetectNDEFs called")
        print("🔍 NFCManager: Number of NDEF messages: \(messages.count)")
        
        // This method is called when NDEF messages are detected
        // For Satochip cards, we'll need to handle raw tag communication instead
        DispatchQueue.main.async { [weak self] in
            let msg = "NDEF messages detected, but Satochip cards use raw tag communication"
            print("🔍 NFCManager: \(msg)")
            self?.completionHandler?(false, msg)
            self?.completionHandler = nil
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        print("🔍 NFCManager: readerSession didDetect tags called")
        print("🔍 NFCManager: Number of tags detected: \(tags.count)")
        
        // This method is called when NFC tags are detected
        // For now, we'll just report that a tag was detected
        // Later we'll implement Satochip-specific tag handling
        DispatchQueue.main.async { [weak self] in
            if let tag = tags.first {
                let msg = "NFC tag detected: \(tag)"
                print("🔍 NFCManager: \(msg)")
                self?.completionHandler?(true, msg)
            } else {
                let msg = "No NFC tags detected"
                print("🔍 NFCManager: \(msg)")
                self?.completionHandler?(false, msg)
            }
            self?.completionHandler = nil
        }
    }
}
