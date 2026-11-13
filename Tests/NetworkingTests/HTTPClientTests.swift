import Foundation
import Testing
@testable import Networking

/// Intercepts every request on a session so tests never hit the network.
private final class StubURLProtocol: URLProtocol {
	/// Returns the response for a request, or throws to simulate a transport failure.
	nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Data, HTTPURLResponse))?
	/// Every request that reached the stub, in order.
	nonisolated(unsafe) static var requests: [URLRequest] = []

	override class func canInit(with request: URLRequest) -> Bool { true }
	override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

	override func startLoading() {
		Self.requests.append(request)
		do {
			guard let handler = Self.handler else { throw URLError(.unknown) }
			let (data, response) = try handler(request)
			client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			client?.urlProtocol(self, didLoad: data)
			client?.urlProtocolDidFinishLoading(self)
		} catch {
			client?.urlProtocol(self, didFailWithError: error)
		}
	}

	override func stopLoading() {}
}

/// A non-`Endpoint` conformer, to check the `any URLRequestConvertible` overload.
private struct StaticRequest: URLRequestConvertible {
	let request: URLRequest
	func urlRequest() throws -> URLRequest { request }
	func url() throws -> URL { request.url! }
	func urlComponents() throws -> URLComponents { URLComponents(url: request.url!, resolvingAgainstBaseURL: false)! }
}

private struct FailingRequest: URLRequestConvertible {
	struct BuildError: Error {}
	func urlRequest() throws -> URLRequest { throw BuildError() }
	func url() throws -> URL { throw BuildError() }
	func urlComponents() throws -> URLComponents { throw BuildError() }
}

// Serialized because the stub's handler and recorded requests are shared static state.
@Suite(.serialized)
final class HTTPClientTests {
	private let client: HTTPClient
	private let url = URL(string: "https://api.example.com/users")!

	init() {
		StubURLProtocol.handler = nil
		StubURLProtocol.requests = []
		let configuration = URLSessionConfiguration.ephemeral
		configuration.protocolClasses = [StubURLProtocol.self]
		client = HTTPClient(urlSession: URLSession(configuration: configuration))
	}

	private func stub(status: Int = 200, body: String = "ok") {
		StubURLProtocol.handler = { request in
			(Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
		}
	}

	private var sentRequest: URLRequest? { StubURLProtocol.requests.last }

	// MARK: network(request: URLRequest)

	@Test func requestReturnsDataAndResponse() async throws {
		stub(status: 201, body: "created")
		let (data, response) = try await client.network(request: URLRequest(url: url))
		#expect(String(decoding: data, as: UTF8.self) == "created")
		#expect((response as? HTTPURLResponse)?.statusCode == 201)
	}

	@Test func requestIsSentAsIs() async throws {
		stub()
		var request = URLRequest(url: url)
		request.httpMethod = "DELETE"
		request.setValue("42", forHTTPHeaderField: "X-Id")
		_ = try await client.network(request: request)
		#expect(sentRequest?.url == url)
		#expect(sentRequest?.httpMethod == "DELETE")
		#expect(sentRequest?.value(forHTTPHeaderField: "X-Id") == "42")
	}

	@Test func errorStatusIsReturnedNotThrown() async throws {
		stub(status: 404, body: "missing")
		let (data, response) = try await client.network(request: URLRequest(url: url))
		#expect(String(decoding: data, as: UTF8.self) == "missing")
		#expect((response as? HTTPURLResponse)?.statusCode == 404)
	}

	@Test func transportErrorIsThrown() async {
		StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
		await #expect {
			try await self.client.network(request: URLRequest(url: self.url))
		} throws: { error in
			(error as? URLError)?.code == .notConnectedToInternet
		}
	}

	// MARK: network(url:)

	@Test func urlSendsGET() async throws {
		stub(body: "users")
		let (data, _) = try await client.network(url: url)
		#expect(String(decoding: data, as: UTF8.self) == "users")
		#expect(sentRequest?.url == url)
		#expect(sentRequest?.httpMethod == "GET")
	}

	// MARK: network(endpoint:)

	@Test func endpointIsBuiltAndSent() async throws {
		stub(body: "posted")
		let endpoint = Endpoint()
			.scheme(.https)
			.host("api.example.com")
			.path("/users")
			.addQuery(name: "page", value: "2")
			.post()
			.bearer("abc123")
			.applicationJson()
		let (data, _) = try await client.network(endpoint: endpoint)
		#expect(String(decoding: data, as: UTF8.self) == "posted")
		#expect(sentRequest?.url?.absoluteString == "https://api.example.com/users?page=2")
		#expect(sentRequest?.httpMethod == "POST")
		#expect(sentRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
		#expect(sentRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
	}

	@Test func invalidEndpointThrowsWithoutSending() async {
		stub()
		let endpoint = Endpoint()
			.scheme(.https)
			.path("/users")
		await #expect(throws: EndpointError.missingHost) {
			try await self.client.network(endpoint: endpoint)
		}
		#expect(StubURLProtocol.requests.isEmpty)
	}

	// MARK: network(request: any URLRequestConvertible)

	@Test func convertibleIsBuiltAndSent() async throws {
		stub(body: "converted")
		var request = URLRequest(url: url)
		request.httpMethod = "PUT"
		let (data, _) = try await client.network(request: StaticRequest(request: request) as any URLRequestConvertible)
		#expect(String(decoding: data, as: UTF8.self) == "converted")
		#expect(sentRequest?.url == url)
		#expect(sentRequest?.httpMethod == "PUT")
	}

	@Test func failingConvertibleThrowsWithoutSending() async {
		stub()
		await #expect(throws: FailingRequest.BuildError.self) {
			try await self.client.network(request: FailingRequest() as any URLRequestConvertible)
		}
		#expect(StubURLProtocol.requests.isEmpty)
	}
}
