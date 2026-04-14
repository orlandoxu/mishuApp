import Foundation

// 对String的通用扩展

extension String {
  var isValidMobile: Bool {
    // 手机号正则表达式
    let mobileRegex = "^1[3-9]\\d{9}$"
    let mobilePredicate = NSPredicate(format: "SELF MATCHES %@", mobileRegex)

    return mobilePredicate.evaluate(with: self)
  }

  /// 去掉末尾的/
  var removeTrailingSlash: String {
    return replacingOccurrences(
      of: "/$",
      with: "",
      options: .regularExpression
    )
  }

  var dropTailZero: String {
    var s = self
    if !s.contains(".") {
      return s
    }

    while s.last == "0" {
      s.removeLast()
    }

    if s.last == "." {
      s.removeLast()
    }

    return s
  }

  var isUrl: Bool {
    let urlRegex = "^https?://.*"
    let urlPredicate = NSPredicate(format: "SELF MATCHES %@", urlRegex)
    // print("isUrl: \(self), \(urlPredicate.evaluate(with: self))")
    return urlPredicate.evaluate(with: self)
  }

  var isHttps: Bool {
    let httpsRegex = "^https://"
    let httpsPredicate = NSPredicate(format: "SELF MATCHES %@", httpsRegex)
    return httpsPredicate.evaluate(with: self)
  }

  var isHttp: Bool {
    let httpRegex = "^http://"
    let httpPredicate = NSPredicate(format: "SELF MATCHES %@", httpRegex)
    return httpPredicate.evaluate(with: self)
  }

  func removingSuffix(_ suffixes: [String]) -> String {
    for suffix in suffixes {
      if hasSuffix(suffix) {
        return String(dropLast(suffix.count))
      }
    }
    return self
  }
}
