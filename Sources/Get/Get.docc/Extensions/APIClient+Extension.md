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

To send a request, use ``send(_:delegate:configure:)-2mbhr`` that accepts ``Request`` as its primary parameter. The request can be configured ``Request/query``, ``Request/headers``, ``Request/body``. 

```swift
let user: User = try await client.send(Request(path: "/user")).value
```

In the previous sample, ``Response/value`` is used to access the decoded response value. The ``Response`` struct also contains metadata associated with the response, including ``Response/response``, ``Response/statusCode``, ``Response/currentRequest``, ``Response/metrics``, and more.

The client uses `JSONDecoder` to decode the response. If the response type is `Void`, no decoding is done and `Response<Void>`. The response also contains the original response ``Response/data``, and if you need to just fetch the data, there are additional APIs for that.

```swift
// Returns the response body as a raw `Data`
let data = try await client.data(for: Request(path: "/user")).value

// Returns the response body as a raw `String`
let string: String = try await client.send(Request(path: "/user")).value
```

You can also provide a task-specific delegate and modify the underlying `URLRequest`.

```swift
let delegate: URLSessionDataDelegate = ...
_ = try await client.send(Request(path: "/user"), delegate: delegate) {
    $0.cachePolicy = .reloadIgnoringLocalCacheData
}
```

To pass data to the server, simply set it as the request ``Request/body`` which is then encoded as JSON. But if you pass `Data`, it's sent as is, and if you pass `String`, it's encoded using UTF8.

```swift
var request = Requsest(path: "/user/emails", method: .post)
request.body = ["kean@example.com"]
try await client.send(request)
```

### Uploading Data

While you can use ``send(_:delegate:configure:)-2mbhr`` to send data to the server, ``APIClient`` also provides a convenience ``upload(for:fromFile:delegate:configure:)-y3l9`` method for uploading data from a file.

```swift
let request = Request(path: "/avatar", method: .post)
try await client.upload(for: request, fromFile: fileURL)
```

### Downloading Data

If you expect the payload to be large, consider using ``download(for:delegate:configure:)`` to download it to a file.

```swift
let request = Request(path: "/image-archive")
let response = try await client.download(for: request)
let fileURL = response.location

// Or resume download using resume data
let response = try await client.download(resumeFrom: resumeData)
```

### Client Delegate

One of the ways you can customize the client is by providing a custom delegate implementing ``APIClientDelegate`` protocol. For example, you can use it to implement authentication.

```swift
final class ClientDelegate: APIClientDelegate {
    private var accessToken: String = ""

    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        request.setValue("Bearer: \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        if case .unacceptableStatusCode(let statusCode) = error as? APIError,
           statusCode == 401, attempts == 1 {
            accessToken = try await refreshAccessToken()
            return true
        }
        return false
    }
}
```

### Session Delegate

``APIClient`` provides elegant high-level APIs, but also gives you _complete_ access to the underlying `URLSession` APIs. You can, as shown earlier, change the session configuration, but it doesn't stop there. You can also provide a custom `URLSessionDelegate` and implement only the methods you need and ``APIClient`` will handle the rest.

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
    $0.sessionConfiguration.httpAdditionalHeaders = ["UserAgent": "bonjour"]
    $0.sessionDelegate = YourSessionDelegate()
}

final class SessionDelegate: URLSessionTaskDelegate {
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

> tip: The framework deliverately doesn't provide unnecessary abstractions on top of the existing native `URLSession` APIs. To learn more about customizing caching and redirect behavior, handling authentication challenges, evaluating server trust, resuming downloads, and more, see [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system). 

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
- ``download(resumeFrom:delegate:)``

### Uploads

- ``upload(for:fromFile:delegate:configure:)-y3l9``
- ``upload(for:fromFile:delegate:configure:)-2q1yx``
