# ``Get/APIClient``

### Creating a Client

You start by instantiating a client:

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com")) 
```

You can customize the client using `APIClient.Configuration` (see it for a complete list of available options). You can also use a convenience initializer to configure it inline:

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
    $0.sessionConfiguration.httpAdditionalHeaders = ["UserAgent": "bonjour"]
    $0.delegate = YourDelegate()
}
```

### Sending Requests

To send a request, use a client instantiated earlier:

```swift
let user: User = try await client.send(.get("/user")).value

try await client.send(.post("/repos", body: Repo(name: "CreateAPI"))
```

The ``send(_:delegate:configure:)-2ls6m`` method returns not just the response value, but all of the metadata associated with the request packed in a ``Response`` struct. And o learn more about creating requests, see ``Request``.

The response can be any `Decodable` type. The response can also be optional. And if the response type is `Data`, the client simply returns raw response data. If it's a `String`, it returns the response as plain text.

> tip: By default, the request ``Request/path`` is appended to the client's ``APIClient/Configuration/baseURL``. However, if you pass a complete URL, e.g. `"https://api.github.com/user"`, it will be used instead. 

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
- ``Configuration``

### Sending Requests

- ``send(_:delegate:configure:)-2ls6m``
- ``send(_:delegate:configure:)-2uc3f``
- ``send(_:delegate:configure:)-3vh73``

### Loading Data

- ``data(for:delegate:configure:)-83pkq``
- ``data(for:delegate:configure:)-t8pp``

### Downloads

- ``download(for:delegate:configure:)-68huc``
- ``download(for:delegate:configure:)-3q3o4``
