import Foundation

extension Endpoint {
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
}
