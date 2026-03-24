import Kingfisher
import SwiftUI

/// 具体到某个相册的文件列表
struct AlbumListView: View {
  @StateObject private var viewModel: AlbumListViewModel
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @State private var showDeleteConfirm: Bool = false

  init(type: CloudAlbumType, imei: String) {
    _viewModel = StateObject(wrappedValue: AlbumListViewModel(type: type, imei: imei))
  }

  var body: some View {
    let isFolderEmpty = viewModel.assets.isEmpty

    VStack(spacing: 0) {
      // 顶部安全区域
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: viewModel.type.title) {
        HStack(spacing: 16) {
          // 筛选按钮
          if !viewModel.isEditing {
            Menu {
              ForEach(CloudAlbumFilter.allCases, id: \.self) { filter in
                Button {
                  viewModel.filter = filter
                  Task {
                    await viewModel.loadData(refresh: true)
                  }
                } label: {
                  Label(filter.rawValue, systemImage: filter.icon)
                }
              }
            } label: {
              Image("icon_message_filter")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(
                  isFolderEmpty
                    ? Color(hex: "0xCCCCCC")
                    : (viewModel.filter == .all ? Color(hex: "0x333333") : Color(hex: "0x06BAFF"))
                )
            }
            .disabled(isFolderEmpty)
          }

          // 编辑按钮
          Button {
            withAnimation {
              viewModel.isEditing.toggle()
              if !viewModel.isEditing {
                viewModel.selectedIds.removeAll()
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
                  : (!viewModel.isEditing ? Color(hex: "0x333333") : Color(hex: "0x06BAFF"))
              )
          }
          .disabled(isFolderEmpty)
        }
      }

      // 相册列表展示
      ZStack {
        ThemeColor.gray100.ignoresSafeArea()

        if viewModel.isLoading && viewModel.assets.isEmpty {
          ProgressView()
        } else if viewModel.assets.isEmpty {
          VStack {
            Image("img_empty")
            Text("暂无数据")
              .foregroundColor(.secondary)
              .padding(.top, 8)
          }
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(groupedAssets, id: \.0) { date, assets in
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
                  ForEach(assets, id: \.id) { asset in
                    AssetCell(asset: asset, isSelectedMode: viewModel.isEditing, isSelected: viewModel.selectedIds.contains(asset.id)) {
                      if viewModel.isEditing {
                        viewModel.toggleSelection(asset)
                      } else {
                        print("点击了 \(asset.id)")
                        appNavigation.push(.cloudAlbumAssetDetail(asset: asset))
                      }
                    }
                    .onAppear {
                      if asset == viewModel.assets.last {
                        Task {
                          await viewModel.loadData()
                        }
                      }
                    }
                  }
                }
                .padding(.horizontal, 16)
              }

              Spacer().frame(height: viewModel.isEditing ? 80 : 20)
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.assets.map(\.id))
          }
        }
      }

      // 底部编辑栏
      if viewModel.isEditing {
        HStack {
          // 备注：全选功能，下个版本再做
          // Button("全选") {
          //   viewModel.selectAll()
          // }
          // .foregroundColor(Color(hex: "0x333333"))

          Spacer()

          Button("取消") {
            withAnimation {
              viewModel.isEditing = false
              viewModel.selectedIds.removeAll()
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
              .background(viewModel.selectedIds.isEmpty ? Color.gray : Color.red)
              .cornerRadius(20)
          }
          .disabled(viewModel.selectedIds.isEmpty)
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
      }
    }
    .ignoresSafeArea(.all, edges: .top) // 顶部忽略安全区域，自己处理NavHeader
    .navigationBarHidden(true)
    .onAppear {
      Task {
        await viewModel.loadData(refresh: true)
      }
    }
    .alert(isPresented: $showDeleteConfirm) {
      Alert(
        title: Text("确认删除"),
        message: Text("确定删除已选中的\(viewModel.selectedIds.count)项内容吗？"),
        primaryButton: .destructive(Text("删除")) {
          Task {
            await viewModel.deleteSelected()
          }
        },
        secondaryButton: .cancel(Text("取消"))
      )
    }
  }

  // private func assetCell(_ asset: AlbumAsset) -> some View {
  //   GeometryReader { geo in
  //     ZStack(alignment: .topTrailing) {
  //       KFImage(URL(string: asset.urlThumb))
  //         .resizable()
  //         .scaledToFill()
  //         .frame(width: geo.size.width, height: geo.size.width * 9 / 16)
  //         .clipped()
  //         .cornerRadius(8)
  //         .contentShape(Rectangle())
  //         .onTapGesture {
  //           if viewModel.isEditing {
  //             viewModel.toggleSelection(asset)
  //           } else {
  //             appNavigation.push(.cloudAlbumAssetDetail(asset: asset))
  //           }
  //         }

  //       // 视频图标
  //       if asset.mtype == 2 {
  //         Image(systemName: "play.circle.fill")
  //           .font(.system(size: 32))
  //           .foregroundColor(.white.opacity(0.8))
  //           .frame(maxWidth: .infinity, maxHeight: .infinity)
  //           .allowsHitTesting(false)
  //       }

  //       // 前后摄标识 (左上角)
  //       Text(asset.camera == 1 ? "前摄" : "后摄") // 假设 1 是前摄
  //         .font(.system(size: 10))
  //         .foregroundColor(.white)
  //         .padding(.horizontal, 4)
  //         .padding(.vertical, 2)
  //         .background(Color.black.opacity(0.5))
  //         .cornerRadius(2)
  //         .padding(4)
  //         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

  //       // 时间 (右下角)
  //       Text(formatTime(asset.createTime))
  //         .font(.system(size: 12))
  //         .foregroundColor(.white)
  //         .padding(4)
  //         .shadow(color: .black, radius: 1)
  //         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

  //       // 编辑模式选中状态 (右上角)
  //       if viewModel.isEditing {
  //         Image(systemName: viewModel.selectedIds.contains(asset.id) ? "checkmark.circle.fill" : "circle")
  //           .font(.system(size: 20))
  //           .foregroundColor(viewModel.selectedIds.contains(asset.id) ? .blue : .white)
  //           .background(Circle().fill(Color.white.opacity(0.2))) // 增加点击区域可见性
  //           .padding(8)
  //       }
  //     }
  //   }
  //   .frame(maxWidth: .infinity)
  //   .aspectRatio(16 / 9, contentMode: .fit)
  // }

  /// 辅助属性：按日期分组
  private var groupedAssets: [(String, [AlbumAsset])] {
    let grouped = Dictionary(grouping: viewModel.assets) { asset -> String in
      let date = Date(timeIntervalSince1970: TimeInterval(asset.createTime) / 1000)
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy年MM月dd日"
      return formatter.string(from: date)
    }
    return grouped.sorted { $0.key > $1.key }
  }

  private func formatTime(_ timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }
}
