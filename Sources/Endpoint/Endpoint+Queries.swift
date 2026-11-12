import Foundation

extension Endpoint {
	/// Appends a query item to the URL.
	///
	/// Existing items with the same name are kept. Use ``setQuery(_:)`` to replace one.
	/// - Parameter query: The query item to append.
	/// - Returns: A copy of the endpoint with the query appended.
	public func addQuery(
		_ query: URLQueryItem
	) -> Endpoint {
		var copy = self
		copy.queries.append(query)
		return copy
	}

	/// Appends a query item built from a name and value, such as `page=2`.
	///
	/// Existing items with the same name are kept. Use ``setQuery(name:value:)`` to replace one.
	/// - Parameters:
	///   - name: The query item name.
	///   - value: The query item value.
	/// - Returns: A copy of the endpoint with the query appended.
	public func addQuery(
		name: String,
		value: String
	) -> Endpoint {
		addQuery(URLQueryItem(name: name, value: value))
	}

	/// Appends query items to the URL, in order.
	///
	/// Existing items with the same name are kept. Use ``setQuery(_:)`` to replace one.
	/// - Parameter queries: The query items to append.
	/// - Returns: A copy of the endpoint with the queries appended.
	public func addQueries(
		_ queries: [URLQueryItem]
	) -> Endpoint {
		var copy = self
		copy.queries.append(contentsOf: queries)
		return copy
	}

	/// Appends query items to the URL, in order.
	///
	/// Existing items with the same name are kept. Use ``setQuery(_:)`` to replace one.
	/// - Parameter queries: The query items to append.
	/// - Returns: A copy of the endpoint with the queries appended.
	public func addQueries(
		_ queries: URLQueryItem...
	) -> Endpoint {
		addQueries(queries)
	}

	/// Replaces the first query item with the same name, or appends it if none exists.
	/// - Parameter query: The query item to set.
	/// - Returns: A copy of the endpoint with the query set.
	public func setQuery(
		_ query: URLQueryItem
	) -> Endpoint {
		var copy = self
		guard let index = copy.queries.firstIndex(where: { $0.name == query.name }) else {
			return copy.addQuery(query)
		}

		copy.queries[index] = query
		return copy
	}

	/// Replaces the first query item with this name, or appends it if none exists.
	/// - Parameters:
	///   - name: The query item name.
	///   - value: The new value.
	/// - Returns: A copy of the endpoint with the query set.
	public func setQuery(
		name: String,
		value: String
	) -> Endpoint {
		var copy = self
		guard let index = copy.queries.firstIndex(where: { $0.name == name}) else {
			return copy.addQuery(name: name, value: value)
		}

		copy.queries[index] = URLQueryItem(name: name, value: value)
		return copy
	}
}
