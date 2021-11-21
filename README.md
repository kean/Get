# Web API Client

A modern web API client in Swift built using Async/Await and Actors.

```swift
let client = APIClient(host: "api.github.com")

// Using the client directly
let user: User = try await client.send(.get("/user"))
try await client.send(.post("/user/emails", body: ["kean@example.com"]))

// Using a predefined API definition
let repos = try await client.send(Resources.users("kean").repos.get)
```

For more information, read the [Web API Client in Swift](https://kean.blog/post/new-api-client).
