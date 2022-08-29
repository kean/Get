<br>
<img src="https://user-images.githubusercontent.com/1567433/147299567-234fc104-b5ee-40b0-aa75-98f7256f1389.png" width="100px">


# Get

[![Platform](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-4E4E4E.svg?colorA=28a745)](#installation)

A lean Swift web API client built using async/await.

Get provides a clear and convenient API for modeling network requests using `Request<Response>` type. And its `APIClient` makes it easy to execute these requests and decode the responses.

```swift
// Create a client
let client = APIClient(baseURL: URL(string: "https://api.github.com"))

// Start sending requests
let user: User = try await client.send(Request(path: "/user")).value

var request = Request(path: "/user/emails", method: .post, body: ["alex@me.com"]
try await client.send(request)
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

In addition to sending quick requests, it also supports downloading data to a file, uploading from a file, authentication, auto-retries, logging, and more. It's a kind of code that you would typically write on top of `URLSession` if you were using it directly.

## Documentation

Learn how to use Get by going through the [documentation](https://kean-docs.github.io/get/documentation/get/) created using DocC.

To learn more about `URLSession`, see [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system).

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

With Pulse, you can inspect logs directly on your device – and it supports _all_ Apple platforms. And you can share the logs at any time and view them on a big screen using [Pulse Pro](https://kean.blog/pulse/pro).

<img width="2100" alt="pulse-preview" src="https://user-images.githubusercontent.com/1567433/177911236-541117b8-11aa-4a31-9343-733e55a5abe8.png">

### CreateAPI

With [CreateAPI](https://github.com/kean/CreateAPI), you can take your backend OpenAPI spec, and generate all of the response entities and even requests for Get `APIClient`.

```swift
generate api.github.yaml --output ./OctoKit --module "OctoKit"
```

> Check out [App Store Connect Swift SDK](https://github.com/AvdLee/appstoreconnect-swift-sdk) that uses [CreateAPI](https://github.com/kean/CreateAPI) for code generation.

### Other Extensions

Get is a lean framework with a lot of flexibility and customization points. It makes it very easy to learn and use, but you'll need to install additional modules for certain features.

- [Mocker](https://github.com/WeTransfer/Mocker) – mocking network requests for testing purposes
- [URLQueryEncoder](https://github.com/CreateAPI/URLQueryEncoder) – URL query encoder with `Codable` support
- [MultipartFormDataKit](https://github.com/Kuniwak/MultipartFormDataKit) – adds support for `multipart/form-data`
- [NaiveDate](https://github.com/CreateAPI/NaiveDate) – working with dates without timezones

## Minimum Requirements

| Get  | Date         | Swift | Xcode | Platforms                                            |
|------|--------------|-------|-------|------------------------------------------------------|
| 2.0  | Jul 26, 2022 | 5.5   | 13.3  | iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, Linux |

## License

Get is available under the MIT license. See the LICENSE file for more info.
