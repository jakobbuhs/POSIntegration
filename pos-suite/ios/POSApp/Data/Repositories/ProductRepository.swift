

import Foundation

final class ProductRepository {
    static let shared = ProductRepository()
    private init() {}
    
    struct ProductsResponse: Codable {
        let products: [Product]
        let count: Int
        let currency: String
        let cachedAt: String
    }
    
    /// Fetch all products from the API
    func fetchProducts() async throws -> [Product] {
        let response: ProductsResponse = try await APIClient.shared.get("/products?currency=NOK")
        return response.products
    }
    
    /// Force a product sync on the server
    func syncProducts() async throws {
        struct SyncResponse: Codable {
            let synced: Int
            let variants: Int
            let syncedAt: String
        }
        
        let _: SyncResponse = try await APIClient.shared.post("/products/sync", body: EmptyBody())
    }
    
    private struct EmptyBody: Codable {}
}
