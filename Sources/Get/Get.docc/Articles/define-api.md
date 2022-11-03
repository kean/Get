# Modeling APIs

Learn how to define an API using ``Request`` type.

## Overview

For smaller apps or one-off requests, using ``APIClient`` directly without creating an API definition can be acceptable. For example:

```swift
let request = Request(path: "/user/emails", method: .post, body: ["kean@example.com"])
try await client.send(request)
```

But it is generally a good idea to define all the available APIs in one place to reduce the clutter in the rest of the codebase and eliminate duplication. The ``Request`` struct is perfectly suited for this. It defines the relative or the absolute URL, the request parameters, and, importantly, the expected response type.

> important: There are many suggestions online to model APIs using enums. This approach might make your code harder to read and modify and lead to merge conflicts. When you add a new call, you should only need to make changes in one place.

## Modeling REST APIs

REST APIs are [designed](https://docs.microsoft.com/en-us/azure/architecture/best-practices/api-design) around resources. Naturally, you can use nested types to represent nested resources to create a structure that mimics that of the API.

```swift
enum API {}

extension API {
    static func users(_ name: String) -> UsersResource {
        UsersResource(path: "/users/\(name)")
    }

    struct UsersResource {
        /// `/users/{username}`
        let path: String

        /// Get the profile of the selected user.
        var get: Request<User> { .init(path: path) }
    
        /// Access the repos belonging to the user.
        var repos: ReposResource { ReposResource(path: path + "/repos") }
    }
}

extension API.UsersResource {
    struct ReposResource {
        /// `/users/{username}/repos`
        let path: String

        /// Get the list of the repos belonging to the user.
        var get: Request<[Repo]> { .init(path: path) }
    }
}

struct Repo: Decodable {}
```

Usage:

```swift
let response = try await client.send(API.users("kean").repos.get)
```

> tip: This API is visually appealing, but it can be a bit tedious to write. With [CreateAPI](https://github.com/kean/CreateAPI), you can take your backend OpenAPI spec, and generate all of the response entities and even requests for ``APIClient``.

## Modeling APIs as Operations

For APIs that don't follow REST API design, there are other ways to define APIs. For example, you can simply list all of the available operations.

```swift
enum API {
    static func getReposForUser(named name: String) -> Request<User> {
        .init(path: "/users/\(name)/repos")
    }
}

struct User: Decodable {}
```

Usage:

```swift
let repos = try await client.send(API.getReposForUser(named: "kean")
```
