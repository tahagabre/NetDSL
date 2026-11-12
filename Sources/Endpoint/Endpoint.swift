import Foundation

public struct Endpoint: Sendable {
	// MARK: URL Properties
	private(set) var scheme: String?
	private(set) var host: String?
	private(set) var path: String?
	private(set) var queries: [URLQueryItem]

	// MARK: Request Properties
	private(set) var body: Data?
	private(set) var method: HTTPMethod?
	private(set) var headers: [HTTPHeader]

	public init() {
		queries = []
		headers = []
	}

	/// Sets the URL scheme, such as `https`.
	///
	/// Replaces any previously set scheme.
	/// - Parameter scheme: The scheme the request URL uses.
	/// - Returns: A copy of the endpoint with the scheme set.
	public func scheme(
		_ scheme: Scheme
	) -> Endpoint {
		var copy = self
		copy.scheme = scheme.rawValue
		return copy
	}

	/// Sets the URL path, such as `/users/42`.
	///
	/// Replaces any previously set path.
	/// - Parameter path: The path appended after the host.
	/// - Returns: A copy of the endpoint with the path set.
	public func path(
		_ path: String
	) -> Endpoint {
		var copy = self
		copy.path = path
		return copy
	}

	// MARK: Host
	/// Sets the URL host from an async value, such as a host loaded from remote config.
	///
	/// Replaces any previously set host.
	///
	/// ```swift
	/// try await Endpoint()
	/// 	.host { try await config.apiHost() }
	/// ```
	/// - Parameter value: A closure that returns the host. Errors it throws are rethrown.
	/// - Returns: A copy of the endpoint with the host set.
	public func host(
		_ value: (@Sendable () async throws -> String)
	) async rethrows -> Endpoint {
		var updated = self
		updated.host = try await value()
		return updated
	}

	/// Sets the URL host, such as `api.example.com`.
	///
	/// Replaces any previously set host.
	/// - Parameter host: The host name, without scheme or path.
	/// - Returns: A copy of the endpoint with the host set.
	public func host(
		_ host: String
	) -> Endpoint {
		var updated = self
		updated.host = host
		return updated
	}

	// MARK: Queries
	/// Appends a query item to the URL.
	///
	/// Existing items with the same name are kept. Use ``setQuery(_:)`` to replace one.
	/// - Parameter query: The query item to append.
	/// - Returns: A copy of the endpoint with the query appended.
	public func addQuery(
		_ query: URLQueryItem
	) -> Endpoint {
		var copy = self
		copy.queries.append(query)
		return copy
	}

	/// Appends a query item built from a name and value, such as `page=2`.
	///
	/// Existing items with the same name are kept. Use ``setQuery(name:value:)`` to replace one.
	/// - Parameters:
	///   - name: The query item name.
	///   - value: The query item value.
	/// - Returns: A copy of the endpoint with the query appended.
	public func addQuery(
		name: String,
		value: String
	) -> Endpoint {
		addQuery(URLQueryItem(name: name, value: value))
	}

	/// Appends query items to the URL, in order.
	///
	/// Existing items with the same name are kept. Use ``setQuery(_:)`` to replace one.
	/// - Parameter queries: The query items to append.
	/// - Returns: A copy of the endpoint with the queries appended.
	public func addQueries(
		_ queries: [URLQueryItem]
	) -> Endpoint {
		var copy = self
		copy.queries.append(contentsOf: queries)
		return copy
	}

	/// Appends query items to the URL, in order.
	///
	/// Existing items with the same name are kept. Use ``setQuery(_:)`` to replace one.
	/// - Parameter queries: The query items to append.
	/// - Returns: A copy of the endpoint with the queries appended.
	public func addQueries(
		_ queries: URLQueryItem...
	) -> Endpoint {
		addQueries(queries)
	}

	/// Replaces the first query item with the same name, or appends it if none exists.
	/// - Parameter query: The query item to set.
	/// - Returns: A copy of the endpoint with the query set.
	public func setQuery(
		_ query: URLQueryItem
	) -> Endpoint {
		var copy = self
		guard let index = copy.queries.firstIndex(where: { $0.name == query.name }) else {
			return copy.addQuery(query)
		}

		copy.queries[index] = query
		return copy
	}

	/// Replaces the first query item with this name, or appends it if none exists.
	/// - Parameters:
	///   - name: The query item name.
	///   - value: The new value.
	/// - Returns: A copy of the endpoint with the query set.
	public func setQuery(
		name: String,
		value: String
	) -> Endpoint {
		var copy = self
		guard let index = copy.queries.firstIndex(where: { $0.name == name}) else {
			return copy.addQuery(name: name, value: value)
		}

		copy.queries[index] = URLQueryItem(name: name, value: value)
		return copy
	}

	// MARK: HTTP Method
	/// Sets the HTTP method.
	///
	/// Replaces any previously set method, so the last one set wins.
	/// - Parameter method: The HTTP method for the request.
	/// - Returns: A copy of the endpoint with the method set.
	public func method(
		_ method: HTTPMethod
	) -> Endpoint {
		var copy = self
		copy.method = method
		return copy
	}

	/// Sets the HTTP method to `GET`.
	///
	/// Replaces any previously set method.
	/// - Returns: A copy of the endpoint with the method set.
	public func get() -> Endpoint {
		method(.get)
	}

	/// Sets the HTTP method to `POST`.
	///
	/// Replaces any previously set method.
	/// - Returns: A copy of the endpoint with the method set.
	public func post() -> Endpoint {
		method(.post)
	}

	/// Sets the HTTP method to `PATCH`.
	///
	/// Replaces any previously set method.
	/// - Returns: A copy of the endpoint with the method set.
	public func patch() -> Endpoint {
		method(.patch)
	}

	/// Sets the HTTP method to `PUT`.
	///
	/// Replaces any previously set method.
	/// - Returns: A copy of the endpoint with the method set.
	public func put() -> Endpoint {
		method(.put)
	}

	/// Sets the HTTP method to `DELETE`.
	///
	/// Replaces any previously set method.
	/// - Returns: A copy of the endpoint with the method set.
	public func delete() -> Endpoint {
		method(.delete)
	}

	// MARK: HTTP Body
	/// Sets the request body by JSON-encoding a value with a default `JSONEncoder`.
	///
	/// Replaces any previously set body. This doesn't add a `Content-Type` header.
	/// - Parameter body: The value to encode.
	/// - Returns: A copy of the endpoint with the encoded body set.
	/// - Throws: The error from `JSONEncoder` if encoding fails.
	public func body<RequestBody: Encodable>(
		_ body: RequestBody
	) throws -> Endpoint {
		var copy = self
		let data = try JSONEncoder().encode(body)
		copy.body = data
		return copy
	}

	/// Sets the request body to raw data, such as an image or pre-encoded JSON.
	///
	/// Replaces any previously set body.
	/// - Parameter data: The bytes sent as the body.
	/// - Returns: A copy of the endpoint with the body set.
	public func body(
		_ data: Data
	) -> Endpoint {
		var copy = self
		copy.body = data
		return copy
	}

	// MARK: Headers
	/// Appends an HTTP header.
	///
	/// Existing headers with the same field are kept. To replace instead, use ``bearer(_:)``, ``accept(_:)`` or ``contentType(_:)``.
	/// - Parameter header: The header field and value.
	/// - Returns: A copy of the endpoint with the header appended.
	public func addHeader(
		_ header: HTTPHeader
	) -> Endpoint {
		var copy = self
		copy.headers.append(header)
		return copy
	}

	/// Appends HTTP headers, in order.
	///
	/// Existing headers with the same field are kept. To replace instead, use ``bearer(_:)``, ``accept(_:)`` or ``contentType(_:)``.
	/// - Parameter headers: The headers to append.
	/// - Returns: A copy of the endpoint with the headers appended.
	public func addHeaders(
		_ headers: [HTTPHeader]
	) -> Endpoint {
		var updated = self
		updated.headers.append(contentsOf: headers)
		return updated
	}

	/// Appends HTTP headers, in order.
	///
	/// Existing headers with the same field are kept. To replace instead, use ``bearer(_:)``, ``accept(_:)`` or ``contentType(_:)``.
	/// - Parameter headers: The headers to append.
	/// - Returns: A copy of the endpoint with the headers appended.
	public func addHeaders(
		_ headers: HTTPHeader...
	) -> Endpoint {
		addHeaders(headers)
	}

	/// Appends an HTTP header built from a field and value, such as `X-Request-ID: 42`.
	///
	/// Existing headers with the same field are kept. To replace instead, use ``bearer(_:)``, ``accept(_:)`` or ``contentType(_:)``.
	/// - Parameters:
	///   - field: The header field name.
	///   - value: The header value.
	/// - Returns: A copy of the endpoint with the header appended.
	public func addHeader(field: String, value: String) -> Endpoint {
		addHeader(
			HTTPHeader(
				field: field,
				value: value
			)
		)
	}

	/// Appends an HTTP header whose value is loaded asynchronously, such as an auth token.
	///
	/// Existing headers with the same field are kept. To replace instead, use ``bearer(_:)``, ``accept(_:)`` or ``contentType(_:)``.
	///
	/// ```swift
	/// let endpoint = try await Endpoint()
	/// 	.addHeader(field: "Authorization") { try await "Bearer \(auth.token())" }
	/// ```
	/// - Parameters:
	///   - field: The header field name.
	///   - value: A closure that returns the header value. Errors it throws are rethrown.
	/// - Returns: A copy of the endpoint with the header appended.
	public func addHeader(
		field: String,
		_ value: (() async throws -> String)
	) async rethrows -> Endpoint {
		addHeader(
			HTTPHeader(
				field: field,
				value: try await value()
			)
		)
	}

	/// Appends an HTTP header that is built asynchronously.
	///
	/// Existing headers with the same field are kept. To replace instead, use ``bearer(_:)``, ``accept(_:)`` or ``contentType(_:)``.
	/// - Parameter value: A closure that returns the header. Errors it throws are rethrown.
	/// - Returns: A copy of the endpoint with the header appended.
	public func addHeader(
		_ value: (
			@Sendable () async throws -> HTTPHeader
		)
	) async rethrows -> Endpoint {
		addHeader(try await value())
	}

	/// Sets an `Authorization: Bearer <token>` header for authenticated requests.
	///
	/// Replaces any existing `Authorization` header, so the request only ever has one.
	/// - Parameter token: The access token, without the `Bearer ` prefix.
	/// - Returns: A copy of the endpoint with the header set.
	public func bearer(_ token: String) -> Endpoint {
		replacingHeader(field: "Authorization", value: "Bearer \(token)")
	}

	/// Sets the `Accept` header, telling the server which response format you want.
	///
	/// Replaces any existing `Accept` header, so the request only ever has one.
	/// - Parameter type: The content type you expect back, such as ``HTTPContentType/json``.
	/// - Returns: A copy of the endpoint with the header set.
	public func accept(_ type: HTTPContentType) -> Endpoint {
		replacingHeader(field: "Accept", value: type.value)
	}

	/// Sets the `Content-Type` header, telling the server the format of the request body.
	///
	/// Replaces any existing `Content-Type` header, so the request only ever has one.
	/// - Parameter type: The body's content type, such as ``HTTPContentType/json``.
	/// - Returns: A copy of the endpoint with the header set.
	public func contentType(
		_ type: HTTPContentType
	) -> Endpoint {
		contentType(with: type.value)
	}

	/// Sets the `Content-Type` header from a raw string, for types ``HTTPContentType`` doesn't cover.
	///
	/// Replaces any existing `Content-Type` header, so the request only ever has one.
	/// - Parameter value: The content type, such as `text/plain; charset=utf-8`.
	/// - Returns: A copy of the endpoint with the header set.
	public func contentType(with value: String) -> Endpoint {
		replacingHeader(field: "Content-Type", value: value)
	}
	/// Sets the `Content-Type` header to `application/json`.
	///
	/// Replaces any existing `Content-Type` header, so the request only ever has one. Pair it with the `Encodable` `body(_:)` when sending JSON.
	/// - Returns: A copy of the endpoint with the header set.
	public func applicationJson() -> Endpoint {
		contentType(.json)
	}

	/// Removes every header named `field` (case-insensitively, as HTTP treats field names) and appends one with `value`.
	private func replacingHeader(field: String, value: String) -> Endpoint {
		var copy = self
		copy.headers.removeAll { $0.field.caseInsensitiveCompare(field) == .orderedSame }
		return copy.addHeader(field: field, value: value)
	}
}
