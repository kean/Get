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
