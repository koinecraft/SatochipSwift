# SatochipSwift API Documentation

## Table of Contents
1. [Core Classes](#core-classes)
2. [Card Communication](#card-communication)
3. [Cryptographic Functions](#cryptographic-functions)
4. [Satochip Functions](#satochip-functions)
5. [Satodime Functions](#satodime-functions)
6. [Seedkeeper Functions](#seedkeeper-functions)
7. [Utility Functions](#utility-functions)
8. [Error Types](#error-types)
9. [Data Structures](#data-structures)

---

## Core Classes

### SatocardController

The main controller class for managing NFC communication with Satochip cards.

#### Properties
- `static var isAvailable: Bool` - Whether the device supports NFC reading
- `private var session: NFCTagReaderSession!` - The NFC session
- `private let onConnect: (CardChannel) -> Void` - Connection callback
- `private let onFailure: (Error) -> Void` - Failure callback
- `private let alertMessages: AlertMessages` - User-facing alert messages

#### Methods

##### `init?(alertMessages: AlertMessages, onConnect: @escaping (CardChannel) -> Void, onFailure: @escaping (Error) -> Void)`
Creates a controller with callbacks for connection and disconnection events.

**Parameters:**
- `alertMessages`: User-facing alert messages for various events
- `onConnect`: Called when the app connects to the card
- `onFailure`: Called when a reading session fails

**Returns:** Optional SatocardController instance

##### `start(alertMessage: String?)`
Starts the NFC session with a preconfigured message.

**Parameters:**
- `alertMessage`: Message about NFC card usage (optional)

**Returns:** Void

##### `stop(errorMessage: String)`
Stops the session with error icon and message.

**Parameters:**
- `errorMessage`: Error message to display

**Returns:** Void

##### `stop(alertMessage: String?)`
Stops the session with success icon and optional message.

**Parameters:**
- `alertMessage`: Alert message to update (optional)

**Returns:** Void

##### `setAlert(_ alertMessage: String?)`
Updates the alert message.

**Parameters:**
- `alertMessage`: Alert message to display (optional)

**Returns:** Void

##### `restartPolling()`
Restarts RF polling.

**Returns:** Void

---

### CoreNFCCardChannel

Implements the CardChannel protocol for NFC communication.

#### Properties
- `private let tag: NFCISO7816Tag` - The NFC tag
- `var connected: Bool` - Whether the tag is available

#### Methods

##### `init(tag: NFCISO7816Tag)`
Initializes the channel with an NFC tag.

**Parameters:**
- `tag`: The ISO7816 NFC tag

**Returns:** CoreNFCCardChannel instance

##### `send(_ cmd: APDUCommand) throws -> APDUResponse`
Sends an APDU command to the card.

**Parameters:**
- `cmd`: The APDU command to send

**Returns:** APDUResponse from the card

**Throws:** CoreNFCCardChannel.Error.invalidAPDU if command is invalid

---

### SatocardCommandSet

Main command interface for interacting with Satochip cards.

#### Properties
- `let cardChannel: CardChannel` - The communication channel
- `let secureChannel: SecureChannel` - The secure channel
- `let satochipParser: SatocardParser` - Response parser
- `public var cardStatus: CardStatus?` - Current card status
- `public var satodimeStatus: SatodimeStatus` - Satodime-specific status
- `public var cardType: CardType` - Type of detected card
- `public var isSecureChannelOpen: Bool` - Whether secure channel is open

#### Methods

##### `init(cardChannel: CardChannel)`
Initializes the command set with a card channel.

**Parameters:**
- `cardChannel`: The communication channel

**Returns:** SatocardCommandSet instance

##### `selectApplet(cardType: CardType) throws -> (APDUResponse, CardType)`
Selects a specific applet on the card.

**Parameters:**
- `cardType`: Type of card to select (default: .anycard)

**Returns:** Tuple of (APDUResponse, detected CardType)

**Throws:** SatocardError.wrongCardType if card type is invalid

##### `cardGetStatus(sendEncrypted: Bool) throws -> APDUResponse`
Gets the current status of the card.

**Parameters:**
- `sendEncrypted`: Whether to send encrypted (default: true)

**Returns:** APDUResponse with card status

**Throws:** Various SatocardError types

##### `cardInitiateSecureChannel() throws -> ([UInt8], [[UInt8]])`
Initiates a secure channel with the card.

**Returns:** Tuple of (card public key, list of possible authentikeys)

**Throws:** Various SatocardError types

##### `cardDisconnect()`
Disconnects from the card and resets state.

**Returns:** Void

---

## Card Communication

### SecureChannel

Manages encrypted communication with the card.

#### Properties
- `var open: Bool` - Whether the secure channel is open
- `var publicKey: [UInt8]?` - Client public key
- `var secret: [UInt8]?` - Shared secret

#### Methods

##### `init()`
Initializes a new secure channel.

**Returns:** SecureChannel instance

##### `generateClientKeypair() -> [UInt8]`
Generates a new client key pair.

**Returns:** Client public key as byte array

##### `initiateSecureChannel(cardPubKey: [UInt8])`
Initiates the secure channel with the card's public key.

**Parameters:**
- `cardPubKey`: The card's public key

**Returns:** Void

##### `encryptSecureChannel(plainApdu: APDUCommand) -> APDUCommand`
Encrypts an APDU command for secure transmission.

**Parameters:**
- `plainApdu`: The plain APDU command

**Returns:** Encrypted APDU command

##### `decryptSecureChannel(encryptedApdu: APDUResponse) throws -> APDUResponse`
Decrypts an APDU response from the card.

**Parameters:**
- `encryptedApdu`: The encrypted APDU response

**Returns:** Decrypted APDU response

**Throws:** SecureChannelError.wrongEncryptedResponseLength

##### `reset()`
Resets the secure channel state.

**Returns:** Void

---

## Cryptographic Functions

### Crypto

Singleton class providing cryptographic operations.

#### Methods

##### `aes256Enc(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8]`
Encrypts data using AES-256 in CBC mode.

**Parameters:**
- `data`: Data to encrypt
- `iv`: Initialization vector
- `key`: Encryption key

**Returns:** Encrypted data

##### `aes256Dec(data: [UInt8], iv: [UInt8], key: [UInt8]) -> [UInt8]`
Decrypts data using AES-256 in CBC mode.

**Parameters:**
- `data`: Data to decrypt
- `iv`: Initialization vector
- `key`: Decryption key

**Returns:** Decrypted data

##### `hmacSHA512(data: [UInt8], key: [UInt8]) -> [UInt8]`
Computes HMAC-SHA512 of data.

**Parameters:**
- `data`: Data to authenticate
- `key`: HMAC key

**Returns:** HMAC result

##### `hmacSHA1(data: [UInt8], key: [UInt8]) -> [UInt8]`
Computes HMAC-SHA1 of data.

**Parameters:**
- `data`: Data to authenticate
- `key`: HMAC key

**Returns:** HMAC result

##### `sha256(_ data: [UInt8]) -> [UInt8]`
Computes SHA-256 hash of data.

**Parameters:**
- `data`: Data to hash

**Returns:** SHA-256 hash

##### `sha512(_ data: [UInt8]) -> [UInt8]`
Computes SHA-512 hash of data.

**Parameters:**
- `data`: Data to hash

**Returns:** SHA-512 hash

##### `keccak256(_ data: [UInt8]) -> [UInt8]`
Computes Keccak-256 hash of data.

**Parameters:**
- `data`: Data to hash

**Returns:** Keccak-256 hash

##### `secp256k1GeneratePair() -> ([UInt8], [UInt8])`
Generates a new secp256k1 key pair.

**Returns:** Tuple of (private key, public key)

##### `secp256k1ECDH(privKey: [UInt8], pubKey: [UInt8]) -> [UInt8]`
Performs ECDH key exchange.

**Parameters:**
- `privKey`: Private key
- `pubKey`: Public key

**Returns:** Shared secret

##### `secp256k1PublicFromPrivate(_ privKey: [UInt8]) -> [UInt8]`
Derives public key from private key.

**Parameters:**
- `privKey`: Private key

**Returns:** Public key

##### `secp256k1PublicToEthereumAddress(_ pubKey: [UInt8]) -> [UInt8]`
Converts secp256k1 public key to Ethereum address.

**Parameters:**
- `pubKey`: Public key

**Returns:** Ethereum address

##### `secp256k1Sign(hash: [UInt8], privKey: [UInt8]) -> [UInt8]`
Signs a hash with a private key.

**Parameters:**
- `hash`: Hash to sign
- `privKey`: Private key

**Returns:** DER-encoded signature

##### `secp256k1Verify(sigBytes: [UInt8], msgHash: [UInt8], pubkeyBytes: [UInt8]) -> Int32`
Verifies a signature.

**Parameters:**
- `sigBytes`: Signature to verify
- `msgHash`: Message hash
- `pubkeyBytes`: Public key

**Returns:** 1 if valid, 0 if invalid

##### `random(count: Int) -> [UInt8]`
Generates random bytes.

**Parameters:**
- `count`: Number of random bytes to generate

**Returns:** Random byte array

---

## Satochip Functions

### PIN Management

##### `cardVerifyPIN(pin: [UInt8]?) throws -> APDUResponse`
Verifies a PIN with the card.

**Parameters:**
- `pin`: PIN to verify (optional, uses cached PIN if nil)

**Returns:** APDUResponse

**Throws:** CardError.wrongPIN, CardError.pinBlocked

##### `cardChangePIN(oldPin: [UInt8], newPin: [UInt8]) throws -> APDUResponse`
Changes the card PIN.

**Parameters:**
- `oldPin`: Current PIN
- `newPin`: New PIN

**Returns:** APDUResponse

**Throws:** Various SatocardError types

##### `cardUnblockPIN(puk: [UInt8]) throws -> APDUResponse`
Unblocks a PIN using PUK.

**Parameters:**
- `puk`: Personal Unblocking Key

**Returns:** APDUResponse

**Throws:** Various SatocardError types

### Card Setup

##### `cardSetup(pin_tries0: UInt8, pin0: [UInt8]) throws -> APDUResponse`
Sets up the card with default parameters.

**Parameters:**
- `pin_tries0`: Number of PIN tries allowed
- `pin0`: Initial PIN

**Returns:** APDUResponse

**Throws:** Various SatocardError types

##### `cardSetup(pinTries0: UInt8, ublkTries0: UInt8, pin0: [UInt8], ublk0: [UInt8], pinTries1: UInt8, ublkTries1: UInt8, pin1: [UInt8], ublk1: [UInt8]) throws -> APDUResponse`
Sets up the card with custom parameters.

**Parameters:**
- `pinTries0`: Number of PIN0 tries
- `ublkTries0`: Number of PUK0 tries
- `pin0`: PIN0
- `ublk0`: PUK0
- `pinTries1`: Number of PIN1 tries
- `ublkTries1`: Number of PUK1 tries
- `pin1`: PIN1
- `ublk1`: PUK1

**Returns:** APDUResponse

**Throws:** Various SatocardError types

### BIP32 Key Management

##### `cardBip32GetExtendedkey(path: String, sid: Int?, optionFlags: UInt8) throws -> ([UInt8], [UInt8])`
Gets an extended key for a BIP32 path.

**Parameters:**
- `path`: BIP32 derivation path (e.g., "m/44'/0'/0'")
- `sid`: Secret ID for Seedkeeper (optional)
- `optionFlags`: Option flags for key derivation

**Returns:** Tuple of (key bytes, chain code)

**Throws:** SatocardError.pathTooLongForBip32Derivation

##### `cardBip32GetXpub(path: String, xtype: UInt32, sid: Int?) throws -> String`
Gets an extended public key for a BIP32 path.

**Parameters:**
- `path`: BIP32 derivation path
- `xtype`: Extended public key type
- `sid`: Secret ID for Seedkeeper (optional)

**Returns:** Base58-encoded extended public key

**Throws:** Various SatocardError types

##### `cardBip32GetXprv(path: String, xtype: UInt32, sid: Int?) throws -> String`
Gets an extended private key for a BIP32 path (Seedkeeper only).

**Parameters:**
- `path`: BIP32 derivation path
- `xtype`: Extended private key type
- `sid`: Secret ID for Seedkeeper (optional)

**Returns:** Base58-encoded extended private key

**Throws:** Various SatocardError types

---

## Satodime Functions

### Status Management

##### `satodimeGetStatus() throws -> APDUResponse`
Gets the current status of the Satodime card.

**Returns:** APDUResponse with status information

**Throws:** Various SatocardError types

##### `satodimeGetKeyslotStatus(keyNbr: UInt8) throws -> APDUResponse`
Gets the status of a specific key slot.

**Parameters:**
- `keyNbr`: Key slot number

**Returns:** APDUResponse with keyslot status

**Throws:** Various SatocardError types

### Key Management

##### `satodimeGetPubkey(keyNbr: UInt8) throws -> APDUResponse`
Gets the public key for a specific key slot.

**Parameters:**
- `keyNbr`: Key slot number

**Returns:** APDUResponse with public key

**Throws:** Various SatocardError types

##### `satodimeGetPrivkey(keyNbr: UInt8) throws -> APDUResponse`
Gets the private key for a specific key slot.

**Parameters:**
- `keyNbr`: Key slot number

**Returns:** APDUResponse with private key

**Throws:** Various SatocardError types

##### `satodimeSealKey(keyNbr: UInt8, entropyUser: [UInt8]) throws -> APDUResponse`
Seals a key slot with user entropy.

**Parameters:**
- `keyNbr`: Key slot number
- `entropyUser`: User-provided entropy

**Returns:** APDUResponse

**Throws:** Various SatocardError types

##### `satodimeUnsealKey(keyNbr: UInt8) throws -> APDUResponse`
Unseals a key slot.

**Parameters:**
- `keyNbr`: Key slot number

**Returns:** APDUResponse

**Throws:** Various SatocardError types

##### `satodimeResetKey(keyNbr: UInt8) throws -> APDUResponse`
Resets a key slot to uninitialized state.

**Parameters:**
- `keyNbr`: Key slot number

**Returns:** APDUResponse

**Throws:** Various SatocardError types

### Key Slot Configuration

##### `satodimeSetKeyslotStatusPart0(keyNbr: UInt8, RFU1: UInt8, RFU2: UInt8, keyAsset: UInt8, keySlip44: UInt32, keyContract: [UInt8], keyTokenid: [UInt8]) throws -> APDUResponse`
Sets the first part of a key slot's status.

**Parameters:**
- `keyNbr`: Key slot number
- `RFU1`: Reserved for future use
- `RFU2`: Reserved for future use
- `keyAsset`: Asset type
- `keySlip44`: SLIP-44 coin type
- `keyContract`: Contract address
- `keyTokenid`: Token ID

**Returns:** APDUResponse

**Throws:** SatodimeApiError.wrongSlip44Size, SatodimeApiError.wrongContractSize

##### `satodimeSetKeyslotStatusPart1(keyNbr: UInt8, keyData: [UInt8]) throws -> APDUResponse`
Sets the second part of a key slot's status.

**Parameters:**
- `keyNbr`: Key slot number
- `keyData`: Key data

**Returns:** APDUResponse

**Throws:** SatodimeApiError.wrongDataSize

### Ownership Transfer

##### `satodimeInitiateOwnershipTransfer() throws -> APDUResponse`
Initiates ownership transfer of the Satodime card.

**Returns:** APDUResponse

**Throws:** Various SatocardError types

---

## Seedkeeper Functions

### Status Management

##### `seedkeeperGetStatus() throws -> (APDUResponse, SeedkeeperStatus)`
Gets the current status of the Seedkeeper card.

**Returns:** Tuple of (APDUResponse, SeedkeeperStatus)

**Throws:** Various SatocardError types

### Secret Generation

##### `seedkeeperGenerateMasterseed(seedSize: Int, exportRights: SeedkeeperExportRights, label: String) throws -> (APDUResponse, SeedkeeperSecretHeader)`
Generates a master seed on the Seedkeeper (deprecated for v0.2+).

**Parameters:**
- `seedSize`: Size of the seed in bytes (16-64)
- `exportRights`: Export rights for the secret
- `label`: Label for the secret

**Returns:** Tuple of (APDUResponse, SeedkeeperSecretHeader)

**Throws:** Various SatocardError types

##### `seedkeeperGenerate2faSecret(exportRights: SeedkeeperExportRights, label: String) throws -> (APDUResponse, SeedkeeperSecretHeader)`
Generates a 2FA secret on the Seedkeeper (deprecated for v0.2+).

**Parameters:**
- `exportRights`: Export rights for the secret
- `label`: Label for the secret

**Returns:** Tuple of (APDUResponse, SeedkeeperSecretHeader)

**Throws:** Various SatocardError types

##### `seedkeeperGenerateRandomSecret(stype: SeedkeeperSecretType, subtype: UInt8, size: UInt8, saveEntropy: Bool, entropy: [UInt8], exportRights: SeedkeeperExportRights, label: String) throws -> (APDUResponse, [SeedkeeperSecretHeader])`
Generates a random secret on the Seedkeeper (v0.2+).

**Parameters:**
- `stype`: Secret type
- `subtype`: Secret subtype
- `size`: Secret size in bytes
- `saveEntropy`: Whether to save the entropy
- `entropy`: Entropy for generation
- `exportRights`: Export rights for the secret
- `label`: Label for the secret

**Returns:** Tuple of (APDUResponse, array of SeedkeeperSecretHeader)

**Throws:** SeedkeeperApiError.wrongSecretSize

### Secret Management

##### `seedkeeperImportSecret(secretObject: SeedkeeperSecretObject, sidPubkey: Int?) throws -> (APDUResponse, Int, [UInt8])`
Imports a secret into the Seedkeeper.

**Parameters:**
- `secretObject`: The secret object to import
- `sidPubkey`: Public key ID for secure import (optional)

**Returns:** Tuple of (APDUResponse, secret ID, fingerprint)

**Throws:** Various SatocardError types

##### `seedkeeperExportSecret(sid: Int, sidPubkey: Int?) throws -> SeedkeeperSecretObject`
Exports a secret from the Seedkeeper.

**Parameters:**
- `sid`: Secret ID to export
- `sidPubkey`: Public key ID for secure export (optional)

**Returns:** SeedkeeperSecretObject

**Throws:** Various SatocardError types

##### `seedkeeperExportSecretToSatochip(sid: Int, sidPubkey: Int) throws -> SeedkeeperSecretObject`
Exports a secret from Seedkeeper for import to Satochip.

**Parameters:**
- `sid`: Secret ID to export
- `sidPubkey`: Satochip authentikey ID

**Returns:** Encrypted SeedkeeperSecretObject

**Throws:** Various SatocardError types

##### `seedkeeperResetSecret(sid: Int) throws -> APDUResponse`
Resets (erases) a secret from the Seedkeeper.

**Parameters:**
- `sid`: Secret ID to reset

**Returns:** APDUResponse

**Throws:** Various SatocardError types

### Secret Listing

##### `seedkeeperListSecretHeaders() throws -> [SeedkeeperSecretHeader]`
Lists all secret headers stored in the Seedkeeper.

**Returns:** Array of SeedkeeperSecretHeader

**Throws:** Various SatocardError types

### Password Derivation

##### `seedkeeperDeriveMasterPassword(salt: [UInt8], sid: Int, sidPubkey: Int?) throws -> (APDUResponse, SeedkeeperDerivedSecret)`
Derives a password from a master password using HMAC-SHA512.

**Parameters:**
- `salt`: Salt for derivation
- `sid`: Master password secret ID
- `sidPubkey`: Public key ID for encrypted export (optional)

**Returns:** Tuple of (APDUResponse, SeedkeeperDerivedSecret)

**Throws:** SatocardError.unsupportedFeature

### Logging

##### `seedkeeperPrintLogs(printAll: Bool) throws -> ([SeedkeeperLog], Int, Int)`
Retrieves logs from the Seedkeeper.

**Parameters:**
- `printAll`: Whether to print all logs or just the latest

**Returns:** Tuple of (logs array, total logs, available logs)

**Throws:** Various SatocardError types

---

## Utility Functions

### Mnemonic

##### `mnemonicString(hexString: String) throws -> String`
Converts a hex string to a BIP39 mnemonic.

**Parameters:**
- `hexString`: Hex string to convert

**Returns:** BIP39 mnemonic string

**Throws:** MnemonicError

##### `generateMnemonic(strength: Int) throws -> String`
Generates a new BIP39 mnemonic.

**Parameters:**
- `strength`: Entropy strength in bits

**Returns:** BIP39 mnemonic string

**Throws:** MnemonicError

##### `mnemonicToMasterseed(mnemonic: String, passphrase: String, mnemonicType: MnemonicType) throws -> [UInt8]`
Converts a mnemonic to a master seed.

**Parameters:**
- `mnemonic`: BIP39 mnemonic
- `passphrase`: Optional passphrase
- `mnemonicType`: Type of mnemonic (default: .bip39)

**Returns:** Master seed bytes

**Throws:** MnemonicError.mnemonicTypeNotSupported

##### `mnemonicToEntropy(bip39: String) throws -> [UInt8]`
Converts a BIP39 mnemonic to entropy.

**Parameters:**
- `bip39`: BIP39 mnemonic string

**Returns:** Entropy bytes

**Throws:** MnemonicError.wrongBip39Word, MnemonicError.wrongBip39Checksum

##### `entropyToMnemonic(entropy: [UInt8]) throws -> String`
Converts entropy to a BIP39 mnemonic.

**Parameters:**
- `entropy`: Entropy bytes

**Returns:** BIP39 mnemonic string

**Throws:** MnemonicError

---

## Error Types

### SatocardError
- `pinRequired` - PIN is required for operation
- `wrongCardType` - Wrong card type detected
- `wrongResponseLength(length: Int, expected: Int)` - Response length mismatch
- `wrongParameter(msg: String)` - Invalid parameter
- `unsupportedFeature(msg: String)` - Feature not supported
- `uninitializedCard(msg: String)` - Card not initialized
- `pathTooLongForBip32Derivation(length: Int, expected: Int)` - BIP32 path too long
- `unexpectedErrorDuringBip32Derivation(sw: Int)` - BIP32 derivation error
- `unsupportedLegacyOptionDuringBip32Derivation` - Legacy option not supported
- `wrongPubkeyLength(length: Int, expected: Int)` - Public key length mismatch
- `wrongXpubLength(length: Int, expected: Int)` - Extended public key length mismatch

### SatodimeApiError
- `wrongSlip44Size(length: Int, expected: Int)` - SLIP-44 size mismatch
- `wrongContractSize(length: Int, expected: Int)` - Contract size mismatch
- `wrongTokenidSize(length: Int, expected: Int)` - Token ID size mismatch
- `wrongDataSize(length: Int, expected: Int)` - Data size mismatch

### SeedkeeperApiError
- `wrongSecretSize(size: Int)` - Secret size out of range

### PkiError
- `emptyCertificate` - Certificate is empty
- `failedToExportPemCertificate` - Failed to export PEM certificate
- `failedToDecodeBase64Certificate` - Failed to decode Base64 certificate
- `failedToConvertPemCertificate` - Failed to convert PEM certificate

### MnemonicError
- `mnemonicTypeNotSupported` - Mnemonic type not supported
- `wrongBip39Checksum` - BIP39 checksum validation failed
- `wrongBip39Word(word: String)` - Invalid BIP39 word
- `invalidBitString` - Invalid bit string
- `failedToRecoverBIP39fromEntropy(recoverd: String, expected: String)` - BIP39 recovery failed

### CardError
- `wrongPIN(retryCounter: UInt8)` - Wrong PIN entered
- `wrongPINLegacy` - Wrong PIN (legacy)
- `pinBlocked` - PIN is blocked

### SecureChannelError
- `wrongEncryptedResponseLength(length: Int)` - Encrypted response length mismatch

---

## Data Structures

### CardStatus
Represents the current status of a Satochip card.

**Properties:**
- `setupDone: Bool` - Whether card setup is complete
- `needsSecureChannel: Bool` - Whether secure channel is required
- `pin0Tries: UInt8` - Remaining PIN0 tries
- `pin1Tries: UInt8` - Remaining PIN1 tries
- `ublk0Tries: UInt8` - Remaining PUK0 tries
- `ublk1Tries: UInt8` - Remaining PUK1 tries

### SatodimeStatus
Represents the status of a Satodime card.

**Properties:**
- `setupDone: Bool` - Whether setup is complete
- `isOwner: Bool` - Whether current user is owner
- `maxNumKeys: Int` - Maximum number of key slots
- `satodimeKeysState: [UInt8]` - State of each key slot
- `unlockCounter: UInt32` - Unlock counter
- `unlockSecret: [UInt8]` - Unlock secret

### SeedkeeperStatus
Represents the status of a Seedkeeper card.

**Properties:**
- `nbSecrets: Int` - Number of stored secrets
- `totalMemory: Int` - Total memory available
- `freeMemory: Int` - Free memory available
- `nbLogsTotal: Int` - Total number of logs
- `nbLogsAvail: Int` - Available logs
- `lastLog: [UInt8]` - Last log entry

### SeedkeeperSecretHeader
Represents the header of a secret stored in Seedkeeper.

**Properties:**
- `sid: Int` - Secret ID
- `type: SeedkeeperSecretType` - Secret type
- `subtype: UInt8` - Secret subtype
- `origin: SeedkeeperSecretOrigin` - Secret origin
- `exportRights: SeedkeeperExportRights` - Export rights
- `nbExportPlaintext: UInt8` - Number of plaintext exports
- `nbExportEncrypted: UInt8` - Number of encrypted exports
- `useCounter: UInt32` - Usage counter
- `fingerprintBytes: [UInt8]` - Secret fingerprint
- `label: String` - Secret label

### SeedkeeperSecretObject
Represents a complete secret object.

**Properties:**
- `secretBytes: [UInt8]` - Secret data
- `secretHeader: SeedkeeperSecretHeader` - Secret header
- `isEncrypted: Bool` - Whether secret is encrypted
- `secretEncryptedParams: SeedkeeperSecretEncryptedParams?` - Encryption parameters

### BIP32KeyPair
Represents a BIP32 key pair.

**Properties:**
- `privateKey: [UInt8]?` - Private key (optional)
- `chainCode: [UInt8]?` - Chain code (optional)
- `publicKey: [UInt8]` - Public key
- `isPublicOnly: Bool` - Whether only public key is available
- `isExtended: Bool` - Whether this is an extended key

### APDUCommand
Represents an APDU command to send to the card.

**Properties:**
- `cla: UInt8` - Class byte
- `ins: UInt8` - Instruction byte
- `p1: UInt8` - Parameter 1
- `p2: UInt8` - Parameter 2
- `data: [UInt8]` - Command data

### APDUResponse
Represents an APDU response from the card.

**Properties:**
- `sw1: UInt8` - Status word 1
- `sw2: UInt8` - Status word 2
- `data: [UInt8]` - Response data
- `sw: UInt16` - Combined status word

---

## Enums

### CardType
- `satochip` - Satochip hardware wallet
- `satodime` - Satodime gift card
- `seedkeeper` - Seedkeeper secret storage
- `unknown` - Unknown card type
- `nocard` - No card detected
- `anycard` - Any card type

### SeedkeeperSecretType
- `masterseed` - Master seed
- `secret2FA` - 2FA secret
- `masterPassword` - Master password
- `key` - Generic key

### SeedkeeperSecretOrigin
- `generatedOnCard` - Generated on the card
- `importedPlaintext` - Imported in plaintext
- `importedEncrypted` - Imported encrypted

### SeedkeeperExportRights
- `noExport` - No export allowed
- `exportPlaintext` - Plaintext export allowed
- `exportEncrypted` - Encrypted export allowed
- `exportBoth` - Both export types allowed

### MnemonicType
- `bip39` - BIP39 standard
- `electrum` - Electrum format

### MnemonicLanguage
- `english` - English wordlist
- `japanese` - Japanese wordlist
- `korean` - Korean wordlist
- `spanish` - Spanish wordlist
- `chinese_simplified` - Simplified Chinese wordlist
- `chinese_traditional` - Traditional Chinese wordlist
- `french` - French wordlist
- `italian` - Italian wordlist
- `czech` - Czech wordlist
- `portuguese` - Portuguese wordlist

### PkiReturnCode
- `success` - Operation successful
- `unknown` - Unknown error
- `emptyCertificate` - Certificate is empty
- `failedToExportPemCertificate` - Failed to export PEM
- `failedToParsePemCertificate` - Failed to parse PEM
- `unsupportedCardType` - Card type not supported
- `subcaNotFound` - Sub-CA not found
- `rootCaNotFound` - Root CA not found
- `FailedToVerifyDeviceCertificate` - Device certificate verification failed
- `failedToGenerateRandomness` - Failed to generate randomness
- `FailedChallengeResponse` - Challenge-response failed
