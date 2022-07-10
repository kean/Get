# Modelling APIs

Learn how to define an API using ``Request`` type.

## Overview

For smaller apps, using ``APIClient`` directly without creating an API definition can be acceptable. But it is generally a good idea to define the available APIs somewhere to reduce the clutter in the rest of the code and eliminate duplication.

## Creating Requests

A request is represented using a simple `Request<Response>` struct. To create a request, use one of the factory methods:

```swift
Request<User>.get("/user")

Request<Repo>.patch(
    "/repos/octokit",
    query: [("password", "123456")],
    body: Repo(access: .public),
    headers: ["Version": "v2"]
)

// Defaults to `Void` as a response
Request.post("/repos", body: Repo(name: "CreateAPI"))
```

> tip: To learn more about defining network requests, see <doc:define-api>.

You can also use an initializer to create requests:

```swift
Request(url: "/repos/octokit", query: [("password", "123456")])
```

> tip: If the request's ``Request/url`` represents a relative URL, e.g. `"/user/repos"`, then it is appended to the client's ``APIClient/Configuration-swift.struct/baseURL``. If pass an absolute URL, e.g. `"https://api.github.com/user"`, it will be used as-is.

## Modeling APIs as Operations

For APIs that don't follow REST API design, there are other simpler ways to define APIs. For example, you can simply list all of the available operations.

```swift
public enum API {
    public static func getReposForUser(named name: String) -> Request<User> {
        .get("/users/\(name)/repos")
    }
}
```

Usage:

```swift
let repos = try await client.send(API.getReposForUser(named: "kean")
```

## Modelling REST APIs

REST APIs are designed around resources. One of the ideas I had was to create a separate type to represent each of the resources and expose HTTP methods that are available on them. It works best for APIs that closely follow ([REST API design](https://docs.microsoft.com/en-us/azure/architecture/best-practices/api-design)). GitHub API is a great example of a REST API, so that's why I used it in the examples.

```swift
public enum API {}

extension API {
    public static func users(_ name: String) -> UsersResource {
        UsersResource(path: "/users/\(name)")
    }
    
    public struct UsersResource {
        /// `/users/{username}`
        public let path: String

        public var get: Request<User> { .get(path) }
    }
}

extension API.UsersResource {
    public var repos: ReposResource { ReposResource(path: path + "/repos") }
    
    public struct ReposResource {
        public let path: String

        public var get: Request<[Repo]> { .get(path) }
    }
}
```

Usage:

```swift
let repos = try await client.send(API.users("kean").repos.get)
```

This API is visually appealing, but it can be a bit tedious to write and less discoverable than simply listing all available calls.

> important: There are many [suggestions](https://github.com/Moya/Moya/blob/master/docs/Examples/Basic.md) to model APIs using enums. This usually isn't ideal because you are setting yourself for merge conflicts, and it is harder to read and modify than other approaches. When you add a new call, you should only need to make changes in one place.

> tip: With [CreateAPI](https://github.com/kean/CreateAPI), you can take your backend OpenAPI spec, and generate all of the response entities and even requests for Get ``APIClient``.
