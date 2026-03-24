// import Foundation

// enum AppEnvironment: String {
//   case production
//   case staging
//   case development
// }

// final class EnvironmentStore {
//   static let shared = EnvironmentStore()

//   private let environmentKey = "mishu_environment"
//   private let baseURLOverrideKey = "mishu_base_url_override"

//   var environment: AppEnvironment {
//     get { AppEnvironment(rawValue: UserDefaults.standard.string(forKey: environmentKey) ?? "") ?? .production }
//     set { UserDefaults.standard.set(newValue.rawValue, forKey: environmentKey) }
//   }

//   var baseURLOverride: String? {
//     get { UserDefaults.standard.string(forKey: baseURLOverrideKey) }
//     set { UserDefaults.standard.set(newValue, forKey: baseURLOverrideKey) }
//   }

//   // func resolvedBaseURL() -> URL {
//   //     // Step 1. 优先使用用户覆盖的 baseURL
//   //     if let override = baseURLOverride, let url = URL(string: override) {
//   //         return url
//   //     }
//   //     // Step 2. 根据环境返回默认 baseURL（对齐 flutter api.dart）
//   //     switch environment {
//   //     case .production:
//   //         return URL(string: "https://api.spreadwin.cn")!
//   //     case .staging:
//   //         return URL(string: "https://api.spreadwin.cn")!
//   //     case .development:
//   //         return URL(string: "http://api-dev.spreadwin.cn")!
//   //     }
//   // }
// }
