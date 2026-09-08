import SwiftUI

struct OnboardingView: View {
    @StateObject private var checker = AccessibilityPermissionChecker()
    @State private var step: Step = .welcome

    let onComplete: () -> Void
    var onStepChange: (String) -> Void = { _ in }

    private enum Step { case welcome, accessibility }

    private func title(for step: Step) -> String {
        switch step {
        case .welcome: return "Welcome to TimeTrail"
        case .accessibility: return "Accessibility Access"
        }
    }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                WelcomeView(onContinue: { step = .accessibility })
            case .accessibility:
                AccessibilityPermissionView(checker: checker, onContinue: onComplete)
            }
        }
        .onAppear {
            onStepChange(title(for: step))
        }
        .onChange(of: step) { newStep in
            onStepChange(title(for: newStep))
        }
    }
}
