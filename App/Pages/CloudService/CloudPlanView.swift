import SwiftUI

struct CloudPlanView: View {
  private let appNavigation = AppNavigationModel.shared
  @ObservedObject private var vehiclesStore: VehiclesStore = .shared
  let imei: String

  @State private var selectedIndex: Int = 0
  @State private var packages: [PackageItem] = []
  @State private var isLoading: Bool = false
  @State private var errorMessage: String? = nil

  private var currentVehicle: VehicleModel? {
    vehiclesStore.hashVehicles[imei]
  }

  var body: some View {
    VStack(spacing: 0) {
      // 1. Custom Navigation Bar with Tabs
      NavHeader(title: "") {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 20) {
            ForEach(Array(packages.enumerated()), id: \.offset) { index, package in
              Button {
                withAnimation {
                  selectedIndex = index
                }
              } label: {
                Text(package.displayTitle)
                  .font(.system(size: selectedIndex == index ? 18 : 16, weight: selectedIndex == index ? .bold : .medium))
                  .foregroundColor(selectedIndex == index ? ThemeColor.brand500 : Color(hex: "0x666666"))
              }
            }
          }
          .padding(.horizontal, 16)
        }
      }
      // HStack(spacing: 0) {
      //   Button {
      //     appNavigation.pop()
      //   } label: {
      //     Image(systemName: "chevron.left")
      //       .font(.system(size: 20, weight: .semibold))
      //       .foregroundColor(Color(hex: "0x111111"))
      //       .frame(width: 44, height: 44)
      //   }
      //   .padding(.leading, 8)

      //   if packages.isEmpty {
      //     Spacer()
      //     Text("云服务套餐")
      //       .font(.system(size: 18, weight: .bold))
      //       .foregroundColor(Color(hex: "0x111111"))
      //     Spacer()
      //   } else {
      //     ScrollView(.horizontal, showsIndicators: false) {
      //       HStack(spacing: 20) {
      //         ForEach(Array(packages.enumerated()), id: \.offset) { index, package in
      //           Button {
      //             withAnimation {
      //               selectedIndex = index
      //             }
      //           } label: {
      //             Text(package.displayTitle)
      //               .font(.system(size: selectedIndex == index ? 18 : 16, weight: selectedIndex == index ? .bold : .medium))
      //               .foregroundColor(selectedIndex == index ? ThemeColor.brand500 : Color(hex: "0x666666"))
      //           }
      //         }
      //       }
      //       .padding(.horizontal, 16)
      //     }
      //   }
      // }
      // .frame(height: 44 + safeAreaTop)
      // .padding(.top, safeAreaTop > 0 ? safeAreaTop - 20 : 0) // Adjust based on actual safe area behavior in custom nav
      // .background(Color.white)

      if isLoading {
        VStack(spacing: 12) {
          Spacer()
          ProgressView("加载套餐中...")
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0xF8F8F8"))
      } else if let errorMessage {
        VStack(spacing: 12) {
          Spacer()
          Text(errorMessage)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0xFF3B30"))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

          Button {
            Task { await fetchPackages() }
          } label: {
            Text("重试")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.white)
              .frame(width: 120, height: 40)
              .background(ThemeColor.brand500)
              .cornerRadius(20)
          }
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0xF8F8F8"))
      } else if packages.isEmpty {
        VStack(spacing: 12) {
          Spacer()
          Text("暂无可购买套餐")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "0x666666"))
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0xF8F8F8"))
      } else {
        // 2. Content TabView
        // Padding added externally to allow edge swipe gesture (pop) to work
        TabView(selection: $selectedIndex) {
          ForEach(Array(packages.enumerated()), id: \.offset) { index, package in
            PackageDetailView(package: package, vehicle: currentVehicle)
              .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .padding(.horizontal, 20) // Important: Allow edge swipe for navigation pop
        .background(Color(hex: "0xF8F8F8"))

        // 3. Bottom Purchase Bar
        VStack(spacing: 0) {
          Divider()
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("价格:")
                  .font(.system(size: 14))
                  .foregroundColor(Color(hex: "0x333333"))
                Text("¥\(packages[safe: selectedIndex]?.displayPriceYuanString ?? "0")")
                  .font(.system(size: 24, weight: .bold))
                  .foregroundColor(ThemeColor.brand500)
              }
              Text("原价: ¥\(packages[safe: selectedIndex]?.originalPriceYuanString ?? "0")")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "0x999999"))
                .strikethrough()
            }

            Spacer()

            Button {
              if let package = packages[safe: selectedIndex] {
                if package.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                  ToastCenter.shared.show("套餐信息异常，请稍后再试")
                  return
                }
                appNavigation.push(.cashier(package: package, imei: imei))
              } else {
                ToastCenter.shared.show("请选择套餐")
              }
            } label: {
              Text("立即购买")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 140, height: 44)
                .background(
                  LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "0x40C5FF"), ThemeColor.brand500]),
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .cornerRadius(22)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .padding(.bottom, safeAreaBottom)
          .background(Color.white)
        }
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .taskOnce {
      await fetchPackages()
    }
  }

  private func fetchPackages() async {
    if isLoading { return }
    await MainActor.run {
      isLoading = true
      errorMessage = nil
    }

    let result = await PackageAPI.shared.getPackages(imei)
    let list = result ?? []
    let filtered = list.filter { item in
      !item.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    await MainActor.run {
      isLoading = false
      packages = filtered
      if selectedIndex >= packages.count {
        selectedIndex = 0
      }
      if result == nil {
        errorMessage = "获取套餐失败，请稍后再试"
      }
    }
  }
}
