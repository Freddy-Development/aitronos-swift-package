# Aitronos Swift Package

A Swift package for integrating Aitronos functionality into your iOS and macOS applications.

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 6.0+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/aitronos-swift-package.git", from: "1.0.0")
]
```

Or in Xcode:
1. File > Add Packages...
2. Enter the repository URL: `https://github.com/yourusername/aitronos-swift-package.git`
3. Select the version you want to use

## Features

The package provides several key components:

### StreamApiClient

The `StreamApiClient` class handles real-time data streaming operations.

### App-Hive Integration

The App-Hive module provides functionality for:
- Managing application state
- Handling data synchronization
- Processing real-time updates

### Freddy API

The Freddy API module offers:
- API client implementation
- Data models
- Network request handling

## Usage

### Basic Setup

```swift
import aitronos

// Initialize the client
let client = StreamApiClient()

// Configure your API settings
client.configure(apiKey: "your-api-key")
```

### Working with the Stream API

```swift
// Start a stream
client.startStream { result in
    switch result {
    case .success(let data):
        // Handle streaming data
        print("Received data: \(data)")
    case .failure(let error):
        // Handle any errors
        print("Error: \(error)")
    }
}
```

### Using App-Hive

```swift
// Initialize App-Hive components
let appHive = AppHive()

// Set up data synchronization
appHive.setupSync { result in
    // Handle sync completion
}
```

### Freddy API Integration

```swift
// Use Freddy API client
let freddyClient = FreddyApiClient()

// Make API requests
freddyClient.makeRequest { response in
    // Handle API response
}
```

## Best Practices

1. Always handle errors appropriately
2. Implement proper authentication
3. Follow the recommended initialization sequence
4. Use appropriate error handling and logging
5. Implement proper cleanup when shutting down streams

## Error Handling

The package uses Swift's native error handling system. Common errors include:

```swift
enum AitronosError: Error {
    case connectionFailed
    case invalidAuthentication
    case streamError
    // ... other error cases
}
```

## Thread Safety

The package is designed to be thread-safe. However, ensure you're making API calls from the appropriate threads:
- Network operations are performed asynchronously
- UI updates should be performed on the main thread
- Heavy processing is done on background threads

## Advanced Configuration

For advanced use cases, you can customize the behavior:

```swift
let config = AitronosConfig(
    timeout: 30,
    retryCount: 3,
    logLevel: .debug
)

client.configure(with: config)
```

## Logging

The package includes comprehensive logging capabilities:

```swift
// Enable detailed logging
AitronosLogger.setLevel(.debug)

// Custom log handlers
AitronosLogger.setHandler { level, message in
    // Handle log messages
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This package is released under the MIT License. See [LICENSE](LICENSE) for details.

## Support

For support, please:
1. Check the documentation
2. Search for existing issues
3. Create a new issue if needed

## Version History

- 1.0.0
  - Initial release
  - Basic streaming functionality
  - App-Hive integration
  - Freddy API support 