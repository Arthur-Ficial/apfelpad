import SwiftUI

struct UpdateBanner: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        if case .updateAvailable(let latest) = vm.updateState, !vm.sessionDismissedBanner {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(AppTheme.formulaAccent)
                Text("apfelpad \(latest) is available. Install via `brew upgrade apfelpad` or download from GitHub.")
                    .font(.callout)
                Spacer()
                Button("Dismiss") {
                    vm.sessionDismissedBanner = true
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.formulaBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(AppTheme.noticeBorder),
                alignment: .bottom
            )
        }
    }
}
