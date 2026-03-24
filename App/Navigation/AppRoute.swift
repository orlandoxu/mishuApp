struct RouteParam: Hashable {
  let key: String
  let value: String
}

enum RoutePresentation: String, Hashable, CaseIterable {
  case push
  case sheet
  case fullScreen
}

enum AppRoute: Hashable {
  case page(path: String, params: [RouteParam], presentation: RoutePresentation)
}

struct RouteDescriptor: Identifiable, Hashable {
  let title: String
  let module: String
  let flutterPage: String
  let path: String
  let suggestedParams: [String]

  var id: String {
    "\(path)|\(flutterPage)"
  }
}

enum RouteCatalog {
  static let all: [RouteDescriptor] = [
    RouteDescriptor(title: "start_page", module: "Main", flutterPage: "start_page", path: "/main/start", suggestedParams: []),
    RouteDescriptor(title: "main_tab", module: "Main", flutterPage: "main_tab", path: "/main/tab", suggestedParams: ["tab"]),

    RouteDescriptor(title: "login", module: "Login", flutterPage: "login", path: "/login/index", suggestedParams: []),
    RouteDescriptor(title: "telephone_login", module: "Login", flutterPage: "telephone_login", path: "/login/telephone", suggestedParams: ["phone", "zone"]),
    RouteDescriptor(title: "telephone_auto_login", module: "Login", flutterPage: "telephone_auto_login", path: "/login/telephone_auto", suggestedParams: ["phone"]),
    RouteDescriptor(title: "telephone_banding", module: "Login", flutterPage: "telephone_banding", path: "/login/telephone_bind", suggestedParams: ["phone"]),
    RouteDescriptor(title: "phone_zone_dialog", module: "Login", flutterPage: "phone_zone_dialog", path: "/login/zone_dialog", suggestedParams: []),

    RouteDescriptor(title: "home", module: "Home", flutterPage: "home", path: "/home/index", suggestedParams: []),
    RouteDescriptor(title: "home_detail", module: "Home", flutterPage: "home_detail", path: "/home/detail", suggestedParams: ["id"]),

    RouteDescriptor(title: "album", module: "Album", flutterPage: "album", path: "/album/index", suggestedParams: []),
    RouteDescriptor(title: "album_detail", module: "Album", flutterPage: "album_detail", path: "/album/detail", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_detail_new", module: "Album", flutterPage: "album_detail_new", path: "/album/detail_new", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_img", module: "Album", flutterPage: "album_img", path: "/album/img", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_list_detail", module: "Album", flutterPage: "album_list_detail", path: "/album/list_detail", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_list_map", module: "Album", flutterPage: "album_list_map", path: "/album/list_map", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_list_map_detail", module: "Album", flutterPage: "album_list_map_detail", path: "/album/list_map_detail", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_list_yun", module: "Album", flutterPage: "album_list_yun", path: "/album/list_cloud", suggestedParams: []),
    RouteDescriptor(title: "album_live_history", module: "Album", flutterPage: "album_live_history", path: "/album/live_history", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_local", module: "Album", flutterPage: "album_local", path: "/album/local", suggestedParams: []),
    RouteDescriptor(title: "album_map", module: "Album", flutterPage: "album_map", path: "/album/map", suggestedParams: []),
    RouteDescriptor(title: "album_map_detail", module: "Album", flutterPage: "album_map_detail", path: "/album/map_detail", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_video", module: "Album", flutterPage: "album_video", path: "/album/video", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_yun_detail", module: "Album", flutterPage: "album_yun_detail", path: "/album/cloud_detail", suggestedParams: ["id"]),
    RouteDescriptor(title: "album_yun_query", module: "Album", flutterPage: "album_yun_query", path: "/album/cloud_query", suggestedParams: ["query"]),
    RouteDescriptor(title: "FijkWidgetBottom", module: "Album", flutterPage: "FijkWidgetBottom", path: "/album/fijk_bottom", suggestedParams: []),

    RouteDescriptor(title: "equipment", module: "Equipment", flutterPage: "equipment", path: "/equipment/index", suggestedParams: []),
    RouteDescriptor(title: "equipment_wifi_bind", module: "Equipment", flutterPage: "equipment_wifi_bind", path: "/equipment/wifi_bind", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "equipment_wifi_direct", module: "Equipment", flutterPage: "equipment_wifi_direct", path: "/equipment/wifi_direct", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "equipment_limit_wifi_bind", module: "Equipment", flutterPage: "equipment_limit_wifi_bind", path: "/equipment/wifi_bind_limited", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "equipment_video_test", module: "Equipment", flutterPage: "equipment_video_test", path: "/equipment/video_test", suggestedParams: ["deviceId"]),
    // DONE-AI: 这些路由还是要改一下，要优化一下。路由里面，怎么能够有中文呢！这肯定是不允许的啊
    RouteDescriptor(title: "qrcode_vin_flow", module: "Equipment", flutterPage: "qrcode_vin_flow", path: "/equipment/qrcode", suggestedParams: ["vin", "qrcode"]),
    RouteDescriptor(title: "vehicle_live_view", module: "Equipment", flutterPage: "vehicle_live_view", path: "/equipment/vehicle_live", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "device_settings", module: "Equipment", flutterPage: "device_settings", path: "/equipment/settings", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "setting_gps", module: "Equipment", flutterPage: "setting_gps", path: "/equipment/setting_gps", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "setting_voice", module: "Equipment", flutterPage: "setting_voice", path: "/equipment/setting_voice", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "tcard", module: "Equipment", flutterPage: "tcard", path: "/equipment/tcard", suggestedParams: ["deviceId"]),

    RouteDescriptor(title: "trip", module: "Trip", flutterPage: "trip", path: "/trip/index", suggestedParams: []),
    RouteDescriptor(title: "trip_detal", module: "Trip", flutterPage: "trip_detal", path: "/trip/detail", suggestedParams: ["id"]),
    RouteDescriptor(title: "trip_map", module: "Trip", flutterPage: "trip_map", path: "/trip/map", suggestedParams: ["id"]),
    RouteDescriptor(title: "trip_rank", module: "Trip", flutterPage: "trip_rank", path: "/trip/rank", suggestedParams: []),
    RouteDescriptor(title: "trip_track_map", module: "Trip", flutterPage: "trip_track_map", path: "/trip/track_map", suggestedParams: ["id"]),
    RouteDescriptor(title: "stop_car_list", module: "Trip", flutterPage: "stop_car_list", path: "/trip/stop_car_list", suggestedParams: []),
    RouteDescriptor(title: "trip_stop_car_detail", module: "Trip", flutterPage: "trip_stop_car_detail", path: "/trip/stop_car_detail", suggestedParams: ["id"]),
    RouteDescriptor(title: "car_condition", module: "Trip", flutterPage: "car_condition", path: "/trip/car_condition", suggestedParams: ["carId"]),
    RouteDescriptor(title: "trip_components", module: "Trip", flutterPage: "trip_components", path: "/trip/components", suggestedParams: []),

    RouteDescriptor(title: "obd_apply_entire_check", module: "OBD", flutterPage: "obd_apply_entire_check", path: "/obd/apply_entire_check", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "obd_check_prepare", module: "OBD", flutterPage: "obd_check_prepare", path: "/obd/check_prepare", suggestedParams: ["deviceId"]),
    RouteDescriptor(title: "obd_entire_check", module: "OBD", flutterPage: "obd_entire_check", path: "/obd/entire_check", suggestedParams: ["taskId"]),
    RouteDescriptor(title: "obd_examined_report", module: "OBD", flutterPage: "obd_examined_report", path: "/obd/examined_report", suggestedParams: ["reportId"]),
    RouteDescriptor(title: "obd_exception_report", module: "OBD", flutterPage: "obd_exception_report", path: "/obd/exception_report", suggestedParams: ["reportId"]),
    RouteDescriptor(title: "obd_report_list", module: "OBD", flutterPage: "obd_report_list", path: "/obd/report_list", suggestedParams: []),
    RouteDescriptor(title: "obd_check_detail", module: "OBD", flutterPage: "obd_check_detail", path: "/obd/check_detail", suggestedParams: ["reportId"]),
    RouteDescriptor(title: "obd_battery_state", module: "OBD", flutterPage: "obd_battery_state", path: "/obd/battery_state", suggestedParams: ["reportId"]),
    RouteDescriptor(title: "obd_fuel_state", module: "OBD", flutterPage: "obd_fuel_state", path: "/obd/fuel_state", suggestedParams: ["reportId"]),
    RouteDescriptor(title: "obd_sensor_state", module: "OBD", flutterPage: "obd_sensor_state", path: "/obd/sensor_state", suggestedParams: ["reportId"]),
    RouteDescriptor(title: "obd_throttle_state", module: "OBD", flutterPage: "obd_throttle_state", path: "/obd/throttle_state", suggestedParams: ["reportId"]),

    RouteDescriptor(title: "me", module: "Me", flutterPage: "me", path: "/me/index", suggestedParams: []),
    RouteDescriptor(title: "new_me", module: "Me", flutterPage: "new_me", path: "/me/index_new", suggestedParams: []),
    RouteDescriptor(title: "about", module: "Me", flutterPage: "about", path: "/me/about", suggestedParams: []),
    RouteDescriptor(title: "setting", module: "Me", flutterPage: "setting", path: "/me/setting", suggestedParams: []),
    RouteDescriptor(title: "me_setting", module: "Me", flutterPage: "me_setting", path: "/me/me_setting", suggestedParams: []),
    RouteDescriptor(title: "permission_setting", module: "Me", flutterPage: "permission_setting", path: "/me/permission_setting", suggestedParams: []),
    RouteDescriptor(title: "notice_setting", module: "Me", flutterPage: "notice_setting", path: "/me/notice_setting", suggestedParams: []),
    RouteDescriptor(title: "edit_user_info", module: "Me", flutterPage: "edit_user_info", path: "/me/edit_user", suggestedParams: []),
    RouteDescriptor(title: "edit_car_info", module: "Me", flutterPage: "edit_car_info", path: "/me/edit_car", suggestedParams: ["carId"]),
    RouteDescriptor(title: "edit_car_choose_car", module: "Me", flutterPage: "edit_car_choose_car", path: "/me/edit_car_choose", suggestedParams: []),
    RouteDescriptor(title: "edit_car_lisence_number", module: "Me", flutterPage: "edit_car_lisence_number", path: "/me/edit_car_license", suggestedParams: ["carId"]),
    RouteDescriptor(title: "perfect_car_info", module: "Me", flutterPage: "perfect_car_info", path: "/me/perfect_car", suggestedParams: ["carId"]),
    RouteDescriptor(title: "me_vip", module: "Me", flutterPage: "me_vip", path: "/me/vip", suggestedParams: []),
    RouteDescriptor(title: "order", module: "Me", flutterPage: "order", path: "/me/order", suggestedParams: []),
    RouteDescriptor(title: "order_item", module: "Me", flutterPage: "order_item", path: "/me/order_item", suggestedParams: ["id"]),
    RouteDescriptor(title: "gift", module: "Me", flutterPage: "gift", path: "/me/gift", suggestedParams: []),
    RouteDescriptor(title: "new_gift", module: "Me", flutterPage: "new_gift", path: "/me/gift_new", suggestedParams: []),
    RouteDescriptor(title: "packages_orders", module: "Me", flutterPage: "packages_orders", path: "/me/packages_orders", suggestedParams: []),

    RouteDescriptor(title: "police", module: "Police", flutterPage: "police", path: "/police/index", suggestedParams: []),
    RouteDescriptor(title: "police_detail", module: "Police", flutterPage: "police_detail", path: "/police/detail", suggestedParams: ["id"]),

    RouteDescriptor(title: "base_web", module: "Web", flutterPage: "base_web", path: "/web/base", suggestedParams: ["url"]),
    RouteDescriptor(title: "web", module: "Web", flutterPage: "web", path: "/web/index", suggestedParams: ["url"]),
    RouteDescriptor(title: "inappwebview_web", module: "Web", flutterPage: "inappwebview_web", path: "/web/inapp", suggestedParams: ["url"]),
  ]
}
