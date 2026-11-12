import Foundation

extension Endpoint {
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
