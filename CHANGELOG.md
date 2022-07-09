# Get 0.x

## Get 0.8.0

*Apr 26, 2022*

- Make `Request` and `Response` conditionally `Sendable` (requires Xcode 13.3)
- Deprecate `URLRequest` `cURLDescription()` extension – it was never meant to be in scope

## Get 0.7.1

*Apr 11, 2022*

- Fix trailing `?` when creating the request with empty query items - [#29](https://github.com/kean/Get/pull/29/), thanks to [Guilherme Souza](https://github.com/grsouza)

## Get 0.7.0

*Apr 9, 2022*

- Add `baseURL` client configuration option. Deprecate `host`, `port`, and `isInsercure`.

Usage:

```swift
APIClient(baseURL: URL(string: "https://api.github.com"))
```

## Get 0.6.0

*Apr 3, 2022*

- Add `URLRequest` parameter to `shouldClientRetry(_:request:withError:)` in `APIClientDelegate` - [#23](https://github.com/kean/Get/pull/23/), thanks to [Pavel Krusek](https://github.com/pkrusek)
- Add Linux support - [#20](https://github.com/kean/Get/pull/20), thanks to [Mathieu Barnachon](https://github.com/mbarnach)

## Get 0.5.0

*Jan 21, 2022*

- Make `APIClientDelegate` method throwable - [#16](https://github.com/kean/Get/pull/16), thanks to [Tomoya Hayakawa](https://github.com/simorgh3196)

## Get 0.4.0

*Jan 10, 2022*

- Add public `Request` initializer

## Get 0.3.1

*Dec 29, 2021*

- The new optional `send()` variant now also supports `String`, and `Data`.

## Get 0.3.0

*Dec 29, 2021*

- Add `send` variant that works with optional types. If the response is empty – return `nil`.

## Get 0.2.1

*Dec 24, 2021*

- Remove `value(for:)`. It's not a great convenience method if it requires the same amount of code as an regular version. 

```swift
let user: User = try await client.send(.get("/user")).value
let user: User = try await client.value(for: .get("/user"))
```

## Get 0.2

*Dec 23, 2021*

- It now supports iOS 13, macOS 10, watchOS 6, and tvOS 13
- Make `willSend` async - [#11](https://github.com/kean/APIClient/pull/11), thanks to [Lars-Jørgen Kristiansen](https://github.com/LarsJK)
- Add a more convenient way to initialize `APIClient` (same as `ImagePipeline` in [Nuke](https://github.com/kean/Nuke)):

```swift
let client = APIClient(host: "api.github.com") {
    $0.delegate = MyClientDelegate()
    $0.sessionConfiguration.httpAdditionalHeaders = ["apiKey": "easilyExtractableSecretKey"]
}
```

- You can now provide a session delegate (`URLSessionDelegate`) when instantiating a client for monitoring URLSession events – the client will continue doing its thing
- Add metrics (`URLSessionTaskMetrics`) to `Response`
- Add public `Response` initializer and make properties writable

## APIClient 0.0.6

*Dec 13, 2021* 

- Method `send` now supports fetching `Response<Data>` (returns raw data) and `Response<String>` (returns plain text)
- Query parameters are now modeled as an array of `(String, String?)` tuples enabling "explode" support
- You can now pass `headers` in the request
- Body in `post`, `put`, and `patch` can now be empty
- All methods now support query parameters
- Add `body` parameter to `delete` method
- Make `body` parameter optional

## APIClient 0.0.5

*Dec 10, 2021*

- Make `Configuration` init public - [#10](https://github.com/kean/APIClient/pull/10), thanks to [Theis Egeberg](https://github.com/theisegeberg)
- All `send` methods now return a new `Response<T>` struct containing not just the response value, but also data, request, response, and status code.
- Add `value(for:)` method that returns `T` – a replacement for the old `send` method
- Add `data(for:)` method returning `Response<Data>`
- Add `options`, `head`, and `trace` HTTP methods
- Method `delete` to use `query` instead of `body`

## APIClient 0.0.4

*Dec 8, 2021*

- Add an option to customize the client's port and scheme - [#7](https://github.com/kean/APIClient/pull/7), thanks to [Mathieu Barnachon
](https://github.com/mbarnach)
- Make values in query parameters optional - [#8](https://github.com/kean/APIClient/pull/8), thanks to [Bernhard Loibl](https://github.com/fonkadelic)
- Update example JSON models to match the GitHub API spec - [#5](https://github.com/kean/APIClient/pull/5), thanks to [Arthur Semenyutin](https://github.com/vox-humana)
- Use `iso8601` date decoding and encoding strategies by default and add a way to customize the decoder and encoder
- Add `id` to requests
- Make `Request` properties public

## APIClient 0.0.3

*Nov 28, 2021*

- Make it available on more platforms 

## APIClient 0.0.1

*Nov 23, 2021*

- Initial release 
