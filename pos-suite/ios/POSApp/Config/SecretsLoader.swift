import Foundation

struct Secrets {
  let apiBaseURL: URL
  let sumupAffiliateKey: String
  let shopifyShopDomain: String?
}

extension Secrets {
  static let shared: Secrets = {
    guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist") else {
      fatalError("Secrets.plist missing from app bundle (Target Membership?)")
    }
    guard
      let dict = NSDictionary(contentsOf: url) as? [String: Any],
      let base = dict["API_BASE_URL"] as? String,
      let apiURL = URL(string: base),
      let afk = dict["SUMUP_AFFILIATE_KEY"] as? String
    else {
      fatalError("Secrets.plist missing keys or invalid types: need API_BASE_URL (String) and SUMUP_AFFILIATE_KEY (String)")
    }
    return Secrets(
      apiBaseURL: apiURL,
      sumupAffiliateKey: afk,
      shopifyShopDomain: dict["SHOPIFY_SHOP_DOMAIN"] as? String
    )
  }()
}
