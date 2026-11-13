import Foundation

extension Endpoint {

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
}
