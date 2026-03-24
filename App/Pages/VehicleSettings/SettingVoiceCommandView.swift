import SwiftUI

struct SettingVoiceCommandView: View {
  private struct VoiceRow: Hashable {
    let title: String
    let commands: [String]
  }

  private let captureRows: [VoiceRow] = [
    .init(title: "拍照", commands: ["抓拍照片", "我要拍照"]),
    .init(title: "录像", commands: ["抓拍视频", "时空流上传"]),
  ]

  private let functionRows: [VoiceRow] = [
    .init(title: "锁定视频", commands: ["锁定视频"]),
    .init(title: "关闭录音", commands: ["关闭录音"]),
    .init(title: "打开录音", commands: ["打开录音"]),
  ]

  private let systemRows: [VoiceRow] = [
    .init(title: "格式化内存卡", commands: ["格式化内存卡"]),
  ]

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "语音命令")
      ScrollView(showsIndicators: false) {
        VStack(spacing: 0) {
          Image("icon_setting_mic")
            .resizable()
            .scaledToFit()
            .frame(width: 88, height: 88)
            .padding(.top, 28)

          Text("你可以通过以下语音指令控制记录仪，\n无需唤醒词，直接说出指令即可。")
            .font(.system(size: 17))
            .foregroundColor(Color(hex: "0x7D7D83"))
            .multilineTextAlignment(.center)
            .lineSpacing(7)
            .padding(.top, 28)
            .padding(.horizontal, 42)

          sectionTitle("拍照录像")
            .padding(.top, 36)
          commandCard(rows: captureRows)
            .padding(.top, 14)

          sectionTitle("拍照录像")
            .padding(.top, 38)
          commandCard(rows: functionRows)
            .padding(.top, 14)

          sectionTitle("系统")
            .padding(.top, 34)
          commandCard(rows: systemRows)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
      }
      .background(Color(hex: "0xF3F4F6"))
    }
    .ignoresSafeArea()
    .background(Color(hex: "0xF3F4F6"))
  }

  private func sectionTitle(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 14, weight: .semibold))
      .foregroundColor(Color(hex: "0x111111"))
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 18)
  }

  private func commandCard(rows: [VoiceRow]) -> some View {
    VStack(spacing: 0) {
      ForEach(Array(rows.enumerated()), id: \.element) { index, row in
        HStack(alignment: .center, spacing: 10) {
          Text(row.title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color(hex: "0x313236"))

          Spacer(minLength: 12)

          HStack(spacing: 8) {
            ForEach(row.commands, id: \.self) { command in
              Text(command)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x505157"))
                .padding(.horizontal, 14)
                .frame(height: 25)
                .background(Color(hex: "0xECEDEF"))
                .clipShape(Capsule())
            }
          }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 68)

        if index < rows.count - 1 {
          Rectangle()
            .fill(Color(hex: "0xE4E5E8"))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
        }
      }
    }
    .background(Color(hex: "0xF8F8F9"))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(.horizontal, 18)
  }
}
