import SwiftUI

struct SettingInputItem: View {
  let item: TemplateItem
  let payload: InputPayload
  @ObservedObject private var store = TemplateStore.shared
  @State private var text: String = ""
  @State private var isUpdating = false

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(item.item ?? "")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x111111"))

        if let describe = item.describe, !describe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(describe)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x999999"))
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer()

      TextField("请输入", text: $text, onCommit: {
        updateValue()
      })
      .font(.system(size: 14))
      .foregroundColor(Color(hex: "0x666666"))
      .multilineTextAlignment(.trailing)
      .disabled(isUpdating)
      .keyboardType(.asciiCapable)
      .onAppear {
        if let c = item.c, let v = store.settings[c]?.v {
          text = v
        }
      }
    }
    .padding(.vertical, 12)
    .background(Color.white)
    .cornerRadius(8)
    .vehicleSettingsUpdatingOverlay(isUpdating)
  }

  private func updateValue() {
    if isUpdating {
      return
    }
    isUpdating = true
    Task {
      let success = await store.updateSetting(item: item, value: text)
      if !success {
        ToastCenter.shared.show("设置失败，请稍后再试")
      }
      isUpdating = false
    }
  }
}

struct SettingPasswordItem: View {
  let item: TemplateItem
  let payload: PasswordPayload
  @ObservedObject private var store = TemplateStore.shared
  @State private var text: String = ""
  @State private var isUpdating = false
  @State private var isSecure: Bool = true
  private static let allowedPasswordScalars: CharacterSet = {
    var symbols = ""
    let ranges: [ClosedRange<Int>] = [0x21 ... 0x2F, 0x3A ... 0x40, 0x5B ... 0x60, 0x7B ... 0x7E]
    for range in ranges {
      for value in range {
        if let scalar = UnicodeScalar(value) {
          symbols.unicodeScalars.append(scalar)
        }
      }
    }
    return CharacterSet.alphanumerics.union(CharacterSet(charactersIn: symbols))
  }()

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(item.item ?? "")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x111111"))

        if let describe = item.describe, !describe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(describe)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x999999"))
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer()

      HStack(spacing: 8) {
        Group {
          if isSecure {
            SecureField("请输入", text: $text, onCommit: {
              updateValue()
            })
          } else {
            TextField("请输入", text: $text, onCommit: {
              updateValue()
            })
          }
        }
        .font(.system(size: 14))
        .foregroundColor(Color(hex: "0x666666"))
        .multilineTextAlignment(.trailing)
        .keyboardType(.asciiCapable)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .onChange(of: text) { newValue in
          let filtered = filteredPasswordText(newValue)
          if filtered != newValue {
            text = filtered
          }
        }
        .disabled(isUpdating)

        Button {
          isSecure.toggle()
        } label: {
          Image(systemName: isSecure ? "eye.slash" : "eye")
            .foregroundColor(Color(hex: "0x999999"))
        }
        .buttonStyle(.plain)
        .disabled(isUpdating)
      }
      .frame(maxWidth: 180, alignment: .trailing)
    }
    .padding(.vertical, 12)
    .background(Color.white)
    .cornerRadius(8)
    .vehicleSettingsUpdatingOverlay(isUpdating)
    .onAppear {
      if let c = item.c, let v = store.settings[c]?.v {
        text = filteredPasswordText(v)
      }
    }
  }

  private func filteredPasswordText(_ input: String) -> String {
    String(input.unicodeScalars.filter { Self.allowedPasswordScalars.contains($0) })
  }

  private func updateValue() {
    if isUpdating {
      return
    }
    isUpdating = true
    Task {
      let success = await store.updateSetting(item: item, value: text)
      if !success {
        ToastCenter.shared.show("设置失败，请稍后再试")
      }
      isUpdating = false
    }
  }
}

struct SettingGpsItem: View {
  struct Option: Hashable {
    let value: String
    let title: String
  }

  let item: TemplateItem
  let payload: GpsPayload
  @ObservedObject private var store = TemplateStore.shared
  @State private var isUpdating = false

  var body: some View {
    let options = gpsOptions
    VStack(alignment: .leading, spacing: 12) {
      Text(item.item ?? "")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "0x111111"))

      if !options.isEmpty {
        VStack(spacing: 0) {
          ForEach(options, id: \.self) { option in
            Button {
              selectOption(option)
            } label: {
              HStack {
                Text(option.title)
                  .font(.system(size: 16))
                  .foregroundColor(Color(hex: "0x111111"))

                Spacer()

                if option.value == selectedValue {
                  Image(systemName: "checkmark")
                    .foregroundColor(Color(hex: "0x06BAFF"))
                }
              }
              .padding(16)
              .background(Color.white)
            }
            .buttonStyle(.plain)

            if option != options.last {
              Divider().padding(.leading, 16)
            }
          }
        }
      } else {
        Text("暂无可选定位模式")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x999999"))
      }

      if let describe = item.describe, !describe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(describe)
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x999999"))
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 12)
    .background(Color.white)
    .cornerRadius(8)
    .vehicleSettingsUpdatingOverlay(isUpdating)
  }

  private var selectedValue: String? {
    guard let c = item.c else { return nil }
    return store.settings[c]?.v
  }

  private var gpsOptions: [Option] {
    guard let c = item.c else { return [] }
    let allowed = store.settings[c]?.l ?? []
    if !allowed.isEmpty {
      return allowed.map { value in
        Option(value: value, title: gpsTitle(for: value))
      }
    }
    if let current = store.settings[c]?.v, !current.isEmpty {
      return [Option(value: current, title: gpsTitle(for: current))]
    }
    return []
  }

  private func gpsTitle(for value: String) -> String {
    let normalized = value.lowercased()
    if normalized == "0" || normalized == "off" || normalized == "close" || normalized == "关闭" {
      return "关闭"
    }
    if normalized == "1" || normalized == "gps" {
      return "GPS"
    }
    if normalized == "2" || normalized == "bd" || normalized == "beidou" || normalized == "北斗" {
      return "北斗"
    }
    if normalized == "3" || normalized == "gps+bd" || normalized == "gps_bd" || normalized == "gps&bd" || normalized == "gps北斗" {
      return "GPS+北斗"
    }
    return value
  }

  private func selectOption(_ option: Option) {
    guard let c = item.c else { return }
    if option.value == selectedValue {
      return
    }
    if isUpdating {
      return
    }
    isUpdating = true
    Task {
      let success = await store.updateSetting(c: c, source: item.source, value: option.value)
      if !success {
        ToastCenter.shared.show("设置失败，请稍后再试")
      }
      isUpdating = false
    }
  }
}
