import Foundation
import Testing
@testable import Networking

struct EndpointURLRequestConvertibleTests {
	private let base = Endpoint()
		.scheme(.https)
		.host("api.example.com")
		.path("/users")

	// MARK: urlComponents()

	@Test func urlComponentsMapsParts() throws {
		let components = try base
			.addQuery(name: "page", value: "2")
			.urlComponents()
		#expect(components.scheme == "https")
		#expect(components.host == "api.example.com")
		#expect(components.path == "/users")
		#expect(components.queryItems == [URLQueryItem(name: "page", value: "2")])
	}

	@Test func urlComponentsHasNilQueryItemsWhenNoQueries() throws {
		let components = try base
			.urlComponents()
		#expect(components.queryItems == nil)
	}

	@Test func urlComponentsThrowsMissingPath() {
		#expect(throws: EndpointError.missingPath) {
			try Endpoint()
				.scheme(.https)
				.host("api.example.com")
				.urlComponents()
		}
	}

	@Test func urlComponentsOnlyRequiresPath() throws {
		let components = try Endpoint()
			.path("/users")
			.urlComponents()
		#expect(components.scheme == nil)
		#expect(components.host == nil)
		#expect(components.path == "/users")
	}

	// MARK: url()

	@Test func urlBuildsFullURL() throws {
		let url = try base
			.url()
		#expect(url.absoluteString == "https://api.example.com/users")
	}

	@Test func urlIncludesQueriesInOrder() throws {
		let url = try base
			.addQuery(name: "page", value: "2")
			.addQuery(name: "limit", value: "10")
			.url()
		#expect(url.absoluteString == "https://api.example.com/users?page=2&limit=10")
	}

	@Test func urlPercentEncodesPathAndQueries() throws {
		let url = try base
			.path("/a b")
			.addQuery(name: "q", value: "a b&c")
			.url()
		#expect(url.absoluteString == "https://api.example.com/a%20b?q=a%20b%26c")
	}

	@Test func urlThrowsMissingScheme() {
		#expect(throws: EndpointError.missingScheme) {
			try Endpoint()
				.host("api.example.com")
				.path("/users")
				.url()
		}
	}

	@Test func urlThrowsMissingHost() {
		#expect(throws: EndpointError.missingHost) {
			try Endpoint()
				.scheme(.https)
				.path("/users")
				.url()
		}
	}

	@Test func urlThrowsMissingPath() {
		#expect(throws: EndpointError.missingPath) {
			try Endpoint()
				.scheme(.https)
				.host("api.example.com")
				.url()
		}
	}

	@Test func urlChecksSchemeBeforeHostBeforePath() {
		#expect(throws: EndpointError.missingScheme) {
			try Endpoint()
				.url()
		}
		#expect(throws: EndpointError.missingHost) {
			try Endpoint()
				.scheme(.https)
				.url()
		}
	}

	@Test func urlWorksWhenPathLacksLeadingSlash() throws {
		let url = try base
			.path("users")
			.url()
		#expect(url.absoluteString == "https://api.example.com/users")
	}

	// MARK: urlRequest()

	@Test func urlRequestUsesURL() throws {
		let request = try base
			.addQuery(name: "page", value: "2")
			.urlRequest()
		#expect(request.url?.absoluteString == "https://api.example.com/users?page=2")
	}

	@Test(arguments: [HTTPMethod.get, .post, .put, .patch, .delete])
	func urlRequestUsesMethod(_ method: HTTPMethod) throws {
		let request = try base
			.method(method)
			.urlRequest()
		#expect(request.httpMethod == method.rawValue)
	}

	@Test func urlRequestDefaultsToGET() throws {
		let request = try base
			.urlRequest()
		#expect(request.httpMethod == "GET")
	}

	@Test func urlRequestUsesBody() throws {
		let data = Data("hello".utf8)
		let request = try base
			.post()
			.body(data)
			.urlRequest()
		#expect(request.httpBody == data)
	}

	@Test func urlRequestHasNoBodyByDefault() throws {
		let request = try base
			.urlRequest()
		#expect(request.httpBody == nil)
	}

	@Test func urlRequestUsesHeaders() throws {
		let request = try base
			.bearer("abc123")
			.accept(.json)
			.applicationJson()
			.addHeader(field: "X-Id", value: "42")
			.urlRequest()
		#expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
		#expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
		#expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
		#expect(request.value(forHTTPHeaderField: "X-Id") == "42")
	}

	@Test func urlRequestCombinesHeadersWithSameField() throws {
		let request = try base
			.addHeader(field: "X-Tag", value: "a")
			.addHeader(field: "x-tag", value: "b")
			.urlRequest()
		#expect(request.value(forHTTPHeaderField: "X-Tag") == "a,b")
	}

	@Test func urlRequestThrowsWhenURLIsInvalid() {
		#expect(throws: EndpointError.missingHost) {
			try Endpoint()
				.scheme(.https)
				.path("/users")
				.urlRequest()
		}
	}
}
