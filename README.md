<br>
<img src="https://user-images.githubusercontent.com/1567433/147299567-234fc104-b5ee-40b0-aa75-98f7256f1389.png" width="100px">


# Get

A modern Swift web API client built using async/await.

```swift
let client = APIClient(host: "api.github.com")

// Using the client directly
let user: User = try await client.send(.get("/user"))
try await client.send(.post("/user/emails", body: ["kean@example.com"]))

// Using a predefined API definition
let repos = try await client.send(Paths.users("kean").repos.get)
```

For more information, read [Web API Client in Swift](https://kean.blog/post/new-api-client).

## Usage

### Intantiating a Client

You start by instantiating an APIClient:

```swift
let client = APIClient(host: "api.github.com")
```

You can customize the client using `APIClient.Configuration` (see it for a complete list of available options). You can also use a convenience initializer to set configuration inline:

```swift
let client = APIClient(host: "api.github.com") {
    $0.sessionConfiguration.httpAdditionalHeaders = ["UserAgent": "bonjour"]
    $0.delegate = YourDelegate()
}
```

### Creating Requests

A request is represented using `Request<Response>` struct. To create a request, use one of the factory methods:

```swift
let get = Request<User>.get("/user")

let post = Request<Void>.post("/repos", body: Repo(name: "CreateAPI"))

let patch = Request<Repo>.post(
    "/repos/octokit",
    query: [("password", "123456")],
    body: Repo(access: .public),
    headers: ["Version": "v2"]
)
```

### Sending Requests

You use `APIClient` to send the requests:

```swift
let user: User = try await client.value(for: .get("/user"))
```

The `value(for:)` method supports `Decodable` response types (or use `data(for:)` to fetch raw response data).

If you want to send a request modifying data, e.g. a `.post` request, use `send` method.

```swift
try await client.send(.post("/repos", body: Repo(name: "CreateAPI"))
```

The `send` method is the primary way you interact with `APIClient`. It's not just for `.post` requests. Unlike `value(for:)`, it returns not just the response value, but all of the associated request metadata:

```swift
public struct Response<T> {
    public var value: T
    public var data: Data
    public var request: URLRequest
    public var response: URLResponse
    public var statusCode: Int?
    public var metrics: URLSessionTaskMetrics?
}
```

> If the response type is `Data`, the client will return raw response data. And if you use `String`, it'll return a response as plain text.

### Client Delegate

One of the ways you can customize the client is by providing a custom delegate implementing `APIClientDelegate` protocol. For example, you can use it to implement an authorization flow.

```swift
final class AuthorizatingDelegate: APIClientDelegate {    
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async {
        request.allHTTPHeaderFields = ["Authorization": "Bearer: \(token)"]
    }
    
    func shouldClientRetry(_ client: APIClient, withError error: Error) async -> Bool {
        if case .unacceptableStatusCode(let statusCode) = (error as? APIError), statusCode == 401 {
            return await refreshAccessToken()
        }
        return false
    }
}
```

### Session Delegate

`APIClient` provides elegant high-level APIs, but also gives you _complete_ access to the underlying `URLSession` APIs. You can, as shown earlier, change the session configuration, but it doesn't stop there. You can also provide a custom `URLSessionDelegate` and implement only the methods you are interested in – `APIClient` will handle the rest.

```swift
let client = APIClient(host: "api.github.com") {
    $0.sessionConfiguration.httpAdditionalHeaders = ["UserAgent": "bonjour"]
    $0.sessionDelegate = YourTaskDelegate()
}

final class YourTaskDelegate: URLSessionTaskDelegate {
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

## Integrations

### Pulse

You can easily add logging to your API client using [Pulse](https://github.com/kean/Pulse). It's a one-line setup.

```swift
let client = APIClient(host: "api.github.com") {
    $0.sessionDelegate = PulseCore.URLSessionProxyDelegate()
}
```

With Pulse, you can inspect logs directly on your device – and it supports _all_ Apple platforms. And you can share the logs at any time and view them on a big screen using [Pulse Pro](https://kean.blog/pulse/guides/pulse-pro).

<img src="https://user-images.githubusercontent.com/1567433/107718772-ab576580-6ca4-11eb-83a1-fc510e57bab1.png">

### CreateAPI

With [CreateAPI](https://github.com/kean/CreateAPI), you can take your backend OpenAPI spec, and generate all of the response entities and even requests for Get `APIClient`.

```swift
generate api.github.yaml --output ./OctoKit --module "OctoKit"
```

> Check out [OctoKit](https://github.com/kean/OctoKit/blob/main/README.md), which is a GitHub API client generated using [CreateAPI](https://github.com/kean/CreateAPI) that uses [Get](https://github.com/kean/Get) for networking.

## Minimum Requirements

| Nuke          | Swift           | Xcode           | Platforms                                         |
|---------------|-----------------|-----------------|---------------------------------------------------|
| Get 0.1      | Swift 5.5       | Xcode 13.2      | iOS 13.0 / watchOS 6.0 / macOS 10.15 / tvOS 13.0  |

## License

Get is available under the MIT license. See the LICENSE file for more info.
