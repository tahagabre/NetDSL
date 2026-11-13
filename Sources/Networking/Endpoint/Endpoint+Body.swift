import Foundation

extension Endpoint {

	/// Sets the request body by JSON-encoding a value.
	///
	/// Replaces any previously set body. This doesn't add a `Content-Type` header.
	/// - Parameters:
	///   - body: The value to encode.
	///   - encoder: The encoder to use, such as one with `.convertToSnakeCase` keys. Defaults to a plain `JSONEncoder`.
	/// - Returns: A copy of the endpoint with the encoded body set.
	/// - Throws: The error from `encoder` if encoding fails.
	public func body<RequestBody: Encodable>(
		_ body: RequestBody,
		encoder: JSONEncoder = JSONEncoder()
	) throws -> Endpoint {
		var copy = self
		let data = try encoder.encode(body)
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
