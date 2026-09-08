import SwiftUI

struct OnboardingView: View {
    @StateObject private var checker = AccessibilityPermissionChecker()
    @State private var step: Step = .welcome

    let onComplete: () -> Void

    private enum Step { case welcome, accessibility }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                WelcomeView(onContinue: { step = .accessibility })
            case .accessibility:
                AccessibilityPermissionView(checker: checker, onContinue: onComplete)
            }
        }
    }
}
