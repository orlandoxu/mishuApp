import Foundation

struct PinyinUtils {
  static func getPinyinInitial(for string: String) -> String {
    guard !string.isEmpty else { return "#" }
    
    let mutableString = NSMutableString(string: string)
    // 转换为拼音
    CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
    // 去除声调
    CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
    
    let pinyin = mutableString as String
    if let firstChar = pinyin.first {
      let letter = String(firstChar).uppercased()
      // 判断是否是字母
      if letter >= "A" && letter <= "Z" {
        return letter
      }
    }
    return "#"
  }
}
