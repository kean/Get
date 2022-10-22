# Authentication

Learn how to implement authentication.

## Access Tokens

Every authorization system has its quirks. If you use [OAuth 2.0](https://oauth.net/2/) or a similar protocol, you need to send an access token with every request. One of the common ways is by setting an [`"Authorization"`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization) header. ``APIClient`` provides all the necessary hooks to add any authorization mechanism that you need.

### Settings Authorization Headers

While you can provide authorization headers in individual requests, a common approach is to set them in a centralized place. The ``APIClientDelegate/client(_:willSendRequest:)-8orzl`` delegate method is a good place to do it.

```swift
final class ClientDelegate: APIClientDelegate {
    private var accessToken: String = ""

    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
}
```

> important: If you look at native [`setValue(_:forHTTPHeaderField:)`](https://developer.apple.com/documentation/foundation/urlrequest/2011447-setvalue) documentation, you'll see a list of [Reserved HTTP Headers](https://developer.apple.com/documentation/foundation/nsurlrequest#1776617) that you shouldn't set manually. `"Authorization"` is one of them and relies on `URLSession` built-in authorization mechanism. Unfortunately, it doesn't support OAuth 2.0. Setting an `"Authorization"` header manually is still [the least worst](https://developer.apple.com/forums/thread/89811) option.

> tip: The ``APIClientDelegate/client(_:willSendRequest:)-8orzl`` method is also a good way to provide default headers, like ["User-Agent"](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent). But you can also provide fields that don't change using [`httpAdditionalHeaders`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411532-httpadditionalheaders) property of [`URLSessionConfiguration`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration).

### Refreshing Tokens

If your access tokens are short-lived, it is important to implement a proper refresh flow. ``APIClientDelegate`` provides a method for that too: ``APIClientDelegate/clshoul`.

```swift
final class ClientDelegate: APIClientDelegate {
    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        if case .unacceptableStatusCode(let statusCode) = error as? APIError,
           statusCode == 401, attempts == 1 {
            accessToken = try await refreshAccessToken()
            return true
        }
        return false
    }

    private func refreshAccessToken() async throws -> String {
        fatalError("Not implemented")
    }
}
```

> important: The client might call ``APIClientDelegate/client(_:shouldRetry:error:attempts:)-6tv21``  multiple times (once for each failed request). Make sure to coalesce the requests to refresh the token and handle the scenario with an expired refresh token.

> tip: If you are thinking about using auto-retries for connectivity issues, consider using [`waitsForConnectivity`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/2908812-waitsforconnectivity) instead. If the request does fail with a network issue, it is usually best to communicate an error to the user. With [`NWPathMonitor`](https://developer.apple.com/documentation/network/nwpathmonitor) you can still monitor the connection to your server and retry automatically.

## Server Trust

On top of authorizing the user, many services will also have a way of authorizing the client - your app. If it is an API key, you can set it using the same way as an `"Authorization"` header.

To learn more about Server Trust, see [Performing Manual Server Trust Authentication](https://developer.apple.com/documentation/foundation/url_loading_system/handling_an_authentication_challenge/performing_manual_server_trust_authentication).
