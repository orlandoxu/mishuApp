import SwiftUI

struct VehicleEmptyView: View {
  let onTapAdd: () -> Void

  var body: some View {
    GeometryReader { geo in
      // DONE-AI: 空状态图片与文案居中显示，间距 16
      VStack {
        Image("img_empty")
          .resizable()
          .scaledToFit()
          .frame(width: 200, height: 200)
        Text("还没有绑定记录仪哦")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x999999"))
      }
      .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
    }
    .frame(maxWidth: .infinity, minHeight: 360)
  }
}

struct EquipmentEmptyStateView_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      Color.white.ignoresSafeArea()
      VehicleEmptyView(onTapAdd: {})
        .padding(.horizontal, 20)
    }
    .previewLayout(.sizeThatFits)
  }
}
