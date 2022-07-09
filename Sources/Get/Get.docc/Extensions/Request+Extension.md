# ``Get/Request``

### Creating Requests

A request is represented using a simple `Request<Response>` struct. To create a request, use one of the factory methods:

```swift
Request<User>.get("/user")

Request<Void>.post("/repos", body: Repo(name: "CreateAPI"))

Request<Repo>.patch(
    "/repos/octokit",
    query: [("password", "123456")],
    body: Repo(access: .public),
    headers: ["Version": "v2"]
)
```

## Topics

### Initializers

- ``init(method:path:query:headers:)``
- ``init(method:path:query:body:headers:)``

### Instance Properties

- ``method``
- ``path``
- ``query``
- ``headers``
- ``id``

### Type Method

- ``get(_:query:headers:)``
- ``post(_:query:headers:)``
- ``post(_:query:body:headers:)``
- ``put(_:query:headers:)``
- ``put(_:query:body:headers:)``
- ``patch(_:query:headers:)``
- ``patch(_:query:body:headers:)``
- ``delete(_:query:headers:)``
- ``delete(_:query:body:headers:)``
- ``head(_:query:headers:)``
- ``options(_:query:headers:)``
- ``trace(_:query:headers:)``
