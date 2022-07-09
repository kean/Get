# Authorization

Learn how to implement user authorization.

## Overview

Every authorization system has its quirks. If you use [OAuth 2.0](https://oauth.net/2/) or a similar protocol, you need to send an access token with every request. One of the common ways is by setting an [`"Authorization"`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization) header. ``APIClient`` provides all the necessary hooks to add any authorization mechanism that you need.

### Settings Authorization Headers

While you can provide authorization headers in individual requests, a common approach is to set them in a centralized place. The ``APIClientDelegate/client(_:willSendRequest:)-8orzl`` delegate method is a good place to do it.

```swift
final class YourAPIClientDelegate: APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) {
        request.setValue("Bearer: \(accessToken)", forHTTPHeaderField: "Authorization")
    }
}
```

> important: If you look at native [`setValue(_:forHTTPHeaderField:)`](https://developer.apple.com/documentation/foundation/urlrequest/2011447-setvalue) documentation, you'll see a list of [Reserved HTTP Headers](https://developer.apple.com/documentation/foundation/nsurlrequest#1776617) that you shouldn't set manually. `"Authorization"` is one of them and relies on `URLSession` built-in authorization mechanism. Unfortunately, it doesn't support OAuth 2.0. Setting an `"Authorization"` header manually is still [the least worst](https://developer.apple.com/forums/thread/89811) option.

> tip: The ``APIClientDelegate/client(_:willSendRequest:)-8orzl`` method is also a good way to provide default headers, like ["User-Agent"](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent). But you can also provide fields that don't change using [`httpAdditionalHeaders`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411532-httpadditionalheaders) property of [`URLSessionConfiguration`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration).

### Refreshing Tokens

If your access tokens are short-lived, it is important to implement a proper refresh flow. ``APIClientDelegate`` provides a method for that too: ``APIClientDelegate/shouldClientRetry(_:for:withError:)-550vh``.

```swift
final class YourAPIClientDelegate: APIClientDelegate {
    func shouldClientRetry(_ client: APIClient, withError error: Error) async -> Bool {
        if case .unacceptableStatusCode(let status) = (error as? YourError), status == 401 {
            return await refreshAccessToken()
        }
        return false
    }
    
    private func refreshAccessToken() async -> Bool {
        // TODO: Refresh access token
    }
}
```

> important: The client might call ``APIClientDelegate/shouldClientRetry(_:for:withError:)-550vh``  multiple times (once for each failed request). Make sure to coalesce the requests to refresh the token and handle the scenario with an expired refresh token.

> tip: If you are thinking about using auto-retries for connectivity issues, consider using [`waitsForConnectivity`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/2908812-waitsforconnectivity) instead. If the request does fail with a network issue, it's usually best to communicate an error to the user. With [`NWPathMonitor`](https://developer.apple.com/documentation/network/nwpathmonitor) you can still monitor the connection to your server and retry automatically.

### Client Authorization

On top of authorizing the user, many services will also have a way of authorizing the client. If it's an API key, you can set it using the same way as an `"Authorization"` header. You may also want to [obfuscate](https://nshipster.com/secrets/) it, but keep in mind that client secrecy is impossible.

Another less common approach is [mTLS](https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/) (mutual TLS) where it's not just the server sending a certificate – the client does too. One of the advantages of using certificates is that the secret (private key) never leaves the device.

`URLSession` supports mTLS natively and it's easy to implement, even when using the new `async/await` API (thanks, Apple!).

```swift
final class YourTaskDelegate: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge)
        async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // You'll probably need to create it somewhere else.
            let credential = URLCredential(identity: ..., certificates: ..., persistence: ...)
            return (.useCredential, credential)
        } else {
            return (.performDefaultHandling, nil)
        }
    }
}
```

The main challenge with mTLS is getting the private key to the client. You can embed an obfuscated `.p12` file in the app, making it hard to discover, but it's still not impenetrable.