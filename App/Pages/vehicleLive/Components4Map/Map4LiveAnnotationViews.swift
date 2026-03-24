import MAMapKit
import UIKit

// Map4Live 的车辆/用户标注视图与标注类型定义

final class Map4LiveCarAnnotationView: MAAnnotationView {
  private static let onlineCarImage = UIImage(named: "icon_map_car")
  private static let offlineCarImage = UIImage(named: "icon_map_car_offline")
  private static let defaultStatusImage = UIImage(named: "icon_status_offline")

  private let badgeView = UIView()
  private let badgeLabel = UILabel()
  private let statusImageView = UIImageView()
  private let carImageView = UIImageView()
  private let contentStack = UIStackView()
  private var lastIsOnline: Bool?
  private var lastStatusIconName: String?
  private var lastStatusDescription: String?
  private var lastStatusColor: UIColor?

  override init(annotation: MAAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    setupView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }

  func updateHeading(_ heading: Double?) {
    // Step 1. 根据车辆航向旋转车辆图标（无航向则复位）
    if let heading {
      let radians = CGFloat(heading / 180.0 * Double.pi)
      carImageView.transform = CGAffineTransform(rotationAngle: radians)
    } else {
      carImageView.transform = .identity
    }
  }

  func updateStatus(iconName: String?, description: String?, color: UIColor?) {
    // Step 1. 防止重复刷新（同一状态不重复写 UI）
    if lastStatusIconName == iconName, lastStatusDescription == description, lastStatusColor == color { return }
    lastStatusIconName = iconName
    lastStatusDescription = description
    lastStatusColor = color

    // Step 2. 设置状态图标（找不到则使用默认图标）
    statusImageView.image = UIImage(named: iconName ?? "") ?? Self.defaultStatusImage
    statusImageView.isHidden = statusImageView.image == nil

    // Step 3. 设置状态文案与边框颜色（无文案则隐藏 badge）
    badgeLabel.text = description
    if let color {
      badgeLabel.textColor = color
      badgeView.layer.borderColor = color.cgColor
    }
    let hasDescription = !(description?.isEmpty ?? true)
    badgeView.isHidden = !hasDescription

    accessibilityLabel = description
  }

  func updateOnlineStatus(_ onlineStatus: Int?) {
    // Step 1. 将业务在线状态映射到是否在线（1/2/7 视为在线）
    let isOnline = onlineStatus == 1 || onlineStatus == 2 || onlineStatus == 7
    if lastIsOnline == isOnline { return }
    lastIsOnline = isOnline

    // Step 2. 根据是否在线切换车辆图标（在线/离线）
    if isOnline {
      carImageView.image = Self.onlineCarImage ?? Self.offlineCarImage
    } else {
      carImageView.image = Self.offlineCarImage ?? Self.onlineCarImage
    }
  }

  private func setupView() {
    // Step 1. 初始化车辆图标（在线状态由后续 updateOnlineStatus 驱动）
    updateOnlineStatus(nil)
    carImageView.contentMode = .scaleAspectFit

    // Step 2. 初始化状态 UI（图标 + 文案）
    updateStatus(iconName: nil, description: nil, color: nil)
    statusImageView.contentMode = .scaleAspectFit

    // Step 3. 配置 badge 样式
    badgeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    badgeLabel.textAlignment = .center
    badgeLabel.numberOfLines = 1

    badgeView.backgroundColor = .white
    badgeView.layer.cornerRadius = 12
    badgeView.layer.borderWidth = 1
    badgeView.layer.borderColor = ThemeColor.gray600Ui.cgColor
    badgeView.clipsToBounds = true

    // Step 4. AutoLayout 配置
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false
    badgeView.translatesAutoresizingMaskIntoConstraints = false
    statusImageView.translatesAutoresizingMaskIntoConstraints = false
    carImageView.translatesAutoresizingMaskIntoConstraints = false
    contentStack.translatesAutoresizingMaskIntoConstraints = false

    badgeView.addSubview(badgeLabel)
    NSLayoutConstraint.activate([
      badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 12),
      badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -12),
      badgeLabel.topAnchor.constraint(equalTo: badgeView.topAnchor, constant: 4),
      badgeLabel.bottomAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: -4),
      badgeView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
    ])

    // Step 5. 布局层级：badge -> status -> car（竖向堆叠）
    contentStack.axis = .vertical
    contentStack.alignment = .center
    contentStack.spacing = 2
    contentStack.addArrangedSubview(badgeView)
    contentStack.addArrangedSubview(statusImageView)
    contentStack.addArrangedSubview(carImageView)
    // DONE-AI: 这个东西，不需要响应手势，否则的话，会导致手势不丝滑
    contentStack.isUserInteractionEnabled = false
    addSubview(contentStack)

    // Step 6. 约束与尺寸
    NSLayoutConstraint.activate([
      contentStack.topAnchor.constraint(equalTo: topAnchor),
      contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
      contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),

      statusImageView.widthAnchor.constraint(equalToConstant: 62),
      statusImageView.heightAnchor.constraint(equalToConstant: 62),
      carImageView.widthAnchor.constraint(equalToConstant: 32),
      carImageView.heightAnchor.constraint(equalToConstant: 53),
    ])

    // Step 7. 设定标注视图尺寸与中心点偏移（底部对齐）
    bounds = CGRect(x: 0, y: 0, width: 120, height: 150)
    centerOffset = CGPoint(x: 0, y: -75)
  }
}

final class LiveVehiclePointAnnotation: MAPointAnnotation {}
final class LiveUserPointAnnotation: MAPointAnnotation {}

final class Map4LiveUserAnnotationView: MAAnnotationView {
  private static let userImage = UIImage(named: "icon_map_user")
  private let userImageView = UIImageView()

  override init(annotation: MAAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    setupView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }

  func updateHeading(_ heading: Double?) {
    // Step 1. 根据用户朝向旋转用户图标（无效朝向则复位）
    if let heading, heading >= 0 {
      let radians = CGFloat(heading / 180.0 * Double.pi)
      userImageView.transform = CGAffineTransform(rotationAngle: radians)
    } else {
      userImageView.transform = .identity
    }
  }

  private func setupView() {
    // Step 1. 初始化用户图标
    userImageView.image = Self.userImage
    userImageView.contentMode = .scaleAspectFit
    userImageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(userImageView)

    // Step 2. 约束铺满
    NSLayoutConstraint.activate([
      userImageView.topAnchor.constraint(equalTo: topAnchor),
      userImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
      userImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      userImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])

    // Step 3. 尺寸与中心点偏移（底部对齐）
    bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
    centerOffset = CGPoint(x: 0, y: -22)
  }
}
