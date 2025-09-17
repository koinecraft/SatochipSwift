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
        guard isNFCAvailable else {
            completion(false, "NFC is not available on this device")
            return
        }
        
        completionHandler = completion
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "Hold your Satochip card near the iPhone to begin communication"
        nfcSession?.begin()
    }
    
    /// Stops the current NFC session
    func stopNFCSession() {
        nfcSession?.invalidate()
        nfcSession = nil
        completionHandler = nil
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
        DispatchQueue.main.async { [weak self] in
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    self?.completionHandler?(false, "User cancelled NFC session")
                case .readerSessionInvalidationErrorSessionTimeout:
                    self?.completionHandler?(false, "NFC session timed out")
                case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                    self?.completionHandler?(false, "NFC session terminated unexpectedly")
                default:
                    self?.completionHandler?(false, "NFC error: \(nfcError.localizedDescription)")
                }
            } else {
                self?.completionHandler?(false, "NFC error: \(error.localizedDescription)")
            }
            self?.completionHandler = nil
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // This method is called when NDEF messages are detected
        // For Satochip cards, we'll need to handle raw tag communication instead
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(false, "NDEF messages detected, but Satochip cards use raw tag communication")
            self?.completionHandler = nil
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        // This method is called when NFC tags are detected
        // For now, we'll just report that a tag was detected
        // Later we'll implement Satochip-specific tag handling
        DispatchQueue.main.async { [weak self] in
            if let tag = tags.first {
                self?.completionHandler?(true, "NFC tag detected: \(tag)")
            } else {
                self?.completionHandler?(false, "No NFC tags detected")
            }
            self?.completionHandler = nil
        }
    }
}
