import Foundation

/// The raw result of a request: the response body and the response metadata.
///
/// For HTTP requests, cast the `URLResponse` to `HTTPURLResponse` to read the status code and headers.
public typealias HTTPResponse = (Data, URLResponse)

/// A type that sends network requests and returns their raw response.
///
/// Depend on this protocol instead of ``HTTPClient`` so you can swap in a mock in tests.
/// A conforming type only implements `network(request: URLRequest)`; the other overloads build on it.
public protocol Networking {
	/// Sends a `URLRequest` as is.
	/// - Parameter request: The request to send.
	/// - Returns: The response body and metadata.
	func network(request: URLRequest) async throws -> HTTPResponse
}

extension Networking {
	/// Sends a `GET` request to a URL, with no headers or body.
	/// - Parameter url: The URL to request.
	/// - Returns: The response body and metadata.
	/// - Throws: The error from `network(request: URLRequest)`.
	public func network(url: URL) async throws -> HTTPResponse {
		try await network(request: URLRequest(url: url))
	}

	/// Builds a request from any ``URLRequestConvertible``, such as an ``Endpoint``, and sends it.
	/// - Parameter request: The value to build the request from.
	/// - Returns: The response body and metadata.
	/// - Throws: The error from ``URLRequestConvertible/urlRequest()`` if the request can't be built,
	///   before anything is sent, or the error from `network(request: URLRequest)`.
	public func network(request: any URLRequestConvertible) async throws -> HTTPResponse {
		try await network(request: request.urlRequest())
	}
}

/// Sends requests with `URLSession`.
///
/// ```swift
/// let (data, response) = try await HTTPClient()
/// 	.network(
/// 		request: Endpoint()
/// 			.scheme(.https)
/// 			.host("api.example.com")
/// 			.path("/users")
/// 			.get()
/// 	)
/// ```
///
/// Any response the server sends back is returned, including `4xx` and `5xx`. Check the status code yourself.
/// Errors are thrown only when the request can't be built or the transport fails, such as no connection.
public final class HTTPClient: Sendable, Networking {
	/// The session used to send every request.
	public let urlSession: URLSession

	/// Creates a client that sends requests with the given session.
	/// - Parameter urlSession: The session to use. Defaults to `URLSession.shared`.
	public init(urlSession: URLSession = .shared) {
		self.urlSession = urlSession
	}

	/// Sends a `URLRequest` as is.
	/// - Parameter request: The request to send.
	/// - Returns: The response body and metadata.
	/// - Throws: The `URLSession` error, such as a `URLError`, if the request fails to complete.
	public func network(request: URLRequest) async throws -> HTTPResponse {
		try await urlSession.data(for: request)
	}
}
