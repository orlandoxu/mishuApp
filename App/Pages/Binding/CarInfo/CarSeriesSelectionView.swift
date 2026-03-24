import SwiftUI

// DONE-AI: 目前还有一个问题，就是选择了某一个品牌之后，跳转到选择车型的这个页面之后，有一个很大的问题。就是车型没有显示。我看了网络，网络是有请求的，也有返回值的
// DONE-AI: 但是我测试了，还是没有看到车型列表啊

struct CarSeriesSelectionView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var bindingStore: BindingStore = .shared

  let brandId: Int
  let brandName: String
  var source: CarSelectionSource = .binding

  @State private var carSeries: [CarSeriesModel] = []
  @State private var isLoading = true

  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea()

      VStack(spacing: 0) {
        // Navigation Bar
        HStack(spacing: 0) {
          Button {
            appNavigation.pop()
          } label: {
            ZStack {
              Circle()
                .fill(Color.black.opacity(0.001))
                .frame(width: 44, height: 44)
              Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "0x111111"))
            }
          }
          .buttonStyle(.plain)

          Spacer()

          Text(brandName)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(hex: "0x111111"))

          Spacer()

          // Placeholder for symmetry
          Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 56 + safeAreaTop)

        if isLoading {
          Spacer()
          ProgressView()
          Spacer()
        } else if carSeries.isEmpty {
          Spacer()
          Text("暂无车型信息")
            .foregroundColor(Color(hex: "0x999999"))
            .font(.system(size: 14))
          Spacer()
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(carSeries, id: \.seriesId) { series in
                Button {
                  selectSeries(series)
                } label: {
                  VStack(spacing: 0) {
                    HStack {
                      Text(series.name)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "0x111111"))
                        .padding(.vertical, 16)

                      Spacer()

                      if bindingStore.seriesId == (Int(series.seriesId) ?? 0) {
                        Image(systemName: "checkmark")
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundColor(Color(hex: "0x06BAFF"))
                      }
                    }
                    .padding(.horizontal, 16)

                    Divider().padding(.leading, 16)
                  }
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
              }
            }
          }
        }
      }
    }
    .navigationBarHidden(true)
    .onAppear {
      loadSeries()
    }
  }

  private func loadSeries() {
    Task {
      if let list = await CarBrandAPI.shared.searchByBrandType(brandId: brandId) {
        await MainActor.run {
          self.carSeries = list
        }
      }
      await MainActor.run {
        self.isLoading = false
      }
    }
  }

  private func selectSeries(_ series: CarSeriesModel) {
    switch source {
    case .binding:
      bindingStore.seriesId = Int(series.seriesId) ?? 0
      bindingStore.carBrandName = brandName
      bindingStore.carSeriesName = series.name
      // Pop back to Step 3
      appNavigation.popTo(.bindStep3)

    case let .vehicleInfo(imei):
      updateVehicleInfo(imei: imei, series: series)
    }
  }

  private func updateVehicleInfo(imei: String, series: CarSeriesModel) {
    Task {
      // Step 1. 组装车型更新参数
      let payload = VehicleSetCarInfoPayload(imei: imei, seriesId: series.seriesId)
      // Step 2. 提交车型更新
      let result = await VehicleAPI.shared.setCarInfo(payload: payload)
      await VehiclesStore.shared.refresh()
      await MainActor.run {
        if result != nil {
          ToastCenter.shared.show("修改成功")
          appNavigation.popTo(.vehicleInfo(imei: imei))
        } else {
          ToastCenter.shared.show("修改失败，请稍后再试")
        }
      }
    }
  }
}
