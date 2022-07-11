# ``Get/APIClient``

### Creating a Client

Start by instantiating a client:

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com")) 
```

You can customize the client using ``APIClient/Configuration-swift.struct`` or use a convenience initializer to configure it inline:

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
    $0.sessionConfiguration.httpAdditionalHeaders = ["UserAgent": "hello"]
    $0.delegate = YourDelegate()
}
```

### Sending Requests and Decoding Responses

To send a request, use a client instantiated earlier:

```swift
let user: User = try await client.send(.get("/user")).value

try await client.send(.post("/repos", body: Repo(name: "CreateAPI"))
```

The ``send(_:delegate:configure:)-3t9w0`` method returns not just the response value, but all of the metadata associated with the request packed in a ``Response`` struct. And o learn more about creating requests, see ``Request``.

The response can be any `Decodable` type. The response can also be optional. If the response is `String`, it returns raw response as a string.

You can also provide task-specific delegates and easily change any of the `URLRequest` properties before the request is sent.

```swift
let delegate: URLSessionDataDelegate = ...
let response = try await client.send(Paths.user.get, delegate: delegate) {
    $0.cachePolicy = .reloadIgnoringLocalCacheData
}
```

### Downloading and Uploading Data

To fetch the response data, use ``data(for:delegate:configure:)`` and decode data using your preferred method or use ``download(for:delegate:configure:)`` to download it to the file.

```swift
let response = try await client.download(for: .get("/user"))
let fileURL = response.location
```

``APIClient`` also provides a convenience method ``upload(for:fromFile:delegate:configure:)-y3l9`` for uploading data from a file:

```swift
try await client.upload(for: .post("/avatar"), fromFile: fileURL)
```

### Client Delegate

One of the ways you can customize the client is by providing a custom delegate implementing `APIClientDelegate` protocol. For example, you can use it to implement an authorization flow.

```swift
final class AuthorizingDelegate: APIClientDelegate {    
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        request.allHTTPHeaderFields = ["Authorization": "Bearer: \(token)"]
    }
    
    func shouldClientRetry(_ client: APIClient, withError error: Error) async throws -> Bool {
        if case .unacceptableStatusCode(let statusCode) = (error as? APIError), statusCode == 401 {
            return await refreshAccessToken()
        }
        return false
    }
}
```

### Session Delegate

``APIClient`` provides elegant high-level APIs, but also gives you _complete_ access to the underlying `URLSession` APIs. You can, as shown earlier, change the session configuration, but it doesn't stop there. You can also provide a custom `URLSessionDelegate` and implement only the methods you are interested in – ``APIClient`` will handle the rest.

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
    $0.sessionConfiguration.httpAdditionalHeaders = ["UserAgent": "bonjour"]
    $0.sessionDelegate = YourSessionDelegate()
}

final class YourSessionDelegate: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            return (.useCredential, URLCredential(...))
        } else {
            return (.performDefaultHandling, nil)
        }
    }
}
```

## Topics

### Creating a Client

- ``init(baseURL:_:)``
- ``init(configuration:)``
- ``Configuration-swift.struct``

### Instance Properties

- ``configuration-swift.property``
- ``session``

### Sending Requests

- ``send(_:delegate:configure:)-3t9w0``
- ``send(_:delegate:configure:)-2mbhr``

### Loading Data

- ``data(for:delegate:configure:)``

### Downloads

- ``download(for:delegate:configure:)``

### Uploads

- ``upload(for:fromFile:delegate:configure:)-y3l9``
- ``upload(for:fromFile:delegate:configure:)-2q1yx``
