import Foundation

public struct Endpoint: Sendable {
	// MARK: URL Properties
	var scheme: String?
	var host: String?
	var path: String?
	var queries: [URLQueryItem]

	// MARK: Request Properties
	var body: Data?
	var method: HTTPMethod?
	var headers: [HTTPHeader]

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
	/// Replaces any previously set path. A leading `/` is added if missing, so `users` becomes `/users`.
	/// - Parameter path: The path appended after the host.
	/// - Returns: A copy of the endpoint with the path set.
	public func path(
		_ path: String
	) -> Endpoint {
		var copy = self
		copy.path = path.hasPrefix("/") ? path : "/" + path
		return copy
	}
}
