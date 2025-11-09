import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, DesignSystem.Spacing.m)
      .padding(.vertical, DesignSystem.Spacing.s)
      .frame(minHeight: DesignSystem.Sizing.minTapHeight)
      .background(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard, style: .continuous)
          .fill(backgroundColor(for: configuration))
      )
      .foregroundStyle(Color.white)
      .contentShape(Rectangle())
      .controlSize(.large)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
      .opacity(isEnabled ? 1 : 0.5)
      .accessibilityAddTraits(.isButton)
  }

  private func backgroundColor(for configuration: Configuration) -> Color {
    let base = Color.accentColor
    return configuration.isPressed ? base.opacity(0.85) : base
  }
}

struct SecondaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    let borderColor = Color.accentColor.opacity(isEnabled ? 1 : 0.4)

    return configuration.label
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, DesignSystem.Spacing.m)
      .padding(.vertical, DesignSystem.Spacing.s)
      .frame(minHeight: DesignSystem.Sizing.minTapHeight)
      .background(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard, style: .continuous)
          .stroke(borderColor, lineWidth: 1)
      )
      .foregroundStyle(Color.accentColor)
      .contentShape(Rectangle())
      .controlSize(.large)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
      .opacity(isEnabled ? 1 : 0.6)
      .accessibilityAddTraits(.isButton)
  }
}
