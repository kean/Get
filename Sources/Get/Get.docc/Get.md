# ``Get``

A modern Swift web API client built using async/await.

## Overview

Get provides a convenient and clear API for performing network requests.

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com"))

// Using the client directly
let user: User = try await client.send(.get("/user")).value
try await client.send(.post("/user/emails", body: ["kean@example.com"]))

// Using an API definition generated with CreateAPI
let repos = try await client.send(Paths.users("kean").repos.get)
```

## Sponsors 💖

[Support](https://github.com/sponsors/kean) Get on GitHub Sponsors.

## Minimum Requirements

| Get | Date       | Swift | Xcode | Platforms                                            |
|-----|------------|-------|-------|------------------------------------------------------|
| 0.6 | 04/03/2022 | 5.5   | 13.2  | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, Linux |
| 0.1 | 12/22/2021 | 5.5   | 13.2  | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0        |

## License

Get is available under the MIT license. See the LICENSE file for more info.

## Topics

### API Client

- ``APIClient``
- ``APIClientDelegate``
- ``APIError``

### Sending Requests

- ``Request``
- ``Response``

### Articles

- <doc:authorization>
- <doc:integrations>
- <doc:caching>
