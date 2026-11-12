import Foundation
import Testing
@testable import Networking

struct EndpointTests {
	private struct TestError: Error {}

	// MARK: Init

	@Test func initStartsEmpty() {
		let endpoint = Endpoint()
		#expect(endpoint.scheme == nil)
		#expect(endpoint.host == nil)
		#expect(endpoint.path == nil)
		#expect(endpoint.queries.isEmpty)
		#expect(endpoint.body == nil)
		#expect(endpoint.method == nil)
		#expect(endpoint.headers.isEmpty)
	}

	// MARK: URL Properties

	@Test func schemeUsesRawValue() {
		let endpoint = Endpoint()
			.scheme(.https)
		#expect(endpoint.scheme == "https")
	}

	@Test func pathIsSet() {
		let endpoint = Endpoint()
			.path("/users")
		#expect(endpoint.path == "/users")
	}

	@Test func hostIsSet() {
		let endpoint = Endpoint()
			.host("api.example.com")
		#expect(endpoint.host == "api.example.com")
	}

	@Test func asyncHostIsSet() async {
		let endpoint = await Endpoint()
			.host { "api.example.com" }
		#expect(endpoint.host == "api.example.com")
	}

	@Test func asyncHostRethrows() async {
		await #expect(throws: TestError.self) {
			try await Endpoint()
				.host { throw TestError() }
		}
	}

	// MARK: Immutability

	@Test func buildersReturnCopiesAndLeaveOriginalUnchanged() {
		let base = Endpoint()
			.host("api.example.com")
		let users = base
			.path("/users")
		let posts = base
			.path("/posts")

		#expect(base.path == nil)
		#expect(users.path == "/users")
		#expect(posts.path == "/posts")
		#expect(users.host == "api.example.com")
	}

	// MARK: Queries

	@Test func addQueryAppends() {
		let endpoint = Endpoint()
			.addQuery(URLQueryItem(name: "a", value: "1"))
			.addQuery(name: "b", value: "2")
		#expect(endpoint.queries == [
			URLQueryItem(name: "a", value: "1"),
			URLQueryItem(name: "b", value: "2"),
		])
	}

	@Test func addQueryKeepsDuplicates() {
		let endpoint = Endpoint()
			.addQuery(name: "a", value: "1")
			.addQuery(name: "a", value: "2")
		#expect(endpoint.queries.count == 2)
	}

	@Test func addQueriesArrayAndVariadicAppendInOrder() {
		let endpoint = Endpoint()
			.addQueries([URLQueryItem(name: "a", value: "1")])
			.addQueries(URLQueryItem(name: "b", value: "2"), URLQueryItem(name: "c", value: "3"))
		#expect(endpoint.queries.map(\.name) == ["a", "b", "c"])
	}

	@Test func setQueryReplacesExistingInPlace() {
		let endpoint = Endpoint()
			.addQuery(name: "a", value: "1")
			.addQuery(name: "b", value: "2")
			.setQuery(URLQueryItem(name: "a", value: "9"))
		#expect(endpoint.queries == [
			URLQueryItem(name: "a", value: "9"),
			URLQueryItem(name: "b", value: "2"),
		])
	}

	@Test func setQueryAppendsWhenMissing() {
		let endpoint = Endpoint()
			.addQuery(name: "a", value: "1")
			.setQuery(URLQueryItem(name: "b", value: "2"))
		#expect(endpoint.queries.map(\.name) == ["a", "b"])
	}

	@Test func setQueryByNameReplacesExisting() {
		let endpoint = Endpoint()
			.addQuery(name: "a", value: "1")
			.setQuery(name: "a", value: "9")
		#expect(endpoint.queries == [URLQueryItem(name: "a", value: "9")])
	}

	@Test func setQueryByNameAppendsWhenMissing() {
		let endpoint = Endpoint()
			.setQuery(name: "a", value: "1")
		#expect(endpoint.queries == [URLQueryItem(name: "a", value: "1")])
	}

	@Test func setQueryReplacesOnlyFirstMatch() {
		let endpoint = Endpoint()
			.addQuery(name: "a", value: "1")
			.addQuery(name: "a", value: "2")
			.setQuery(name: "a", value: "9")
		#expect(endpoint.queries.map(\.value) == ["9", "2"])
	}

	// MARK: HTTP Method

	@Test(arguments: [HTTPMethod.get, .post, .put, .patch, .delete])
	func methodIsSet(_ method: HTTPMethod) {
		let endpoint = Endpoint()
			.method(method)
		#expect(endpoint.method == method)
	}

	@Test func methodShortcuts() {
		let get = Endpoint()
			.get()
		let post = Endpoint()
			.post()
		let put = Endpoint()
			.put()
		let patch = Endpoint()
			.patch()
		let delete = Endpoint()
			.delete()

		#expect(get.method == .get)
		#expect(post.method == .post)
		#expect(put.method == .put)
		#expect(patch.method == .patch)
		#expect(delete.method == .delete)
	}

	@Test func lastMethodWins() {
		let endpoint = Endpoint()
			.get()
			.post()
		#expect(endpoint.method == .post)
	}

	// MARK: Body

	@Test func dataBodyIsSet() {
		let data = Data("hello".utf8)
		let endpoint = Endpoint()
			.body(data)
		#expect(endpoint.body == data)
	}

	@Test func encodableBodyIsJSONEncoded() throws {
		struct Payload: Codable, Equatable { let id: Int }
		let endpoint = try Endpoint()
			.body(Payload(id: 7))
		let body = try #require(endpoint.body)
		#expect(try JSONDecoder().decode(Payload.self, from: body) == Payload(id: 7))
	}

	@Test func encodableBodyThrowsOnEncodingFailure() {
		struct Failing: Encodable {
			func encode(to encoder: Encoder) throws { throw TestError() }
		}
		#expect(throws: TestError.self) {
			try Endpoint()
				.body(Failing())
		}
	}

	// MARK: Headers

	@Test func addHeaderAppends() {
		let endpoint = Endpoint()
			.addHeader((field: "A", value: "1"))
			.addHeader((field: "B", value: "2"))
		#expect(endpoint.headers.map(\.field) == ["A", "B"])
		#expect(endpoint.headers.map(\.value) == ["1", "2"])
	}

	@Test func addHeadersArrayAndVariadicAppendInOrder() {
		let endpoint = Endpoint()
			.addHeaders([(field: "A", value: "1")])
			.addHeaders((field: "B", value: "2"), (field: "C", value: "3"))
		#expect(endpoint.headers.map(\.field) == ["A", "B", "C"])
	}

	@Test func addHeaderFieldValueAppends() {
		let endpoint = Endpoint()
			.addHeader(field: "A", value: "1")
			.addHeader(field: "A", value: "2")
		#expect(endpoint.headers.map(\.field) == ["A", "A"])
		#expect(endpoint.headers.map(\.value) == ["1", "2"])
	}

	@Test func bearerAddsAuthorizationHeader() {
		let endpoint = Endpoint()
			.bearer("abc123")
		#expect(endpoint.headers.map(\.field) == ["Authorization"])
		#expect(endpoint.headers.map(\.value) == ["Bearer abc123"])
	}

	@Test func acceptAddsAcceptHeader() {
		let endpoint = Endpoint()
			.accept(.json)
		#expect(endpoint.headers.map(\.field) == ["Accept"])
		#expect(endpoint.headers.map(\.value) == ["application/json"])
	}

	@Test(arguments: [
		(HTTPContentType.json, "application/json"),
		(.png, "image/png"),
		(.jpeg, "image/jpeg"),
		(.pdf, "application/pdf"),
		(.xls, "application/vnd.ms-excel"),
		(.xlsx, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
		(.ppt, "application/vnd.ms-powerpoint"),
		(.pptx, "application/vnd.openxmlformats-officedocument.presentationml.presentation"),
		(.doc, "application/msword"),
		(.docx, "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
	])
	func contentTypeAddsContentTypeHeader(_ type: HTTPContentType, _ expected: String) {
		let endpoint = Endpoint()
			.contentType(type)
		#expect(endpoint.headers.map(\.field) == ["Content-Type"])
		#expect(endpoint.headers.map(\.value) == [expected])
	}

	@Test func contentTypeWithRawValueAddsContentTypeHeader() {
		let endpoint = Endpoint()
			.contentType(with: "text/plain; charset=utf-8")
		#expect(endpoint.headers.map(\.field) == ["Content-Type"])
		#expect(endpoint.headers.map(\.value) == ["text/plain; charset=utf-8"])
	}

	@Test func applicationJsonAddsJSONContentType() throws {
		let endpoint = Endpoint()
			.applicationJson()
		#expect(endpoint.headers.map(\.field) == ["Content-Type"])
		#expect(endpoint.headers.map(\.value) == ["application/json"])
	}

	// MARK: Single-Value Headers

	@Test func acceptReplacesExistingAccept() {
		let endpoint = Endpoint()
			.accept(.json)
			.accept(.pdf)
		#expect(endpoint.headers.map(\.field) == ["Accept"])
		#expect(endpoint.headers.map(\.value) == ["application/pdf"])
	}

	@Test func bearerReplacesExistingBearer() {
		let endpoint = Endpoint()
			.bearer("old")
			.bearer("new")
		#expect(endpoint.headers.map(\.field) == ["Authorization"])
		#expect(endpoint.headers.map(\.value) == ["Bearer new"])
	}

	@Test func bearerReplacesCaseInsensitiveAuthorization() {
		let endpoint = Endpoint()
			.addHeader(field: "authorization", value: "Basic abc")
			.bearer("abc123")
		#expect(endpoint.headers.map(\.field) == ["Authorization"])
		#expect(endpoint.headers.map(\.value) == ["Bearer abc123"])
	}

	@Test func bearerLeavesOtherHeadersUntouched() {
		let endpoint = Endpoint()
			.addHeader(field: "X-Id", value: "42")
			.accept(.json)
			.bearer("old")
			.bearer("new")
		#expect(endpoint.headers.map(\.field) == ["X-Id", "Accept", "Authorization"])
		#expect(endpoint.headers.map(\.value) == ["42", "application/json", "Bearer new"])
	}

	@Test func contentTypeVariantsNeverDuplicate() {
		let endpoint = Endpoint()
			.contentType(.png)
			.contentType(with: "text/plain")
			.applicationJson()
			.contentType(.pdf)
		#expect(endpoint.headers.map(\.field) == ["Content-Type"])
		#expect(endpoint.headers.map(\.value) == ["application/pdf"])
	}

	@Test func singleValueHeadersReplaceCaseInsensitiveMatches() {
		let endpoint = Endpoint()
			.addHeader(field: "accept", value: "text/html")
			.addHeader(field: "CONTENT-TYPE", value: "text/html")
			.accept(.json)
			.contentType(.json)
		#expect(endpoint.headers.map(\.field) == ["Accept", "Content-Type"])
		#expect(endpoint.headers.map(\.value) == ["application/json", "application/json"])
	}

	@Test func singleValueHeadersLeaveOtherHeadersUntouched() {
		let endpoint = Endpoint()
			.addHeader(field: "X-Id", value: "42")
			.bearer("abc123")
			.accept(.json)
			.accept(.pdf)
			.contentType(.json)
			.contentType(.png)
		#expect(endpoint.headers.map(\.field) == ["X-Id", "Authorization", "Accept", "Content-Type"])
		#expect(endpoint.headers.map(\.value) == ["42", "Bearer abc123", "application/pdf", "image/png"])
	}

	@Test func asyncHeaderValueIsSet() async {
		let endpoint = await Endpoint()
			.addHeader(field: "Authorization") { "Bearer token" }
		#expect(endpoint.headers.first?.field == "Authorization")
		#expect(endpoint.headers.first?.value == "Bearer token")
	}

	@Test func asyncHeaderValueRethrows() async {
		await #expect(throws: TestError.self) {
			try await Endpoint()
				.addHeader(field: "Authorization") { throw TestError() }
		}
	}

	@Test func asyncHeaderIsSet() async {
		let endpoint = await Endpoint()
			.addHeader { (field: "X-Id", value: "42") }
		#expect(endpoint.headers.first?.field == "X-Id")
		#expect(endpoint.headers.first?.value == "42")
	}

	@Test func asyncHeaderRethrows() async {
		await #expect(throws: TestError.self) {
			try await Endpoint()
				.addHeader { () async throws -> HTTPHeader in throw TestError() }
		}
	}
}
