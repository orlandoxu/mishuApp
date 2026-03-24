import Foundation
import SwiftUI

@MainActor
final class AlbumListViewModel: ObservableObject {
  let type: CloudAlbumType
  let imei: String
  @Published var assets: [AlbumAsset] = []
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?
  @Published var filter: CloudAlbumFilter = .all
  @Published var isEditing: Bool = false
  @Published var selectedIds: Set<String> = []

  // Pagination
  private var page: Int = 1
  private let limit: Int = 20
  private var hasMore: Bool = true

  init(type: CloudAlbumType, imei: String) {
    self.type = type
    self.imei = imei
  }

  func loadData(refresh: Bool = false) async {
    if refresh {
      page = 1
      hasMore = true
      assets = []
    }

    guard hasMore, !isLoading else { return }

    isLoading = true
    errorMessage = nil

    let queryTypes = type.getAlbumTypeIds(filter: filter)
    let finalPayload = AlbumListV2Payload(
      imei: imei,
      limit: limit,
      page: page,
      type: queryTypes
    )

    let fetchedAssets = await AlbumAPI.shared.listV2(payload: finalPayload)
    if let fetchedAssets {
      if refresh {
        assets = fetchedAssets
      } else {
        assets.append(contentsOf: fetchedAssets)
      }

      hasMore = fetchedAssets.count >= limit
      if !fetchedAssets.isEmpty {
        page += 1
      }
    } else {
      errorMessage = "加载失败，请稍后再试"
    }

    isLoading = false
  }

  func deleteSelected() async {
    guard !selectedIds.isEmpty else { return }
    isLoading = true

    let result = await AlbumAPI.shared.deleteResource(ids: Array(selectedIds))

    if result != nil {
      withAnimation(.easeInOut(duration: 0.25)) {
        assets.removeAll { selectedIds.contains($0.id) }
      }
      selectedIds.removeAll()
      isEditing = false
      await CloudAlbumViewModel.shared(imei: imei).fetchData()
      ToastCenter.shared.show("删除成功")
    } else {
      ToastCenter.shared.show("删除失败，请稍后再试")
    }

    isLoading = false
  }

  func toggleSelection(_ asset: AlbumAsset) {
    if selectedIds.contains(asset.id) {
      selectedIds.remove(asset.id)
    } else {
      selectedIds.insert(asset.id)
    }
  }

  func selectAll() {
    if selectedIds.count == assets.count {
      selectedIds.removeAll()
    } else {
      selectedIds = Set(assets.map { $0.id })
    }
  }
}
