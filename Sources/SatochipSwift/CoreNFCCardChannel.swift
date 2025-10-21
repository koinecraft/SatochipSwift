import Foundation
import CoreNFC
import os.log

@available(iOS 13.0, *)
public class CoreNFCCardChannel: CardChannel {

    public enum Error: Swift.Error {
        case invalidAPDU
    }

    private let tag: NFCISO7816Tag

    public init(tag: NFCISO7816Tag) {
        self.tag = tag
    }

    public var connected: Bool {
        return tag.isAvailable
    }

    /// This call is blocking. Do not call it on main thread or within the `connect()` method of the NFCTagReaderSession.
    /// Instead, call it asynchronously on a background thread.
    public func send(_ cmd: APDUCommand) throws -> APDUResponse {
        dispatchPrecondition(condition: DispatchPredicate.notOnQueue(DispatchQueue.main))

        SatochipDebug("APDU Command: cla=0x\(String(format: "%02X", cmd.cla)) ins=0x\(String(format: "%02X", cmd.ins)) p1=0x\(String(format: "%02X", cmd.p1)) p2=0x\(String(format: "%02X", cmd.p2)) lc=\(cmd.data.count)", category: .cardChannel)

        typealias APDUResult = (responseData: Data, sw1: UInt8, sw2: UInt8, error: Swift.Error?)

        var result: APDUResult! = nil

        guard let apdu = NFCISO7816APDU(data: Data(cmd.serialize())) else {
            throw Error.invalidAPDU
        }

        let semaphore = DispatchSemaphore(value: 0)
        tag.sendCommand(apdu: apdu) {
            result = ($0, $1, $2, $3)
            SatochipDebug("APDU Response: data len=\(result.responseData.count) sw=0x\(String(format: "%02X%02X", result.sw1, result.sw2))", category: .cardChannel)
            semaphore.signal()
        }
        semaphore.wait()

        if let error = result.error {
            SatochipError("CardChannel error: \(error.localizedDescription)", category: .cardChannel)
            throw error
        }
        return APDUResponse(sw1: result.sw1, sw2: result.sw2, data: result.responseData.bytes)
    }

}
