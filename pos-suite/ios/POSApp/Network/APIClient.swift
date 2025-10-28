import Foundation

enum APIError: Error { case badURL, http(Int), decode, message(String) }

final class APIClient {
  static let shared = APIClient()
  private let base: URL
  private let sess: URLSession

  private init() {
    base = Secrets.shared.apiBaseURL
    sess = URLSession(configuration: .default)
  }

  func get<T: Decodable>(_ path: String) async throws -> T {
    guard let url = URL(string: path, relativeTo: base) else { throw APIError.badURL }
    var req = URLRequest(url: url)
    req.httpMethod = "GET"
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    let (data, resp) = try await sess.data(for: req)
    guard let http = resp as? HTTPURLResponse else { throw APIError.message("No HTTP") }
    guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode) }
    do { return try JSONDecoder().decode(T.self, from: data) } catch { throw APIError.decode }
  }

  func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
    guard let url = URL(string: path, relativeTo: base) else { throw APIError.badURL }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(body)
    let (data, resp) = try await sess.data(for: req)
    guard let http = resp as? HTTPURLResponse else { throw APIError.message("No HTTP") }
    guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode) }
    do { return try JSONDecoder().decode(T.self, from: data) } catch {
      // some endpoints return empty body; allow decoding to empty dictionary
      if T.self == Empty.self, data.isEmpty { return Empty() as! T }
      throw APIError.decode
    }
  }

  struct Empty: Decodable {}
}
