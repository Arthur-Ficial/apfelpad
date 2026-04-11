import SwiftUI

struct UpdateBanner: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        if case .updateAvailable(let latest) = vm.updateState, !vm.sessionDismissedBanner {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(Color(red: 0.16, green: 0.49, blue: 0.22))
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
            .background(Color(red: 0.94, green: 0.98, blue: 0.93))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color(red: 0.16, green: 0.49, blue: 0.22).opacity(0.3)),
                alignment: .bottom
            )
        }
    }
}
