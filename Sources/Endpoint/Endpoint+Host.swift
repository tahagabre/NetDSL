import Foundation

extension Endpoint {
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
}
