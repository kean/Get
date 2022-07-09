# Integrations

Learn how to extend ``APIClient`` using third-party frameworks.

### Pulse

You can easily add logging to your API client using [Pulse](https://github.com/kean/Pulse). It's a one-line setup.

```swift
let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
    $0.sessionDelegate = PulseCore.URLSessionProxyDelegate()

    // If you also have a session delegate, add it to the delegate chain
    $0.sessionDelegate = PulseCore.URLSessionProxyDelegate(delegate: yourDelegate)
}
```

With Pulse, you can inspect logs directly on your device – and it supports _all_ Apple platforms. And you can share the logs at any time and view them on a big screen using [Pulse Pro](https://kean.blog/pulse/guides/pulse-pro).

![Pulse Preview](pulse-preview.png)

### CreateAPI

With [CreateAPI](https://github.com/kean/CreateAPI), you can take your backend OpenAPI spec, and generate all of the response entities and even requests for Get ``APIClient``.

```swift
generate api.github.yaml --output ./OctoKit --module "OctoKit"
```

> Check out [App Store Connect Swift SDK](https://github.com/AvdLee/appstoreconnect-swift-sdk) that starting with v2.0 uses [CreateAPI](https://github.com/kean/CreateAPI) for code generation.
