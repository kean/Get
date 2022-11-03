# ``Get/Request``

### Creating Requests

A request is represented using a simple `Request<Response>` struct. To create a request, use one of the factory methods:

```swift
// Simple request with a decodable response 
Request<User>(path: "/user")

// Request with additional parameters
var request = Request<Repo>(path: "/repos/octokit", method: .patch)
request.query = [("password", "123456")]
request.body = Repo(access: .public)
request.headers = ["Version": "v2"]

// Request with no explicit response type defaults to `Void` response type
Request(path: "/repos", method: .put, body: Repo(name: "CreateAPI"))
```

> tip: If the request's ``Request/url`` represents a relative URL, e.g. `"/user/repos"`, then it is appended to the client's ``APIClient/Configuration-swift.struct/baseURL``. If pass an absolute URL, e.g. `"https://api.github.com/user"`, it will be used as-is.

You can also initialize the request with a `URL` which can be either relative or absolute.

```swift
Request(url: URL(string: "https://api.github.com/user")!)
```

There is also a way to change the response type of the existing request. Let's say you want to decode the response using a different `Decodable` model or maybe you want to get the raw response `String`.

```swift
let request = Request<User>(path: "/user")

// Returns response as a raw `String`
let response = try await client.send(request.withResponse(String.self))
```

> tip: To learn more about defining network requests, see <doc:define-api>.
