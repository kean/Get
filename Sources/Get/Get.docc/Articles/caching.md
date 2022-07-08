# Caching

Learn how Get caches data.

## Overview

Caching is a great way to improve application performance and end-user experience. Developers often overlook [HTTP cache](https://tools.ietf.org/html/rfc7234) natively [supported](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html) by `URLSession` To enable HTTP caching the server sends special HTTP headers along with the request.

### HTTP Caching

Here is an example of properly configured HTTP `cache-control` headers:

```
HTTP/1.1 200 OK
Cache-Control: public, max-age=3600
Expires: Mon, 26 Jan 2016 17:45:57 GMT
Last-Modified: Mon, 12 Jan 2016 17:45:57 GMT
ETag: "686897696a7c876b7e"
```

This response is cacheable and will be *fresh* for 1 hour. When it becomes *stale*, the client validates it by making a *conditional* request using the `If-Modified-Since` and/or `If-None-Match` headers. If the response is still fresh the server returns status code [`304 Not Modified`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/304) to instruct the client to use cached data, or it would return `200 OK` with a new data otherwise.

> tip: By default, `URLSession` uses `URLCache.shared` with a small disk and memory capacity. You might not know it, but already be taking advantage of HTTP caching.

HTTP caching is a flexible system where both the server and the client get a say over what gets cached and how. With HTTP, a server can set restrictions on which responses are cacheable, set an expiration age for responses, provide validators (`ETag`, `Last-Modified`) to check stale responses, force revalidation on each request, and more.
