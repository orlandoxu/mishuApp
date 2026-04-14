import SwiftUI

struct LoginBackgroundView: View {
  let bgColor: Color

  init(bgColor: Color = Color.white) {
    self.bgColor = bgColor
  }

  var body: some View {
    ZStack(alignment: .top) {
      bgColor.ignoresSafeArea()

      Image("background")
        .resizable()
        .scaledToFit() // 保持高宽比
        .frame(maxWidth: .infinity) // 水平撑满屏幕
        .clipped() // 超出部分裁掉
        .ignoresSafeArea(edges: .top) // 如果想顶到状态栏
    }
  }
}
