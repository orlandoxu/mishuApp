import SwiftUI

struct EditableMoneyCategory: Identifiable, Equatable {
  let id: String
  var name: String
  let canEdit: Bool
}

struct MoneyCategorySettingsSheet: View {
  @Binding var expenseCategories: [EditableMoneyCategory]
  @Binding var incomeCategories: [EditableMoneyCategory]
  var onSave: ([EditableMoneyCategory], [EditableMoneyCategory]) -> Void

  @State private var activeTab: String = "expense"
  @State private var draftExpense: [EditableMoneyCategory] = []
  @State private var draftIncome: [EditableMoneyCategory] = []
  @State private var editingId: String?
  @State private var editText = ""
  @State private var pendingNewCategoryIds: Set<String> = []
  @FocusState private var isEditingFocused: Bool

  private var currentList: [EditableMoneyCategory] {
    activeTab == "expense" ? draftExpense : draftIncome
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 6) {
        tabButton("支出分类", tab: "expense")
        tabButton("收入分类", tab: "income")
      }
      .padding(6)
      .background(Color(hex: "#F8F9FB"))
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .padding(.bottom, 18)

      ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
          ForEach(currentList) { item in
            categoryCell(item)
          }
          Button {
            addCategory()
          } label: {
            Text("添加")
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(Color.black.opacity(0.45))
              .frame(maxWidth: .infinity)
              .frame(height: 42)
              .background(Color(hex: "#F8F9FB"))
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          }
          .buttonStyle(.plain)
        }
      }
      .frame(height: 260)
      .contentShape(Rectangle())
      .onTapGesture {
        dismissEditing(commit: true)
      }

      Text("“其他”分类不可编辑与删除")
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(Color.black.opacity(0.35))
        .padding(.top, 8)

      Button {
        dismissEditing(commit: true)
        expenseCategories = sanitizeList(draftExpense)
        incomeCategories = sanitizeList(draftIncome)
        onSave(expenseCategories, incomeCategories)
        closeSheet()
      } label: {
        Text("保存并返回")
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 60)
          .background(Color.black)
          .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      }
      .buttonStyle(.plain)
      .padding(.top, 18)
    }
    .padding(.horizontal, 28)
    .padding(.vertical, 28)
    .frame(maxWidth: 342)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    .onAppear {
      draftExpense = sanitizeList(expenseCategories)
      draftIncome = sanitizeList(incomeCategories)
    }
    .simultaneousGesture(
      TapGesture().onEnded {
        if editingId != nil {
          dismissEditing(commit: true)
        }
      }
    )
  }

  private func tabButton(_ title: String, tab: String) -> some View {
    Button {
      activeTab = tab
      editingId = nil
      editText = ""
    } label: {
      Text(title)
        .font(.system(size: 14, weight: .black))
        .foregroundColor(activeTab == tab ? .black : Color.black.opacity(0.25))
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(activeTab == tab ? Color.white : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func categoryCell(_ item: EditableMoneyCategory) -> some View {
    if editingId == item.id && item.canEdit {
      HStack(spacing: 8) {
        TextField("", text: $editText)
          .font(.system(size: 14, weight: .bold))
          .textFieldStyle(.plain)
          .focused($isEditingFocused)
        Button {
          deleteCategory(item.id)
        } label: {
          Image(systemName: "trash")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.red.opacity(0.85))
            .frame(width: 22, height: 22)
        }
        Button {
          saveCategory(item.id)
        } label: {
          Image(systemName: "checkmark")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.green.opacity(0.85))
            .frame(width: 22, height: 22)
        }
      }
      .padding(.horizontal, 10)
      .frame(height: 42)
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.black.opacity(0.08), lineWidth: 1))
    } else {
      Button {
        guard item.canEdit else { return }
        editingId = item.id
        editText = item.name
        isEditingFocused = true
      } label: {
        Text(item.name)
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(activeTab == "expense" ? Color(hex: "#E46784") : Color(hex: "#10A87B"))
          .frame(maxWidth: .infinity)
          .frame(height: 42)
          .background(activeTab == "expense" ? Color(hex: "#FFF2F4") : Color(hex: "#EFFFF8"))
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
      .buttonStyle(.plain)
    }
  }

  private func addCategory() {
    let newId = UUID().uuidString
    let next = EditableMoneyCategory(id: newId, name: "", canEdit: true)
    if activeTab == "expense" {
      draftExpense.append(next)
    } else {
      draftIncome.append(next)
    }
    pendingNewCategoryIds.insert(newId)
    editingId = next.id
    editText = ""
    isEditingFocused = true
  }

  private func saveCategory(_ id: String) {
    let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    if activeTab == "expense" {
      if let idx = draftExpense.firstIndex(where: { $0.id == id }) {
        draftExpense[idx].name = trimmed
      }
    } else {
      if let idx = draftIncome.firstIndex(where: { $0.id == id }) {
        draftIncome[idx].name = trimmed
      }
    }
    pendingNewCategoryIds.remove(id)
    dismissEditing(commit: false)
  }

  private func deleteCategory(_ id: String) {
    if activeTab == "expense" {
      draftExpense.removeAll { $0.id == id && $0.canEdit }
    } else {
      draftIncome.removeAll { $0.id == id && $0.canEdit }
    }
    pendingNewCategoryIds.remove(id)
    editingId = nil
    editText = ""
  }

  private func sanitizeList(_ input: [EditableMoneyCategory]) -> [EditableMoneyCategory] {
    var seen = Set<String>()
    var output: [EditableMoneyCategory] = []
    for item in input {
      let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
      if name.isEmpty { continue }
      if seen.contains(name) { continue }
      seen.insert(name)
      output.append(EditableMoneyCategory(id: item.id, name: name, canEdit: item.canEdit))
    }
    if !output.contains(where: { $0.name == "其他" }) {
      output.append(EditableMoneyCategory(id: "other-fixed-\(UUID().uuidString)", name: "其他", canEdit: false))
    }
    return output
  }

  private func closeSheet() {
    BottomSheetCenter.shared.hide()
  }

  private func dismissEditing(commit: Bool) {
    guard let editingId else {
      isEditingFocused = false
      return
    }
    if commit {
      let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        if activeTab == "expense" {
          if let idx = draftExpense.firstIndex(where: { $0.id == editingId }) {
            draftExpense[idx].name = trimmed
          }
        } else if let idx = draftIncome.firstIndex(where: { $0.id == editingId }) {
          draftIncome[idx].name = trimmed
        }
        pendingNewCategoryIds.remove(editingId)
      } else if pendingNewCategoryIds.contains(editingId) {
        draftExpense.removeAll { $0.id == editingId }
        draftIncome.removeAll { $0.id == editingId }
        pendingNewCategoryIds.remove(editingId)
      }
    }
    self.editingId = nil
    editText = ""
    isEditingFocused = false
  }
}
