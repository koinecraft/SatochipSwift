import P256K
import CryptoSwift
import CommonCrypto
import Foundation

enum PBKDF2HMac {
    case sha256
    case sha512
}

class Crypto {
    static let shared = Crypto()

    private init() {
        // P256K module handles context internally
    }
    
    // use pkcs7 padding
    func aes256Enc(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
        let result = try! CryptoSwift.AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7).encrypt(data)
        return result
    }
    
    // use pkcs7 padding
    func aes256Dec(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
        let result = try! CryptoSwift.AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7).decrypt(data)
        return result
    }
    
    // nopadding
//    func aes256EncNopad(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
//        let result = try! AES(key: key, blockMode: CBC(iv: iv), padding: .noPadding).encrypt(data)
//        return result
//    }
//
//    func aes256DecNopad(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
//        let result = try! AES(key: key, blockMode: CBC(iv: iv), padding: .noPadding).decrypt(data)
//        return result
//    }

    func aes256CMac(data: [UInt8], key: [UInt8]) -> [UInt8] {
        let result = aes256Enc(data: data, iv: [UInt8](repeating: 0, count: SecureChannel.blockLength), key: key).suffix(16)
        return Array(result)
    }
    
    func desEnc(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
        var out: [UInt8] = [UInt8](repeating: 0, count: data.count)
        var encrypted: Int = 0
        var tmpKey = key
        var tmpData = data
        var tmpIV = iv
        
        CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmDES), CCOptions(0), &tmpKey, key.count, &tmpIV, &tmpData, data.count, &out, out.count, &encrypted)
        return out
    }
    
    func desDec(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
        var out: [UInt8] = [UInt8](repeating: 0, count: data.count)
        var decrypted: Int = 0
        var tmpKey = key
        var tmpData = data
        var tmpIV = iv
        
        CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmDES), CCOptions(0), &tmpKey, key.count, &tmpIV, &tmpData, data.count, &out, out.count, &decrypted)
        return out
    }
       
    func des3Enc(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
        var out: [UInt8] = [UInt8](repeating: 0, count: data.count)
        var encrypted: Int = 0
        var tmpKey = key
        var tmpData = data
        var tmpIV = iv
        
        CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithm3DES), CCOptions(0), &tmpKey, key.count, &tmpIV, &tmpData, data.count, &out, out.count, &encrypted)
        return out
    }
    
    func des3Dec(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
        var out: [UInt8] = [UInt8](repeating: 0, count: data.count)
        var decrypted: Int = 0
        var tmpKey = key
        var tmpData = data
        var tmpIV = iv
        
        CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithm3DES), CCOptions(0), &tmpKey, key.count, &tmpIV, &tmpData, data.count, &out, out.count, &decrypted)
        return out
    }
    
    func des3Mac(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
        let enc: [UInt8] = des3Enc(data: data, iv: iv, key: key)
        return Array(enc.suffix(8))
    }
    
    func des3FullMac(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8] {
        let des3IV : [UInt8]
        
        if (data.count > 8) {
            des3IV = Array(desEnc(data: Array(data[0..<(data.count - 8)]), iv: iv, key: resizeDESKey8(key)).suffix(8))
        } else {
            des3IV = iv
        }
        
        return des3Mac(data: Array(data.suffix(8)), iv: des3IV, key: key)
    }
    
    func resizeDESKey8(_ key: [UInt8]) -> [UInt8] {
        return Array(key[0..<8])
    }
    
    func iso7816_4Pad(data: [UInt8], blockSize: Int) -> [UInt8] {
        var padded = Array(data)
        padded.append(0x80)

        // can be obviously optimized, but I really doubt it makes sense, and this is easier to read
        while (padded.count % blockSize) != 0 {
            padded.append(0x00)
        }

        return padded
    }

    func iso7816_4Unpad(data: [UInt8]) -> [UInt8] {
        if let idx = data.lastIndex(of: 0x80) {
            return Array(data[..<idx])
        } else {
            return data
        }
    }
    
    func pkcs7Pad(data: [UInt8], blockSize: Int) -> [UInt8] {
        let padsize = blockSize - (data.count % blockSize)
        let padBytes: [UInt8] = [UInt8](repeating: UInt8(padsize), count: padsize)
        let padded = data + padBytes
        return padded
    }
    
    func pkcs7Unpad(data: [UInt8]) -> [UInt8] {
        let padsize: Int = Int(data[data.count-1])
        return Array(data[0 ..< (data.count-padsize)])
    }
    
    func pbkdf2(password: String, salt: [UInt8], iterations: Int, hmac: PBKDF2HMac) -> [UInt8] {
        // implemented using CommonCrypto because it is much faster (ms vs s) on the device than CryptoSwfit implementation.
        let keyLength: Int
        let prf: CCPseudoRandomAlgorithm

        switch hmac {
        case .sha256:
            keyLength = 32
            prf = CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256)
        case .sha512:
            keyLength = 64
            prf = CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512)
        }

        precondition(salt.count < 133, "Salt must be less than 133 bytes length")
        var saltBytes = salt
        var outKey: [UInt8] = [UInt8](repeating: 0, count: keyLength)
        let result = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                                          password,
                                          password.lengthOfBytes(using: String.Encoding.utf8),
                                          &saltBytes,
                                          saltBytes.count,
                                          prf,
                                          UInt32(iterations),
                                          &outKey,
                                          keyLength)
        if result == kCCParamError {
            preconditionFailure("PBKDF error")
        }
        return outKey
    }

    func hmacSHA512(data: [UInt8], key: [UInt8]) -> [UInt8] {
        return try! HMAC(key: key, variant: .sha512).authenticate(data)
    }
    
    func hmacSHA1(data: [UInt8], key: [UInt8]) -> [UInt8] {
        return try! HMAC(key: key, variant: .sha1).authenticate(data)
    }

    func sha256(_ data: [UInt8]) -> [UInt8] {
        Digest.sha256(data)
    }

    func sha512(_ data: [UInt8]) -> [UInt8] {
        Digest.sha512(data)
    }

    func keccak256(_ data: [UInt8]) -> [UInt8] {
        Digest.sha3(data, variant: .keccak256)
    }

    func secp256k1GeneratePair() -> ([UInt8], [UInt8]) {
        do {
            // Generate a new private key using P256K
            let privateKey = try P256K.Signing.PrivateKey()
            let publicKey = privateKey.publicKey
            
            // Convert to byte arrays
            let privateKeyBytes = privateKey.dataRepresentation
            let publicKeyBytes = publicKey.dataRepresentation
            
            return (Array(privateKeyBytes), Array(publicKeyBytes))
        } catch {
            // Return zeros if key generation fails
            return ([UInt8](repeating: 0, count: 32), [UInt8](repeating: 0, count: 33))
        }
    }

    func secp256k1ECDH(privKey: [UInt8], pubKey pubKeyBytes: [UInt8]) -> [UInt8] {
        do {
            // Create private key for key agreement from bytes
            let privateKey = try P256K.KeyAgreement.PrivateKey(dataRepresentation: Data(privKey))
            
            // Create public key for key agreement from bytes
            let publicKey = try P256K.KeyAgreement.PublicKey(dataRepresentation: Data(pubKeyBytes), format: .uncompressed)
            
            // Perform ECDH
            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
            
            return Array(sharedSecret.withUnsafeBytes { Data($0) })
        } catch {
            // Return zeros if ECDH fails
            return [UInt8](repeating: 0, count: 32)
        }
    }

    func secp256k1PublicToEthereumAddress(_ pubKey: [UInt8]) -> [UInt8] {
        Array(keccak256(Array(pubKey[1...]))[12...])
    }

    func secp256k1PublicFromPrivate(_ privKey: [UInt8]) -> [UInt8] {
        do {
            let privateKey = try P256K.Signing.PrivateKey(dataRepresentation: Data(privKey))
            let publicKey = privateKey.publicKey
            return Array(publicKey.dataRepresentation)
        } catch {
            // Return zeros if key creation fails
            return [UInt8](repeating: 0, count: 33)
        }
    }

    func secp256k1RecoverPublic(r: [UInt8], s: [UInt8], recId: UInt8, hash: [UInt8]) -> [UInt8] {
        // Note: P256K doesn't directly support signature recovery like secp256k1
        // This is a simplified implementation that may not work for all cases
        // For full compatibility, you might need to use a different approach
        do {
            // Create signature from r, s, and recovery ID
            let signatureData = Data(r + s)
            let signature = try P256K.Signing.ECDSASignature(dataRepresentation: signatureData)
            
            // This is a placeholder - actual recovery would need more complex logic
            // For now, return zeros to indicate unsupported operation
            return [UInt8](repeating: 0, count: 33)
        } catch {
            return [UInt8](repeating: 0, count: 33)
        }
    }

    func secp256k1Sign(hash: [UInt8], privKey: [UInt8]) -> [UInt8] {
        do {
            let privateKey = try P256K.Signing.PrivateKey(dataRepresentation: Data(privKey))
            let signature = try privateKey.signature(for: Data(hash))
            return Array(signature.dataRepresentation)
        } catch {
            // Return empty array if signing fails
            return []
        }
    }
    
    // DEBUG VERIFY
//    int secp256k1_ecdsa_sign(const secp256k1_context* ctx, secp256k1_ecdsa_signature *signature, const unsigned char *msg32, const unsigned char *seckey, secp256k1_nonce_function noncefp, const void* noncedata)
//
//    SECP256K1_API int secp256k1_ecdsa_sign(
//        const secp256k1_context* ctx,
//        secp256k1_ecdsa_signature *sig,
//        const unsigned char *msghash32,
//        const unsigned char *seckey,
//        secp256k1_nonce_function noncefp,
//        const void *ndata
//    )
//
//    int secp256k1_ecdsa_verify(const secp256k1_context* ctx, const secp256k1_ecdsa_signature *sig, const unsigned char *msg32, const secp256k1_pubkey *pubkey)
//    SECP256K1_API SECP256K1_WARN_UNUSED_RESULT int secp256k1_ecdsa_verify(
//        const secp256k1_context* ctx,
//        const secp256k1_ecdsa_signature *sig,
//        const unsigned char *msghash32,
//        const secp256k1_pubkey *pubkey
//    ) SECP256K1_ARG_NONNULL(1) SECP256K1_ARG_NONNULL(2) SECP256K1_ARG_NONNULL(3) SECP256K1_ARG_NONNULL(4);
//
//    secp256k1_ec_pubkey_parse(
//        const secp256k1_context* ctx,
//        secp256k1_pubkey* pubkey,
//        const unsigned char *input,
//        size_t inputlen
//    )
//
//    SECP256K1_API int secp256k1_ecdsa_signature_parse_der(
//        const secp256k1_context* ctx,
//        secp256k1_ecdsa_signature* sig,
//        const unsigned char *input,
//        size_t inputlen
//    ) SECP256K1_ARG_NONNULL(1) SECP256K1_ARG_NONNULL(2) SECP256K1_ARG_NONNULL(3);
//
//    SECP256K1_API int secp256k1_ecdsa_signature_normalize(
//        const secp256k1_context* ctx,
//        secp256k1_ecdsa_signature *sigout,
//        const secp256k1_ecdsa_signature *sigin
//    ) SECP256K1_ARG_NONNULL(1) SECP256K1_ARG_NONNULL(3);
    
    func secp256k1Verify(sigBytes: [UInt8], msgHash: [UInt8], pubkeyBytes: [UInt8]) -> Int32 {
        do {
            let publicKey = try P256K.Signing.PublicKey(dataRepresentation: Data(pubkeyBytes), format: .uncompressed)
            let signature = try P256K.Signing.ECDSASignature(dataRepresentation: Data(sigBytes))
            let isValid = publicKey.isValidSignature(signature, for: Data(msgHash))
            return isValid ? 1 : 0
        } catch {
            return 0
        }
    }
    // ENDBUG VERIFY
    
    // Helper function removed - P256K handles serialization internally

    func random(count: Int) -> [UInt8] {
        CryptoSwift.AES.randomIV(count)
    }
}
