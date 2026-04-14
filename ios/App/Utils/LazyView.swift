import SwiftUI

/**
 * LazyView的背景
 * 1. 背景：NavigationLink 有一个大问题，目标视图立即创建（不会等到事件触发）
 * 2. 原理：目标视图虽然立即创建，但因为只会加载第一个层，所以我们可以通过这个LazyView来延迟加载
 * 3. 附加问题：
 */

struct LazyView<Content: View>: View {
  let content: () -> Content

  var body: some View { content() }
}
