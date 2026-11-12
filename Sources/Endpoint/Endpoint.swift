import Foundation

struct Endpoint: Sendable {
	// MARK: URL Properties
	public let scheme: String?
	public let host: String?
	public let path: String?
	public let queries: [URLQueryItem]

	// MARK: Request Properties
	public let body: Data?
	public let method: HTTPMethod?
	public let headers: [HTTPHeader]
}
