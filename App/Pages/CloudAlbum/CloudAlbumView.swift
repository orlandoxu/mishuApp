import SwiftUI
import UIKit

/// 云相册的最顶层页面
struct CloudAlbumView: View {
  @StateObject private var viewModel: CloudAlbumViewModel
  @StateObject private var localAlbumStore: LocalAlbumStore = .shared
  @ObservedObject private var appNavigation: AppNavigationModel = .shared

  init(imei: String) {
    _viewModel = StateObject(wrappedValue: CloudAlbumViewModel.shared(imei: imei))
  }

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "云相册") {
        Button {
          viewModel.isGridView.toggle()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "square.grid.2x2")
              .foregroundColor(viewModel.isGridView == .grid ? .black : .gray)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(
                viewModel.isGridView == .grid
                  ? AnyView(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                      .fill(Color.white)
                  )
                  : AnyView(Color.clear)
              )
            Image(systemName: "list.bullet")
              .foregroundColor(viewModel.isGridView == .list ? .black : .gray)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(
                viewModel.isGridView == .list
                  ? AnyView(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                      .fill(Color.white)
                  )
                  : AnyView(Color.clear)
              )
          }
          .padding(.horizontal, 4)
          .padding(.vertical, 3)
          .background(Color(hex: "0xEEEEEE"))
          .cornerRadius(16)
        }
      }

      VStack(spacing: 0) {
        TabView(selection: $viewModel.isGridView) {
          // 聚合模式
          ScrollView {
            LazyVGrid(
              columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
              ],
              spacing: 12
            ) {
              Button {
                appNavigation.push(.localAlbum(imei: viewModel.imei))
              } label: {
                LocalAlbumCell(count: localAlbumStore.totalCount)
              }

              ForEach(CloudAlbumType.allCases.filter { $0 != .local }, id: \.self) { type in
                Button {
                  appNavigation.push(.cloudAlbumDetail(type: type, imei: viewModel.imei))
                } label: {
                  AlbumCell(
                    type: type,
                    count: viewModel.albumData.map { type.getCount(from: $0) } ?? 0
                  )
                }
              }
            }
            .padding(.top, 32)
            .padding(.bottom, 100)
          }
          .hideScrollIndicators()
          .tag(AlbumLayoutMode.grid)

          // 列表模式
          ScrollView {
            LazyVStack(spacing: 12) {
              ForEach(viewModel.listAssets, id: \.id) { asset in
                ListItemCell(asset: asset) {
                  appNavigation.push(.cloudAlbumAssetDetail(asset: asset))
                }
                .onAppear {
                  if asset == viewModel.listAssets.last {
                    Task {
                      await viewModel.fetchList()
                    }
                  }
                }
              }

              if viewModel.isListLoading {
                ProgressView()
                  .frame(maxWidth: .infinity, alignment: .center)
                  .padding(.vertical, 16)
              } else if viewModel.listAssets.isEmpty {
                VStack(spacing: 16) {
                  Image("img_message_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                  Text("暂无数据")
                    .foregroundColor(Color(hex: "0x999999"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
              }
            }
            .padding(.top, 32)
            .padding(.bottom, 100)
          }
          .hideScrollIndicators()
          .tag(AlbumLayoutMode.list)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      }
      .padding(.horizontal, 16)
      .background(ThemeColor.gray100)
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .onAppear {
      Task {
        await localAlbumStore.refreshIfAuthorized()
        await viewModel.fetchData()
      }
    }
  }
}
