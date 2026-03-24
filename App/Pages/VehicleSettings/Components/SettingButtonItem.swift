import SwiftUI

struct SettingButtonItem: View {
  let item: TemplateItem
  let payload: ButtonPayload
  @ObservedObject private var store = TemplateStore.shared
  @State private var isUpdating = false
  @State private var showConfirm = false

  var body: some View {
    Button {
      if payload.copy == true {
        if let c = item.c, let v = store.settings[c]?.v {
          UIPasteboard.general.string = v
          ToastCenter.shared.show("已复制")
        }
        return
      }

      if let prompt = payload.confirmPrompt, !prompt.isEmpty {
        showConfirm = true
      } else {
        performAction()
      }
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: 6) {
          Text(item.item ?? "")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: payload.color ?? "0x111111"))

          if let describe = item.describe, !describe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(describe)
              .font(.system(size: 14))
              .foregroundColor(Color(hex: "0x999999"))
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(8)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .alert(isPresented: $showConfirm) {
      Alert(
        title: Text("提示"),
        message: Text(payload.confirmPrompt ?? ""),
        primaryButton: .destructive(Text("确定")) {
          performAction()
        },
        secondaryButton: .cancel(Text("取消"))
      )
    }
  }

  private func performAction() {
    isUpdating = true
    Task {
      let success = await store.updateSetting(item: item, value: "0")
      if success {
        ToastCenter.shared.show("操作成功")
      } else {
        ToastCenter.shared.show("操作失败，请稍后再试")
      }
      isUpdating = false
    }
  }
}
