import Foundation
import CoreNFC

@available(iOS 13.0, *)
open class SatocardController: NSObject {

    /// Whether the device supports the Satochip reading
    public static var isAvailable: Bool {
        return NFCTagReaderSession.readingAvailable
    }

    private var session: NFCTagReaderSession!
    private let onConnect: (CardChannel) -> Void
    private let onFailure: (Error) -> Void
    private let alertMessages: AlertMessages

    public typealias AlertMessages = (
        moreThanOneTagFound: String,
        unsupportedTagType: String,
        tagConnectionError: String
    )

    /// User-facing alert messages to show on various events.
    public static let defaultAlertMessages = AlertMessages(
        moreThanOneTagFound: "More than one tag was found. Please present only one tag.",
        unsupportedTagType: "Unsupported Smart Card.",
        tagConnectionError: "Connection error. Please try again."
    )

    /// Creates controller with callbacks for connection and disconnection events for a Satochip
    /// - Parameter onConnect: Called when the app connected to the card
    /// - Parameter onFailure: Called when a reading session failed due to various reasons, including leaving the field
    public init?(alertMessages: AlertMessages = SatocardController.defaultAlertMessages,
                 onConnect: @escaping (CardChannel) -> Void,
                 onFailure: @escaping (Error) -> Void) {
        self.alertMessages = alertMessages
        self.onConnect = onConnect
        self.onFailure = onFailure
        super.init()
        guard let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self) else {
            return nil
        }
        self.session = session
    }

    /// Starts the session with a preconfigured message for display.
    ///
    /// When any NFC tags are detected, controller checks that it's only single tag detected
    /// otherwise it restarts the polling and notifies user with `moreThanOneTagFound` alert message.
    ///
    /// If the detected tag is not ISO7816 tag, then the session is ended with error (`unsupportedTagType` alert message).
    ///
    /// Next, controller tries to connect to the tag. If connection successful, then the `onConnect` is called
    /// on a background thread with a card channel passed in.
    ///
    /// If the connection to the tag failed, then the session is stopped with the `tagConnectionError` alert message.
    ///
    /// At any point, if the session is ended with error, the `onFailure` is called with the respective error.
    ///
    /// - Parameter alertMessage: message about usage of the NFC card
    public func start(alertMessage: String? = nil) {
        print("🔍 CONSOLE DEBUG: SatocardController.start called with alertMessage: \(alertMessage ?? "nil")")
        setAlert(alertMessage)
        print("🔍 CONSOLE DEBUG: Starting NFCTagReaderSession...")
        session.begin()
        print("🔍 CONSOLE DEBUG: NFCTagReaderSession.begin() called")
    }

    /// Stops the session with error icon and message displayed.
    /// - Parameter errorMessage: error message to display
    public func stop(errorMessage: String) {
        session.invalidate(errorMessage: errorMessage)
    }

    /// Stops the session with success icon and optionally updated message displayed.
    /// - Parameter alertMessage: alert message to update
    public func stop(alertMessage: String?) {
        setAlert(alertMessage)
        session.invalidate()
    }

    /// Updates the alert message.
    /// - Parameter alertMessage: alert message to display or nil (no-op)
    public func setAlert(_ alertMessage: String?) {
        if let message = alertMessage {
            session.alertMessage = message
        }
    }

    /// Restarts RF polling
    public func restartPolling() {
        session.restartPolling()
    }
}

@available(iOS 13.0, *)
extension SatocardController: NFCTagReaderSessionDelegate {

    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("🔍 CONSOLE DEBUG: tagReaderSessionDidBecomeActive called")
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("🔍 CONSOLE DEBUG: tagReaderSession didInvalidateWithError: \(error.localizedDescription)")
        print("🔍 CONSOLE DEBUG: Error domain: \(error._domain)")
        print("🔍 CONSOLE DEBUG: Error code: \(error._code)")
        if let nfcError = error as? NFCReaderError {
            print("🔍 CONSOLE DEBUG: NFCReaderError case: \(nfcError)")
        }
        DispatchQueue.global().async { [unowned self] in
            self.onFailure(error)
        }
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("🔍 CONSOLE DEBUG: tagReaderSession didDetect tags: \(tags.count) tags detected")
        for (index, tag) in tags.enumerated() {
            print("🔍 CONSOLE DEBUG: Tag \(index): \(tag)")
        }
        
        if tags.count > 1 {
            print("🔍 CONSOLE DEBUG: More than one tag detected, restarting polling")
            setAlert(alertMessages.moreThanOneTagFound)
            tagRemovalDetect(tags[0])
            return
        }
        guard let first = tags.first, case NFCTag.iso7816(let tag) = first else {
            print("🔍 CONSOLE DEBUG: No ISO7816 tag found or unsupported tag type")
            stop(errorMessage: alertMessages.unsupportedTagType)
            return
        }
        print("🔍 CONSOLE DEBUG: ISO7816 tag detected, attempting to connect")
        session.connect(to: first) { [weak self] error in
            guard let `self` = self else { return }
            if error != nil {
                print("🔍 CONSOLE DEBUG: Tag connection failed: \(error?.localizedDescription ?? "Unknown error")")
                self.stop(errorMessage: self.alertMessages.tagConnectionError)
                return
            }
            print("🔍 CONSOLE DEBUG: Tag connected successfully, calling onConnect")
            DispatchQueue.global().async {
                self.onConnect(CoreNFCCardChannel(tag: tag))
            }
        }
    }

    // from Apple's exapmle code
    func tagRemovalDetect(_ tag: NFCTag) {
        // In the tag removal procedure, you connect to the tag and query for
        // its availability. You restart RF polling when the tag becomes
        // unavailable; otherwise, wait for certain period of time and repeat
        // availability checking.
        session.connect(to: tag) { [weak self] error in
            guard let `self` = self else { return }
            guard error == nil && tag.isAvailable else {
                self.session.restartPolling()
                return
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
                self.tagRemovalDetect(tag)
            })
        }
    }

}
