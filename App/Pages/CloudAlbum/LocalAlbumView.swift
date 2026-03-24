import AVKit
import Photos
import SwiftUI
import UIKit

/// 本地相册的列表
struct LocalAlbumView: View {
  private struct PreviewTarget: Identifiable {
    let id: String
  }

  let imei: String
  @StateObject private var store: LocalAlbumStore = .shared
  @State private var isEditing = false
  @State private var selectedIds: Set<String> = []
  @State private var previewTarget: PreviewTarget?
  @State private var showDeleteConfirm: Bool = false

  var body: some View {
    let isFolderEmpty = store.assets.isEmpty

    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "本地相册") {
        Button {
          withAnimation {
            isEditing.toggle()
            if !isEditing {
              selectedIds.removeAll()
            }
          }
        } label: {
          Image("icon_message_edit")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundColor(
              isFolderEmpty
                ? Color(hex: "0xCCCCCC")
                : (!isEditing ? Color(hex: "0x333333") : Color(hex: "0x06BAFF"))
            )
        }
        .disabled(isFolderEmpty)
      }

      ZStack {
        ThemeColor.gray100.ignoresSafeArea()

        if !hasPhotoPermission {
          VStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
              .font(.system(size: 48))
              .foregroundColor(.gray)
            Text("需要访问照片权限")
              .foregroundColor(.secondary)
            Button {
              Task {
                let status = await store.requestReadAuthorization()
                if status == .denied || status == .restricted {
                  openAppSettings()
                }
                await store.refreshIfAuthorized()
              }
            } label: {
              Text("去授权")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 38)
                .background(ThemeColor.brand500)
                .cornerRadius(19)
            }
            .buttonStyle(.plain)
          }
        } else if store.assets.isEmpty {
          VStack(spacing: 10) {
            Image("img_empty")
            Text("暂无数据")
          }
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(groupedItems, id: \.0) { date, items in
                Text(date)
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(Color(hex: "0x333333"))
                  .padding(.horizontal, 16)
                  .padding(.top, 16)
                  .padding(.bottom, 12)

                LazyVGrid(
                  columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                  ],
                  spacing: 12
                ) {
                  ForEach(items, id: \.localIdentifier) { asset in
                    assetCell(asset)
                  }
                }
                .padding(.horizontal, 16)
              }
            }
            .animation(.easeInOut(duration: 0.25), value: store.assets.map(\.localIdentifier))
            .padding(.bottom, isEditing ? 80 : 20)
          }
        }
      }

      if isEditing {
        HStack {
          // DONE-AI: 已增加全选/取消全选功能
          Button(isAllSelected ? "取消全选" : "全选") {
            toggleSelectAll()
          }
          .foregroundColor(isAllSelected ? Color(hex: "0x333333") : Color(hex: "0x06BAFF"))

          Spacer()

          Button("取消") {
            withAnimation {
              isEditing = false
              selectedIds.removeAll()
            }
          }
          .foregroundColor(Color(hex: "0x333333"))
          .padding(.trailing, 20)

          Button {
            showDeleteConfirm = true
          } label: {
            Text("删除")
              .foregroundColor(.white)
              .padding(.horizontal, 24)
              .padding(.vertical, 8)
              .background(selectedIds.isEmpty ? Color.gray : Color.red)
              .cornerRadius(20)
          }
          .disabled(selectedIds.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, safeAreaBottom + 16)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .taskOnce {
      _ = imei
      await store.refresh()
    }
    .fullScreenCover(item: $previewTarget) { target in
      let startIndex = store.assets.firstIndex(where: { $0.localIdentifier == target.id }) ?? 0
      LocalAssetFullPreview(
        assets: store.assets,
        startIndex: startIndex
      ) {
        previewTarget = nil
      }
      .id("\(target.id)-\(store.assets.count)")
    }
    .alert(isPresented: $showDeleteConfirm) {
      Alert(
        title: Text("确认删除"),
        message: Text("确定删除已选中的\(selectedIds.count)项内容吗？"),
        primaryButton: .destructive(Text("删除")) {
          Task {
            await deleteSelected()
          }
        },
        secondaryButton: .cancel(Text("取消"))
      )
    }
  }

  private func assetCell(_ asset: PHAsset) -> some View {
    GeometryReader { geo in
      ZStack(alignment: .topTrailing) {
        LocalAlbumThumbnail(asset: asset, size: geo.size.width)
          .frame(width: geo.size.width, height: geo.size.width * 9 / 16)
          .cornerRadius(8)
          .contentShape(Rectangle())
          .onTapGesture {
            if isEditing {
              toggleSelection(asset)
            } else {
              previewAsset(asset)
            }
          }

        if asset.mediaType == .video {
          Image(systemName: "play.circle.fill")
            .font(.system(size: 32))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }

        if isEditing {
          Group {
            if selectedIds.contains(asset.localIdentifier) {
              ZStack {
                Circle()
                  .fill(Color(hex: "0x06BAFF"))
                Image(systemName: "checkmark")
                  .font(.system(size: 11, weight: .semibold))
                  .foregroundColor(.white)
              }
            } else {
              Image(systemName: "circle")
                .foregroundColor(.white)
                .background(Circle().fill(Color.black.opacity(0.2)))
            }
          }
          .frame(width: 20, height: 20)
          .padding(8)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .aspectRatio(16 / 9, contentMode: .fit)
  }

  private func previewAsset(_ asset: PHAsset) {
    previewTarget = PreviewTarget(id: asset.localIdentifier)
  }

  private var groupedItems: [(String, [PHAsset])] {
    let grouped = Dictionary(grouping: store.assets) { asset -> String in
      guard let date = asset.creationDate else { return "未知日期" }
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy年MM月dd日"
      return formatter.string(from: date)
    }
    return grouped.sorted { $0.key > $1.key }
  }

  private var hasPhotoPermission: Bool {
    // return true
    store.authorization == .authorized || store.authorization == .limited
  }

  private func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  private func toggleSelection(_ asset: PHAsset) {
    let id = asset.localIdentifier
    if selectedIds.contains(id) {
      selectedIds.remove(id)
    } else {
      selectedIds.insert(id)
    }
  }

  private func toggleSelectAll() {
    if isAllSelected {
      selectedIds.removeAll()
      return
    }
    selectedIds = Set(store.assets.map(\.localIdentifier))
  }

  private func deleteSelected() async {
    let ids = Array(selectedIds)
    guard !ids.isEmpty else { return }

    let success = await store.deleteAssets(localIdentifiers: ids)
    if success {
      selectedIds.removeAll()
      isEditing = false
    } else {
      ToastCenter.shared.show("删除失败")
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }

  private var isAllSelected: Bool {
    !store.assets.isEmpty && selectedIds.count == store.assets.count
  }
}

private struct LocalAlbumThumbnail: View {
  let asset: PHAsset
  let size: CGFloat
  @State private var image: UIImage?

  var body: some View {
    ZStack {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .clipped()
      } else {
        Color.black.opacity(0.06)
      }
    }
    .onAppear {
      requestThumbnail()
    }
  }

  private func requestThumbnail() {
    let scale = UIScreen.main.scale
    let targetSize = CGSize(width: size * scale, height: size * 9 / 16 * scale)
    let options = PHImageRequestOptions()
    options.isSynchronous = false
    options.deliveryMode = .opportunistic
    options.resizeMode = .fast
    options.isNetworkAccessAllowed = true
    PHImageManager.default().requestImage(
      for: asset,
      targetSize: targetSize,
      contentMode: .aspectFill,
      options: options
    ) { result, _ in
      if let result {
        image = result
      }
    }
  }
}
