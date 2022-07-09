# ``Get``

A modern Swift web API client built using async/await.

## Overview

A modern Swift web API client built using async/await.

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com"))

// Using the client directly
let user: User = try await client.send(.get("/user")).value
try await client.send(.post("/user/emails", body: ["kean@example.com"]))

// Using an API definition generated with CreateAPI
let repos = try await client.send(Paths.users("kean").repos.get)
```

Get provides a convenient way to decode network responses using `Decodable` and to model requests using `Request` type. It uses `URLSession` for networking and provides complete access to all of `URLSession` APIs to enable advanced use-cases.

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

## Sponsors 💖

[Support](https://github.com/sponsors/kean) Get on GitHub Sponsors.

## Minimum Requirements

| Get | Date       | Swift | Xcode | Platforms                                            |
|-----|------------|-------|-------|------------------------------------------------------|
| 11.0 | [RC1](https://github.com/kean/get/releases/tag/1.0.0-rc.1) | 5.6   | 13.3 | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, Linux |
| 0.6 | 04/03/2022 | 5.5   | 13.2  | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, Linux |
| 0.1 | 12/22/2021 | 5.5   | 13.2  | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0        |

## License

Get is available under the MIT license. See the LICENSE file for more info.

## Topics

### Essentials

- ``APIClient``
- ``APIClientDelegate``
- ``APIError``

### Requests and Responses

- ``Request``
- ``Response``

### Articles

- <doc:define-api>
- <doc:authentication>
- <doc:caching>
- <doc:integrations>
