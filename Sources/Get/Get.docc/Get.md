# ``Get``

A lean Swift web API client built using async/await.

## Overview

Get provides a clear and convenient API for modeling network requests using `Request<Response>` type. And its `APIClient` makes it easy to execute these requests and decode the responses.

```swift
// Create a client
let client = APIClient(baseURL: URL(string: "https://api.github.com"))

// Start sending requests
let user: User = try await client.send(.get("/user")).value
try await client.send(.post("/user/emails", body: ["kean@example.com"]))
```

The client uses `URLSession` for networking and provides complete access to all its APIs. It is designed with the "less is more" idea in mind and doesn't introduce any unnecessary abstractions on top of native APIs.

```swift
// In addition to `APIClientDelegate`, you can also override any methods
// from `URLSessionDelegate` family of APIs.
let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
    $0.sessionDelegate = ...
}

// You can also provide task-specific delegates and easily change any of
// the `URLRequest` properties before the request is sent.
let delegate: URLSessionDataDelegate = ...
let response = try await client.send(Paths.user.get, delegate: delegate) {
    $0.cachePolicy = .reloadIgnoringLocalCacheData
}
```

In addition to sending quick requests, Get also supports downloads, uploads from file, authentication, auto-retries, logging, and more.

## Sponsors 💖

[Support](https://github.com/sponsors/kean) Get on GitHub Sponsors.

## Minimum Requirements

| Get | Date       | Swift | Xcode | Platforms                                            |
|-----|------------|-------|-------|------------------------------------------------------|
| 1.0 | 07/26/2022 | 5.6   | 13.3 | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, Linux |
| 0.6 | 04/03/2022 | 5.5   | 13.2  | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, Linux |
| 0.1 | 12/22/2021 | 5.5   | 13.2  | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0        |

## License

Get is available under the MIT license. See the LICENSE file for more info.

## Topics

### Essentials

- ``APIClient``
- ``Request``
- ``Response``

### Misc

- ``APIError``
- ``APIClientDelegate``
- ``HTTPMethod``

### Articles

- <doc:define-api>
- <doc:authentication>
- <doc:caching>
- <doc:integrations>
