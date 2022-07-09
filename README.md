<br>
<img src="https://user-images.githubusercontent.com/1567433/147299567-234fc104-b5ee-40b0-aa75-98f7256f1389.png" width="100px">


# Get

[![Platform](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-4E4E4E.svg?colorA=28a745)](#installation)

A modern Swift web API client built using async/await.

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com"))

// Using the client directly
let user: User = try await client.send(.get("/user")).value
try await client.send(.post("/user/emails", body: ["kean@example.com"]))

// Using an API definition generated with CreateAPI
let repos = try await client.send(Paths.users("kean").repos.get)
```

Get provides a convenient way to decode network responses using `Decodable` and to model requests using `Request` type. It uses `URLSession` for networking and provides complete access to all the `URLSession` APIs to enable advanced use-cases.

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

## Documentation

Learn how to use Get by going through the [documentation](https://kean-docs.github.io/get/documentation/get/) created using DocC.

## Sponsors 💖

[Support](https://github.com/sponsors/kean) Get on GitHub Sponsors.

## Integrations

### Pulse

You can easily add logging to your API client using [Pulse](https://github.com/kean/Pulse). It requests a single line to setup.

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
    $0.sessionDelegate = PulseCore.URLSessionProxyDelegate()
}
```

With Pulse, you can inspect logs directly on your device – and it supports _all_ Apple platforms. And you can share the logs at any time and view them on a big screen using [Pulse Pro](https://kean.blog/pulse/guides/pulse-pro).

<img width="2100" alt="pulse-preview" src="https://user-images.githubusercontent.com/1567433/177911236-541117b8-11aa-4a31-9343-733e55a5abe8.png">

### CreateAPI

With [CreateAPI](https://github.com/kean/CreateAPI), you can take your backend OpenAPI spec, and generate all of the response entities and even requests for Get `APIClient`.

```swift
generate api.github.yaml --output ./OctoKit --module "OctoKit"
```

> Check out [App Store Connect Swift SDK](https://github.com/AvdLee/appstoreconnect-swift-sdk) that starting with v2.0 uses [CreateAPI](https://github.com/kean/CreateAPI) for code generation.

## Minimum Requirements

| Get  | Date         | Swift | Xcode | Platforms                                            |
|------|--------------|-------|-------|------------------------------------------------------|
| 1.0 | [RC1](https://github.com/kean/get/releases/tag/1.0.0-rc.1) | 5.6   | 13.3 | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, Linux |
| 0.6  | Apr 03, 2022 | 5.5   | 13.2  | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, Linux |

## License

Get is available under the MIT license. See the LICENSE file for more info.
