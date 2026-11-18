# NetDSL

A small Swift package for building HTTP requests with chained modifiers, SwiftUI style, and sending them with `async`/`await`.

```swift
import NetDSL

let (data, response) = try await HTTPClient()
	.network(
		request: Endpoint()
			.scheme(.https)
			.host("api.example.com")
			.path("/users")
			.addQuery(name: "page", value: "2")
			.get()
			.bearer(token)
			.accept(.json)
	)
```

## Installation

Add the package with Swift Package Manager (Swift 6.4 or later):

```swift
dependencies: [
	.package(url: "https://github.com/tahagabre/NetDSL.git", branch: "main"),
],
targets: [
	.target(
		name: "MyApp",
		dependencies: [
			.product(name: "NetDSL", package: "NetDSL"),
		]
	),
]
```

## Building an Endpoint

`Endpoint` is a value type. Every modifier returns a new copy, so you can share a base endpoint and derive others from it without changing it. Put each modifier on its own line.

```swift
let api = Endpoint()
	.scheme(.https)
	.host("api.example.com")

let users = api
	.path("/users")

let user = api
	.path("/users/42")
```

### URL

| Modifier | Behavior |
| --- | --- |
| `scheme(_:)` | Sets the scheme. Replaces. |
| `host(_:)` | Sets the host. Replaces. |
| `path(_:)` | Sets the path and adds a missing leading `/`. Replaces. |
| `addQuery(_:)`, `addQuery(name:value:)`, `addQueries(_:)` | Appends query items. Keeps duplicates. |
| `setQuery(_:)`, `setQuery(name:value:)` | Replaces the first item with that name, or appends it. |

```swift
let search = api
	.path("search")
	.addQuery(name: "q", value: "swift testing")
	.addQuery(name: "tag", value: "ios")
	.addQuery(name: "tag", value: "macos")
	.setQuery(name: "q", value: "swift")
// https://api.example.com/search?q=swift&tag=ios&tag=macos
```

Query values are percent-encoded for you.

### Method

`method(_:)` or the shortcuts `get()`, `post()`, `put()`, `patch()` and `delete()`. The last method set wins. If no method is set, the request uses `GET`.

### Body

```swift
struct NewUser: Encodable {
	let firstName: String
}

let encoder = JSONEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase

let create = try api
	.path("/users")
	.post()
	.applicationJson()
	.body(NewUser(firstName: "Ada"), encoder: encoder)
```

`body(_:encoder:)` JSON-encodes any `Encodable`. The encoder defaults to a plain `JSONEncoder`. Use `body(_:)` with `Data` to send raw bytes. Neither sets `Content-Type`, so add it yourself.

### Headers

| Modifier | Behavior |
| --- | --- |
| `bearer(_:)` | Sets `Authorization: Bearer <token>`. Replaces. |
| `accept(_:)` | Sets `Accept`. Replaces. |
| `contentType(_:)`, `contentType(with:)`, `applicationJson()` | Sets `Content-Type`. Replaces. |
| `addHeader(_:)`, `addHeader(field:value:)`, `addHeaders(_:)` | Appends. Keeps duplicates. |

The modifiers that replace match header names ignoring case, so the request never ends up with two `Accept`, `Content-Type` or `Authorization` headers.

```swift
let upload = api
	.path("/files")
	.post()
	.bearer(token)
	.contentType(.pdf)
	.addHeader(field: "X-Request-ID", value: requestID)
	.body(pdfData)
```

### Async values

`host` and `addHeader` also take an `async` closure, for values you have to load first, such as a host from remote config or a fresh token:

```swift
let endpoint = try await Endpoint()
	.scheme(.https)
	.host { try await config.apiHost() }
	.path("/me")
	.addHeader(field: "X-Session") { try await session.id() }
```

Errors the closure throws are rethrown.

## Sending Requests

`HTTPClient` sends requests with `URLSession` (`.shared` by default) and returns the raw `(Data, URLResponse)`.

```swift
let client = HTTPClient()

let (data, response) = try await client.network(request: users)
let status = (response as? HTTPURLResponse)?.statusCode
let decoded = try JSONDecoder().decode([User].self, from: data)
```

`network` accepts an `Endpoint` or any other `URLRequestConvertible`, a `URLRequest`, or a `URL` (sent as a `GET`).

`4xx` and `5xx` responses are **returned, not thrown**, so check the status code yourself. Errors are thrown only when:

- the endpoint can't be built: `EndpointError.missingScheme`, `.missingHost`, `.missingPath` or `.invalidURL`, thrown before anything is sent;
- the transport fails, such as a `URLError` when there's no connection.

### Building the request yourself

`Endpoint` can also give you the request or its URL without sending it:

```swift
let request = try users.urlRequest()       // URLRequest
let url = try users.url()                  // https://api.example.com/users
let components = try users.urlComponents() // URLComponents
```

## Testing

Depend on the `Networking` protocol instead of `HTTPClient`. A conforming type only implements `network(request: URLRequest)`; the `Endpoint` and `URL` overloads come for free.

```swift
final class MockNetworking: Networking {
	var requests: [URLRequest] = []
	var response: HTTPResponse = (Data(), URLResponse())

	func network(request: URLRequest) async throws -> HTTPResponse {
		requests.append(request)
		return response
	}
}

final class UserService {
	let networking: any Networking

	init(networking: any Networking = HTTPClient()) {
		self.networking = networking
	}
}
```

To send your own request types, conform them to `URLRequestConvertible`:

```swift
struct LegacyRequest: URLRequestConvertible {
	func urlRequest() throws -> URLRequest {
		URLRequest(url: URL(string: "https://legacy.example.com/ping")!)
	}
}

try await client.network(request: LegacyRequest())
```
