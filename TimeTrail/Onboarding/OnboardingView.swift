import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        WelcomeView(onContinue: onComplete)
    }
}
