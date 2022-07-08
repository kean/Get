# Defining APIs

Learn how to define an API using ``Request`` type.

## Overview

For smaller apps, using ``APIClient`` directly without creating an API definition can be acceptable. But it's generally a good idea to define the available APIs somewhere to reduce the clutter in the rest of the code and remove possible duplication.

### Modelling REST APIs

REST APIs are designed around resources. One of the ideas I had was to create a separate type to represent each of the resources and expose HTTP methods that are available on them. It works best for APIs that closely follow ([REST API design](https://docs.microsoft.com/en-us/azure/architecture/best-practices/api-design)). GitHub API is a great example of a REST API, so that's why I used it in the examples.

```swift
public enum Resources {}

// MARK: - /users/{username}

extension Resources {
    public static func users(_ name: String) -> UsersResource {
        UsersResource(path: "/users/\(name)")
    }
    
    public struct UsersResource {
        public let path: String

        public var get: Request<User> { .get(path) }
    }
}

// MARK: - /users/{username}/repos

extension Resources.UsersResource {
    public var repos: ReposResource { ReposResource(path: path + "/repos") }
    
    public struct ReposResource {
        public let path: String

        public var get: Request<[Repo]> { .get(path) }
    }
}
```

Usage:

```swift
let repos = try await client.send(Resources.users("kean").repos.get)
```

This API is visually appealing, but it can be a bit tedious to write and less discoverable than simply listing all available calls. If you feel like a simple list of operations is a better option for your API, all the power to you.

> important: There are [suggestions](https://github.com/Moya/Moya/blob/master/docs/Examples/Basic.md) to model APIs as an enum where each property has a separate switch. This isn't ideal because you are setting yourself for merge conflicts, and it's harder to read and modify than other approaches. When you add a new call, you should ideally only need to make a change in one place.
