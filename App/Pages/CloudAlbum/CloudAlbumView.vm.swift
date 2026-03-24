import Foundation
import SwiftUI

/// View state
enum AlbumLayoutMode: Hashable {
  case grid
  case list
}

extension AlbumLayoutMode {
  mutating func toggle() {
    self = self == .grid ? .list : .grid
  }
}

@MainActor
final class CloudAlbumViewModel: ObservableObject {
  private static var instances: [String: CloudAlbumViewModel] = [:]

  static func shared(imei: String) -> CloudAlbumViewModel {
    let key = imei.trimmingCharacters(in: .whitespacesAndNewlines)
    if let instance = instances[key] {
      return instance
    }
    let instance = CloudAlbumViewModel(imei: key)
    instances[key] = instance
    return instance
  }

  let imei: String

  // Grid Mode Data
  @Published var albumData: AlbumData?
  @Published var isLoading: Bool = false

  // List Mode Data
  @Published var listAssets: [AlbumAsset] = []
  @Published var isListLoading: Bool = false
  @Published var listHasMore: Bool = true
  private var listPage: Int = 1
  private let listLimit: Int = 20

  @Published var isGridView: AlbumLayoutMode = .grid {
    didSet {
      print("isGridView: \(isGridView)")
      if isGridView == .list, listAssets.isEmpty {
        Task {
          await fetchList(refresh: true)
        }
      }
    }
  }

  private init(imei: String) {
    self.imei = imei
  }

  func fetchData() async {
    isLoading = true
    albumData = await AlbumAPI.shared.dayCover(imei)
    isLoading = false
  }

  func fetchList(refresh: Bool = false) async {
    if refresh {
      listPage = 1
      listHasMore = true
      // Don't clear assets immediately to avoid flicker, or do it if preferred
      // listAssets = []
    }

    guard listHasMore, !isListLoading else { return }

    isListLoading = true

    let payload = AlbumListV2Payload(
      imei: imei,
      limit: listLimit,
      page: listPage,
      type: CloudAlbumType.allCloudIds
    )

    let fetchedAssets = await AlbumAPI.shared.listV2(payload: payload)

    if let fetchedAssets {
      if refresh {
        listAssets = fetchedAssets
      } else {
        listAssets.append(contentsOf: fetchedAssets)
      }

      listHasMore = fetchedAssets.count >= listLimit
      if !fetchedAssets.isEmpty {
        listPage += 1
      }
    }

    isListLoading = false
  }
}
