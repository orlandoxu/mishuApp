import Foundation
// DONE-AI: 已理解该目录用于提供结构参考；当前项目模型与页面按业务域拆分在 Services/Pages 中，不依赖本文件代码。

struct ChapterUserProgress: Codable {
  let learnedWords: Int
  let progressPercentage: Int
  let isCompleted: Bool
}

struct ChapterItem: Identifiable, Codable {
  let id: String
  let bookId: String
  let order: Int
  let title: String
  let description: String?
  let totalWords: Int
  let difficulty: String?
  let estimatedTime: Int?
  let userProgress: ChapterUserProgress?

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case bookId
    case order
    case title
    case description
    case totalWords
    case difficulty
    case estimatedTime
    case userProgress
  }
}
