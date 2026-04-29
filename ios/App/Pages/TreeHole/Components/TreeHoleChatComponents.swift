import SwiftUI

struct TreeHoleChatMessage: Identifiable, Equatable {
  enum Role: Equatable {
    case user
    case ai
  }

  let id: String
  let role: Role
  let text: String
}

struct TreeHoleChatBubble: View {
  let message: TreeHoleChatMessage
  let maxBubbleWidth: CGFloat

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      if message.role == .ai {
        avatar
      } else {
        Spacer(minLength: 54)
      }

      VStack(alignment: message.role == .ai ? .leading : .trailing, spacing: 6) {
        if message.role == .ai {
          Text("暖暖")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color(hex: "#7B9260"))
        }

        Text(message.text)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(message.role == .ai ? Color(hex: "#5D5750") : .white)
          .lineSpacing(5)
          .fixedSize(horizontal: false, vertical: true)
          .padding(20)
          .background(message.role == .ai ? Color.white : Color(hex: "#7B9260"))
          .clipShape(ChatBubbleShape(role: message.role, radius: 24))
          .overlay {
            if message.role == .ai {
              ChatBubbleShape(role: message.role, radius: 24)
                .stroke(Color(hex: "#EADFC8"), lineWidth: 1)
            }
          }
          .shadow(color: Color.black.opacity(message.role == .ai ? 0.04 : 0), radius: 8, x: 0, y: 3)
      }
      .frame(maxWidth: maxBubbleWidth, alignment: message.role == .ai ? .leading : .trailing)

      if message.role == .user {
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, alignment: message.role == .ai ? .leading : .trailing)
  }

  private var avatar: some View {
    Image("img_emo_avatar_nuannuan")
      .resizable()
      .scaledToFill()
      .frame(width: 48, height: 48)
      .clipShape(Circle())
      .background(Circle().fill(Color.white))
      .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
      .padding(.top, 4)
  }
}

struct TreeHoleChatInputBar: View {
  @Binding var input: String
  var isFocused: FocusState<Bool>.Binding
  let onSend: () -> Void
  let onChangeTopic: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 8) {
        TextField("在此写下你想说的话", text: $input, axis: .vertical)
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color(hex: "#5D5750"))
          .lineLimit(1...4)
          .focused(isFocused)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .submitLabel(.send)
          .onSubmit(onSend)

        Button(action: onSend) {
          Image(systemName: "paperplane.fill")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Color(hex: "#7B9260"))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
      }
      .padding(8)
      .background(Color.white.opacity(0.82))
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(Color(hex: "#EADFC8"), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)

      Button(action: onChangeTopic) {
        HStack(spacing: 4) {
          Image(systemName: "arrow.clockwise")
            .font(.system(size: 15, weight: .bold))
          Text("换个话题")
            .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color(hex: "#A89886"))
      }
      .buttonStyle(.plain)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 4)
    .padding(.bottom, 12)
    .background(Color.clear)
  }
}

private struct ChatBubbleShape: Shape {
  let role: TreeHoleChatMessage.Role
  let radius: CGFloat

  func path(in rect: CGRect) -> Path {
    let corners: UIRectCorner = role == .user
      ? [.topLeft, .bottomLeft, .bottomRight]
      : [.topRight, .bottomLeft, .bottomRight]
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}
