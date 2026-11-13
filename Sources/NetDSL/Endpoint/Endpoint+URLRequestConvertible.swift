import Foundation

/// Errors thrown when an ``Endpoint`` can't be turned into a URL or request.
public enum EndpointError: Error {
	/// No path was set. Use ``Endpoint/path(_:)``.
	case missingPath
	/// No scheme was set. Use ``Endpoint/scheme(_:)``.
	case missingScheme
	/// No host was set. Use `host(_:)`.
	case missingHost
	/// The parts don't form a valid URL.
	case invalidURL
}

/// A type that can build a `URLRequest`, so it can be sent with `network(request:)` on any ``Networking``.
public protocol URLRequestConvertible {
	/// Builds the full request to send.
	func urlRequest() throws -> URLRequest
}

extension Endpoint: URLRequestConvertible {
	/// Builds a `URLRequest` from the endpoint's URL, method, body and headers.
	///
	/// ```swift
	/// let request = try Endpoint()
	/// 	.scheme(.https)
	/// 	.host("api.example.com")
	/// 	.path("/users")
	/// 	.post()
	/// 	.urlRequest()
	/// ```
	///
	/// If no method is set, the request uses `GET`. Headers that share a field name
	/// (ignoring case) are combined into one comma-separated value.
	/// - Returns: The request, ready to send.
	/// - Throws: An ``EndpointError`` if the URL can't be built. See ``url()``.
	public func urlRequest() throws -> URLRequest {
		let url = try url()
		var request = URLRequest(url: url)

		request.httpMethod = method?.rawValue
		request.httpBody = body

		for header in headers {
			request.addValue(header.value, forHTTPHeaderField: header.field)
		}

		return request
	}

	/// Builds the URL from the scheme, host, path and queries, such as `https://api.example.com/users?page=2`.
	///
	/// Scheme, host and path are required.
	/// Query values are percent-encoded for you.
	/// - Returns: The full URL.
	/// - Throws: ``EndpointError/missingScheme``, ``EndpointError/missingHost``,
	///   ``EndpointError/missingPath``, or ``EndpointError/invalidURL`` if the parts don't form a valid URL.
	public func url() throws(EndpointError) -> URL {
		guard scheme != nil else { throw .missingScheme }
		guard host != nil else { throw .missingHost }
		guard let url = try urlComponents().url else { throw .invalidURL }

		return url
	}

	/// Builds the `URLComponents` behind ``url()``, for when you need to inspect or adjust the parts.
	///
	/// Only the path is required here; scheme and host may be `nil`. Use ``url()`` for a validated URL.
	/// When there are no queries, `queryItems` is `nil`, so the URL has no trailing `?`.
	/// - Returns: The components, which may not form a valid URL.
	/// - Throws: ``EndpointError/missingPath`` if no path is set.
	public func urlComponents() throws(EndpointError) -> URLComponents {
		guard let path else { throw .missingPath }

		var components = URLComponents()
		components.scheme = scheme
		components.host = host
		components.path = path
		components.queryItems = queries.isEmpty ? nil : queries

		return components
	}
}
