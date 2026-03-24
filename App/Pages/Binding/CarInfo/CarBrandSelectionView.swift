import Kingfisher
import SwiftUI

struct CarBrandSelectionView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  var source: CarSelectionSource = .binding
  @State private var brandGroups: [(key: String, value: [CarBrandModel])] = []
  @State private var isLoading = true
  @State private var isIndexDragging = false
  @State private var indexSelection: String? = nil

  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea()

      VStack(spacing: 0) {
        // Spacer().frame(height: safeAreaTop).background(Color.white)
        NavHeader(title: "车型选择")

        if isLoading {
          Spacer()
          ProgressView()
          Spacer()
        } else {
          HStack(spacing: 0) {
            ScrollViewReader { proxy in
              ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                  ForEach(brandGroups, id: \.key) { group in
                    Section(header:
                      Text(group.key)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "0x999999"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "0xF5F5F5"))
                        .id(group.key))
                    {
                      ForEach(group.value, id: \.brandId) { brand in
                        // DONE-AI: 这个Button还是有问题，这个button最大的问题，是只有点击到了文字和头像才会跳转。需求是点击这一个横条，都应该能够跳转。就是触发的宽度太短了
                        Button {
                          appNavigation.push(.carSeriesSelection(brandId: brand.brandId, brandName: brand.brandName, source: source))
                        } label: {
                          VStack(spacing: 0) {
                            HStack(spacing: 12) {
                              if !brand.brandImg.isEmpty, let url = URL(string: brand.brandImg) {
                                KFImage(url)
                                  .resizable()
                                  .scaledToFit()
                                  .frame(width: 40, height: 40)
                              } else {
                                Image(systemName: "car")
                                  .resizable()
                                  .scaledToFit()
                                  .frame(width: 30, height: 30)
                                  .foregroundColor(.gray)
                              }

                              Text(brand.brandName)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "0x111111"))

                              Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                          }
                          .frame(maxWidth: .infinity, alignment: .leading)
                          .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                      }
                    }
                  }

                  Spacer().frame(height: safeAreaBottom)
                }
              }
              .overlay(
                HStack(spacing: 6) {
                  Spacer()
                  if isIndexDragging, let key = indexSelection {
                    Text(key)
                      .font(.system(size: 20, weight: .bold))
                      .foregroundColor(.white)
                      .frame(width: 48, height: 48)
                      .background(Color(hex: "0x111111").opacity(0.85))
                      .clipShape(RoundedRectangle(cornerRadius: 8))
                  }
                  GeometryReader { geo in
                    let indexKeys = brandGroups.map { $0.key }
                    VStack(spacing: 2) {
                      ForEach(indexKeys, id: \.self) { key in
                        Button {
                          withAnimation {
                            proxy.scrollTo(key, anchor: .top)
                          }
                        } label: {
                          Text(key)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "0x666666"))
                            .frame(width: 20, height: 16)
                        }
                        .buttonStyle(.plain)
                      }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    // .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.trailing, 4)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                      DragGesture(minimumDistance: 0)
                        .onChanged { value in
                          let itemHeight: CGFloat = 18
                          let totalHeight = itemHeight * CGFloat(indexKeys.count)
                          let topOffset = (geo.size.height - totalHeight) / 2
                          var y = value.location.y - topOffset
                          y = max(0, min(y, totalHeight - 1))
                          let index = Int(y / itemHeight)
                          let key = indexKeys[index]
                          if indexSelection != key {
                            indexSelection = key
                            withAnimation {
                              proxy.scrollTo(key, anchor: .top)
                            }
                          }
                          isIndexDragging = true
                        }
                        .onEnded { _ in
                          isIndexDragging = false
                          indexSelection = nil
                        }
                    )
                  }
                  .frame(width: 28)
                }
              )
            }
          }
        }
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .onAppear {
      loadBrands()
    }
  }

  private func loadBrands() {
    Task {
      if let brands = await CarBrandAPI.shared.allBrand() {
        let grouped = Dictionary(grouping: brands) { brand in
          PinyinUtils.getPinyinInitial(for: brand.brandName)
        }
        let sortedGroups = grouped.sorted { lhs, rhs in
          if lhs.key == "#" && rhs.key != "#" {
            return false
          }
          if rhs.key == "#" && lhs.key != "#" {
            return true
          }
          return lhs.key < rhs.key
        }
        await MainActor.run {
          self.brandGroups = sortedGroups
          self.isLoading = false
        }
      } else {
        await MainActor.run {
          self.isLoading = false
        }
      }
    }
  }
}
