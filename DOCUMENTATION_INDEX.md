# SatochipSwift Documentation Index

This directory contains comprehensive documentation for the SatochipSwift library, a Swift SDK for integrating with Satochip, Satodime, and Seedkeeper hardware cards.

## Documentation Files

### 📋 [OVERVIEW.md](./OVERVIEW.md)
**Project Overview and Use Cases**
- High-level description of the SatochipSwift SDK
- Supported hardware cards (Satochip, Satodime, Seedkeeper)
- Core functionality and security features
- Potential applications and integration scenarios
- Key advantages and technical architecture

### 📚 [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
**Complete API Reference**
- Detailed documentation of all classes, methods, and functions
- Input parameters and return values for every function
- Error types and their meanings
- Data structures and enums
- Cryptographic function specifications

### 💡 [USAGE_EXAMPLES.md](./USAGE_EXAMPLES.md)
**Practical Examples and Integration Guide**
- Step-by-step setup instructions
- Real-world code examples for all three card types
- Error handling patterns and best practices
- Integration patterns for different use cases
- Security considerations and recommendations

## Quick Start

1. **Read the Overview**: Start with [OVERVIEW.md](./OVERVIEW.md) to understand what the library does and how it can be used.

2. **Check the API**: Use [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) as a reference when implementing specific functionality.

3. **Follow Examples**: Use [USAGE_EXAMPLES.md](./USAGE_EXAMPLES.md) to see practical implementations and copy working code patterns.

## Library Components

### Core Classes
- **SatocardController**: NFC communication management
- **SatocardCommandSet**: High-level command interface
- **CoreNFCCardChannel**: Low-level NFC communication
- **SecureChannel**: Encrypted communication protocol

### Card Types
- **Satochip**: Hardware wallet for cryptocurrency operations
- **Satodime**: Cryptocurrency gift card system
- **Seedkeeper**: Secure secret storage device

### Key Features
- **NFC Communication**: ISO14443 protocol support
- **Cryptographic Operations**: secp256k1, AES-256, HMAC, PBKDF2
- **BIP32/BIP39 Support**: Hierarchical deterministic key derivation
- **Secure Channels**: ECDH key exchange with AES encryption
- **PIN Authentication**: Multi-level PIN protection
- **PKI Support**: Certificate-based device verification

## Dependencies

The library requires the following dependencies:
- **SwiftTLS**: X.509 certificate handling
- **secp256k1.swift**: Elliptic curve cryptography
- **CryptoSwift**: Cryptographic operations
- **Zip**: Data compression
- **MnemonicSwift**: BIP39 mnemonic handling
- **BigInt**: Large integer arithmetic

## Platform Requirements

- **iOS 13.0+**: Core NFC support required
- **Swift 5.7+**: Modern Swift language features
- **Xcode**: Latest stable version recommended
- **NFC-enabled Device**: Physical device required (not simulator)

## Security Considerations

- All private keys remain on the secure hardware
- Communication is encrypted using industry-standard protocols
- PIN authentication prevents unauthorized access
- Certificate-based verification ensures device authenticity
- Comprehensive audit logging for security monitoring

## Getting Help

### Common Issues
1. **NFC Not Available**: Ensure device supports NFC and it's enabled
2. **Card Not Detected**: Check card placement and try restarting the session
3. **PIN Errors**: Verify PIN format and check retry counter
4. **Secure Channel Issues**: Ensure proper authentication before encrypted operations

### Error Handling
All functions include comprehensive error handling with specific error types. Refer to the API documentation for detailed error descriptions and handling strategies.

### Best Practices
- Always check NFC availability before starting sessions
- Handle background/foreground transitions properly
- Implement proper PIN entry with secure text fields
- Use retry logic for transient failures
- Log operations for debugging and audit purposes

## Contributing

When contributing to the documentation:
1. Keep examples up-to-date with the latest API
2. Include error handling in all examples
3. Follow Swift naming conventions
4. Add comments explaining complex operations
5. Test all code examples before committing

## Version History

- **v0.2.0**: Added Seedkeeper support
- **v0.1.0**: Initial version with Satochip and Satodime support

## License

This documentation is provided under the same license as the SatochipSwift library.

---

*For the most up-to-date information, always refer to the source code and the latest version of this documentation.*
