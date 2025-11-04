import SwiftUI

struct BottomCTA<Content: View, Actions: View>: View {
  private let content: Content
  private let actions: Actions

  init(@ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) {
    self.content = content()
    self.actions = actions()
  }

  var body: some View {
    VStack(spacing: 0) {
      content
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .safeAreaInset(edge: .bottom) {
      VStack(spacing: DesignSystem.Spacing.s) {
        actions
      }
      .padding(.horizontal, DesignSystem.Sizing.horizontalPadding)
      .padding(.top, DesignSystem.Spacing.m)
      .padding(.bottom, DesignSystem.Spacing.m)
      .frame(maxWidth: .infinity)
      .background(.ultraThinMaterial)
      .overlay(alignment: .top) {
        Divider()
      }
    }
  }
}
