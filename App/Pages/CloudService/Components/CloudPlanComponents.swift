import SwiftUI

// DONE-AI: 车联/守护权益静态数据已抽到 ServiceRightsCatalog

struct PackageDetailView: View {
  let package: PackageItem
  let vehicle: VehicleModel?

  private var simResource: PackageResourceItem? {
    package.coreSimResource
  }

  private var spaceResource: PackageResourceItem? {
    package.coreSpaceResource
  }

  private var timeResource: PackageResourceItem? {
    package.coreTimeResource
  }

  private var isXjCard: Bool {
    vehicle?.sim?.isXjCard == true
  }

  private var packageCycleText: String {
    let candidates = [
      simResource?.cycleText,
      spaceResource?.cycleText,
      timeResource?.cycleText,
      package.displayDuration,
    ]
    for candidate in candidates {
      let value = (candidate ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      if !value.isEmpty {
        return value
      }
    }
    return ""
  }

  private var simCycleText: String {
    (simResource?.cycleText ?? packageCycleText).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var simFlowText: String {
    if let sim = vehicle?.sim, sim.totalFlow > 0 {
      return sim.totalFlowString
    }
    if let simResource {
      return "\(max(0, simResource.total))GB"
    }
    return "0GB"
  }

  private var settleDayText: String {
    let raw = vehicle?.sim?.flowSettleDay.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !raw.isEmpty {
      let digits = raw.filter(\.isNumber)
      if !digits.isEmpty {
        return "每月\(digits)号结算"
      }
      return raw
    }
    return "每月26号结算"
  }

  private var iccidText: String {
    let raw = vehicle?.sim?.iccId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return raw.isEmpty ? "--" : raw
  }

  private var cloudValue: (value: String, unit: String, cycle: String)? {
    guard let spaceResource else { return nil }
    if spaceResource.resType == "spaceCycle" {
      return (
        value: "\(max(0, spaceResource.total))",
        unit: "天循环",
        cycle: spaceResource.cycleText
      )
    }
    return (
      value: "\(max(0, spaceResource.total))",
      unit: "",
      cycle: spaceResource.cycleText
    )
  }

  private var playbackValue: (value: String, unit: String, cycle: String)? {
    guard let timeResource else { return nil }
    return (
      value: "\(max(0, timeResource.total))",
      unit: "分钟",
      cycle: timeResource.cycleText
    )
  }

  private var guardPeriodText: String {
    (package.guardResources.first?.cycleText ?? packageCycleText)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 14) {
        if isXjCard {
          SimIccidCard(iccid: iccidText).padding(.top, 20)
          SimPackageCard(flowText: simFlowText, cycleText: simCycleText, settleDayText: settleDayText)
        }

        SimPackageBanner().padding(.vertical, 52)

        if cloudValue != nil || playbackValue != nil {
          HStack(spacing: 12) {
            if let cloudValue {
              PlanSummaryCard(title: "云端存储", value: cloudValue.value, unit: cloudValue.unit, cycle: cloudValue.cycle)
            }

            if let playbackValue {
              PlanSummaryCard(title: "远程播放", value: playbackValue.value, unit: playbackValue.unit, cycle: playbackValue.cycle)
            }
          }
        }

        if !package.serviceResources.isEmpty {
          RightsSection(title: "车联服务权益", items: ServiceRightsCatalog.baseServices)
        }

        if !package.guardResources.isEmpty {
          RightsSection(title: "爱车守护权益", period: guardPeriodText, items: ServiceRightsCatalog.guardServices)
        }

        Spacer().frame(height: 20)
      }
      .padding(.top, 14)
    }
  }
}

private struct SimIccidCard: View {
  let iccid: String

  var body: some View {
    HStack(spacing: 8) {
      Text("ICCID：")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "0x333333"))
      Text(iccid)
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(Color(hex: "0x333333"))
      Spacer()
    }
    .padding(.horizontal, 16)
    .frame(height: 56)
    .background(Color(hex: "#FFF3CC"))
    .cornerRadius(12)
  }
}

private struct SimPackageCard: View {
  let flowText: String
  let cycleText: String
  let settleDayText: String

  private var flowNumberText: String {
    flowText.replacingOccurrences(of: "GB", with: "")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("设备Sim卡流量包")
        .font(.system(size: 23, weight: .bold))
        .foregroundColor(.white)

      HStack(alignment: .firstTextBaseline) {
        Text(flowNumberText)
          .font(.system(size: 26, weight: .bold))
          .foregroundColor(.white)
          + Text("GB/月流量")
          .font(.system(size: 18))
          .foregroundColor(Color.white.opacity(0.9))
          + Text(cycleText.isEmpty ? "" : " * \(cycleText)")
          .font(.system(size: 26, weight: .bold))
          .foregroundColor(.white)

        Spacer()

        Text(settleDayText)
          .font(.system(size: 18))
          .foregroundColor(Color.white.opacity(0.9))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 18)
    .background(
      RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#66D5FF"))
      // LinearGradient(
      //   gradient: Gradient(colors: [Color(hex: "0x40C5FF"), ThemeColor.brand500]),
      //   startPoint: .topLeading,
      //   endPoint: .bottomTrailing
      // )
    )
    .cornerRadius(14)
    .shadow(color: Color(hex: "0x06BAFF").opacity(0.22), radius: 8, x: 0, y: 4)
  }
}

private struct SimPackageBanner: View {
  var body: some View {
    HStack(spacing: 10) {
      Image("img_package_arraw_left")
        .resizable()
        .scaledToFit()
        .frame(width: 84, height: 10)

      VStack(spacing: 2) {
        Text("购买流量包")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(ThemeColor.brand500)
        Text("立即享受车联服务")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(ThemeColor.brand500)
      }

      Image("img_package_arraw_right")
        .resizable()
        .scaledToFit()
        .frame(width: 84, height: 10)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 2)
  }
}

private struct PlanSummaryCard: View {
  let title: String
  let value: String
  let unit: String
  let cycle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 16))
        .foregroundColor(Color(hex: "0x777777"))

      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(value)
          .font(.system(size: 21, weight: .bold))
          .foregroundColor(Color(hex: "0x333333"))
        if !unit.isEmpty {
          Text(unit)
            .font(.system(size: 17))
            .foregroundColor(Color(hex: "0x777777"))
        }
        if !cycle.isEmpty {
          Text("/\(cycle)")
            .font(.system(size: 17))
            .foregroundColor(Color(hex: "0xA0A0A0"))
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
    .background(Color.white)
    .cornerRadius(12)
  }
}

private struct RightsSection: View {
  let title: String
  var period: String = ""
  let items: [ServiceRightItem]

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 4) {
        Text(title)
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(Color(hex: "0x222222"))
          .padding(.leading, 16)

        if !period.isEmpty {
          Text("(有效期\(period))")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x777777"))
        }
      }

      VStack(spacing: 0) {
        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
          HStack(alignment: .top, spacing: 12) {
            ZStack {
              Circle()
                .fill(Color(hex: "0xEEF1F4"))
                .frame(width: 38, height: 38)
              Image(item.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
            }

            VStack(alignment: .leading, spacing: 4) {
              Text(item.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "0x222222"))
              Text(item.desc)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "0x888888"))
                .lineLimit(2)
            }
            Spacer(minLength: 0)
          }
          .padding(.vertical, 12)

          if index != items.count - 1 {
            Divider().padding(.leading, 50)
          }
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(Color.white)
      .cornerRadius(12)
    }
  }
}

extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
