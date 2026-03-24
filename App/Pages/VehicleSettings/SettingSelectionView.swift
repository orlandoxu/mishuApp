import SwiftUI

struct SettingSelectionView: View {
  let title: String
  let imei: String
  let itemC: String
  let options: [RadioPayload.Item]
  let selectedValue: String?
  let source: String

  @StateObject private var store = TemplateStore.shared
  private let appNavigation = AppNavigationModel.shared
  @State private var isUpdating = false

  var body: some View {
    let filteredOptions = filteredOptions(options, allowed: store.settings[itemC]?.l)
    VStack(spacing: 0) {
      NavHeader(title: title)

      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(filteredOptions, id: \.k) { option in
            Button {
              selectOption(option)
            } label: {
              HStack {
                Text(option.v ?? "")
                  .font(.system(size: 16))
                  .foregroundColor(Color(hex: "0x111111"))

                Spacer()

                if let key = option.k, key == selectedValue {
                  Image(systemName: "checkmark")
                    .foregroundColor(Color(hex: "0x06BAFF"))
                }
              }
              .padding(16)
              .background(Color.white)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 16)
          }
        }
      }
      .background(Color(hex: "0xF5F6F7"))

      if isUpdating {
        Color.black.opacity(0.1)
          .ignoresSafeArea()
          .overlay(ProgressView())
      }
    }
    .navigationBarHidden(true)
  }

  private func selectOption(_ option: RadioPayload.Item) {
    guard let value = option.k else { return }
    if value == selectedValue {
      appNavigation.pop()
      return
    }

    isUpdating = true
    Task {
      let success = await store.updateSetting(c: itemC, source: source, value: value)
      if success {
        await MainActor.run {
          appNavigation.pop()
        }
      } else {
        ToastCenter.shared.show("设置失败，请稍后再试")
      }
      isUpdating = false
    }
  }

  private func filteredOptions(_ options: [RadioPayload.Item], allowed: [String]?) -> [RadioPayload.Item] {
    guard let allowed, !allowed.isEmpty else { return options }
    let allowSet = Set(allowed)
    return options.filter { option in
      guard let key = option.k else { return false }
      return allowSet.contains(key)
    }
  }
}
