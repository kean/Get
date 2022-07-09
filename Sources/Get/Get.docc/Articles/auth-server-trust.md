# Server Trust

Learn how to use handle authentication challenges to establish server trust using mTLS.

## Overview

On top of authorizing the user, many services will also have a way of authorizing the client - your app. If it's an API key, you can set it using the same way as an `"Authorization"` header. You may also want to [obfuscate](https://nshipster.com/secrets/) it, but keep in mind that client secrecy is impossible.

## Using mTLS

Another less common approach is [mTLS](https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/) (mutual TLS) where it's not just the server sending a certificate – the client does too. One of the advantages of using certificates is that the secret (private key) never leaves the device.

`URLSession` supports mTLS natively and it's easy to implement, even when using the new `async/await` API (thanks, Apple!).

```swift
final class YourTaskDelegate: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge)
        async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let credential = URLCredential(identity: ..., certificates: ..., persistence: ...)
            return (.useCredential, credential)
        } else {
            return (.performDefaultHandling, nil)
        }
    }
}
```

The main challenge with mTLS is getting the private key to the client. You can embed an obfuscated `.p12` file in the app, making it hard to discover, but it's still not impenetrable.
