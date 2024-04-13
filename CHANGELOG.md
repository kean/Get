# Get 2.x

## Get 2.2.0

*Apr 13, 2024*

- Increase the minimum supported Xcode version to 15.0 
- Fix warnings in unit tests

## Get 2.1.6

*Dec 25, 2022*

- Fix downloads folder, by [@LePips](https://github.com/LePips) – [#72](https://github.com/kean/Get/pull/72) 

## Get 2.1.5

*Nov 2, 2022*

- Fix warnings in Xcode 14.1
- Move docc files back to the Sources/ 

## Get 2.1.4

*Oct 22, 2022*

- Fix xcodebuild & docc issue in Xcode 14.0

## Get 2.1.3

*Oct 8, 2022*

- Fix [#53](https://github.com/kean/Get/issues/53), a concurrency warning with strict concurrency checking  

## Get 2.1.2

*Sep 21, 2022*

- Fix an issue with `withResponse` always setting method to `.get` - [#62](https://github.com/kean/Get/pull/62), thanks to @briancordanyoung

## Get 2.1.1

*Sep 20, 2022*

- Fix concurrency issue in `DataLoader` with the new iOS 16 `didCreateTask` delegate method

## Get 2.1.0

*Sep 17, 2022*

- Add support for optional responses. If the response is optional and the response body is empty, the request will now succeed and return `nil` - [#58](https://github.com/kean/Get/pull/58), thanks to [@Pomanks](https://github.com/Pomanks)

## Get 2.0.1

*Sep 13, 2022*

- Add support for Xcode 14 (fix build issue on macOS)

## Get 2.0.0

*Aug 26, 2022*

This release is a quick follow-up to Get 1.0 that fixes some of the shortcomings of the original design of the `Request` type.

- `Request` can now be initialized with either a string (`path: String`) or a URL (`url: URL`)
- Replace separate `.get(...)`, `.post(...)`, and other factory methods with a single `HTTPMethod` type. Example: `Request(path: "/user", method: .patch)`
- The first parameter in the `Request` initializer is now `path` or `url`, not `method` that has a default value
- Add a new `Request` initializer that defaults to the `Void` response type unless you specify it explicitly
- Make `body` property of `Request` writable
- Add `upload(for:data:)` method - [#50](https://github.com/kean/Get/pull/50), thanks to @soemarko 
- Replace `APIDelegate` `client(_:makeURLFor:query:)` method with `client(_:makeURLForRequest:)` so that you have complete access to the `Request`
- Remove APIs deprecated in Get 1.0

> See [#51](https://github.com/kean/Get/pull/51) for the reasoning behind the `Request` changes


# Get 1.x

## Get 1.0.4

*Sep 20, 2022*

- Fix concurrency issue in `DataLoader` with the new iOS 16 `didCreateTask` delegate method

## Get 1.0.3

*Sep 13, 2022*

- Add Xcode 14 support

## Get 1.0.2

*Aug 3, 2022* 

- Revert back to supporting Swift 5.5 by @liamnichols in #47

## Get 1.0.1

*Jul 26, 2022*

- Add `@discardableResult` to all `upload()` and `send()` methods

## Get 1.0.0

*Jul 26, 2022*

Get 1.0 is a big release that brings it on par with Moya+Alamofire while still keeping its API surface small and focused. This release also includes new reworked [documentation](https://kean-docs.github.io/get/documentation/get/) generated using DocC, and many other improvements.

The first major change is the addition of two new parameters the existing `send` method: `delegate` and `configure`:

```swift
public func send<T: Decodable>(
    _ request: Request<T>,
    delegate: URLSessionDataDelegate? = nil,
    configure: ((inout URLRequest) -> Void)? = nil
) async throws -> Response<T>
```

With `delegate`, you can modify the behavior of the underlying task, monitor the progress, etc. And with the new `configure` closure, you get access to the entire `URLRequest` API:

```swift
let user = try await client.send(.get("/user")) {
    $0.cachePolicy = .reloadIgnoringLocalCacheData
}
```

The second major change is the addition of new methods: `upload(...)` for uploading data from a file and `download(...)` for downloading data to a file.

```swift
let response = try await client.download(for: .get("/user"))
let fileURL = response.location

try await client.upload(for: .post("/avatar"), fromFile: fileURL)
```

pulse-2.0
## Changes

- Add a `delegate` parameter to `send()` method that sets task-specific `URLSessionDataDelegate` - [#38](https://github.com/kean/Get/pull/38)
- Add `configure` parameter to `send()` method that allows configuring `URLRequest` before it is sent
- Add support for downloading to a file with a new `download(for:delegate:configure:)` method - [#40](https://github.com/kean/Get/pull/40)
- Add support for uploading data from a file with a new `upload(for:withFile:delegate:configure:)` method
- Add an option to do more than one retry attempt using the reworked `client(_:shouldRetryRequest:attempts:error:)` delegate method (the method with an old signature is deprecated)
- Add `client(_:validateResponse:data:request:)` to `APIClientDelegate` that allows to customize validation logic
- Add `client(_:makeURLForRequest:)` method to `APIClientDelegate` to address [#35](https://github.com/kean/Get/issues/35)
- Add `task`, `originalRequest`, `currentRequest` to `Response`
- Add `APIClient/makeURLRequest(for:)` method to the client in case you need to create `URLRequest` without initiating the download
- Add a way to override `Content-Type` and `Accept` headers using session `httpAdditionalHeaders` and `Request` headers
- Add new `Request` factory methods that default to `Void` as a response type and streamline the existing methods
- Add `withResponse(_:)` to allow changing request's response type
- Add `sessionDelegateQueue` parameter to `APIClient.Configuration`
- Add support for `sessionDelegate` from `APIClient.Configuration`  on Linux
- Add public `configuration` and `session` properties to `APIClient`
- Rename `Request/path` to `Request/url` making it clear that absolute URLs are also supported
- Improve decoding/encoding performance by using `Task.detached` instead of using a separate actor for serialization
- Remove send() -> Response<T?> variant
- Remove APIs deprecated in previous versions

## Fixes

- Fix an issue with paths that don't start with `"/"` not being appended to the `baseURL`
- Fix an issue with empty path not working. It is now treated the same way as "/"

## Non-Code Changes

- Hide dependencies used only in test targets
- Documentation is now generated using DocC and is [hosted](https://kean-docs.github.io/get/documentation/get/) on GitHub Pages 
- Perform grammar check on CI

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

- Make `Configuration` init public - [#10](https://github.com/kean/APIClient/pull/10), thanks to [@theisegeberg](https://github.com/theisegeberg)
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
