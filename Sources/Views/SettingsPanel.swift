import SwiftUI

struct SettingsPanel: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Form {
            Section("Editor") {
                Toggle("Show line count in the status strip", isOn: $vm.showLineCount)
            }
            Section("Updates") {
                Toggle("Check for updates on launch", isOn: $vm.checkOnLaunch)
                HStack {
                    statusView
                    Spacer()
                    Button("Check now") {
                        Task { await vm.checkForUpdate() }
                    }
                }
                HStack {
                    Text("Current version")
                    Spacer()
                    Text(vm.currentVersion).foregroundStyle(.secondary)
                }
            }
            Section("Privacy") {
                Text("apfelpad makes one network call: an optional check against api.github.com for new releases. All inference runs on your Mac via apfel. No telemetry.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    @ViewBuilder
    private var statusView: some View {
        switch vm.updateState {
        case .idle:
            Text("").foregroundStyle(.secondary)
        case .checking:
            ProgressView().controlSize(.small)
        case .upToDate:
            Label("Up to date", systemImage: "checkmark.circle")
                .foregroundStyle(AppTheme.formulaAccent)
        case .updateAvailable(let latest):
            Label("\(latest) available", systemImage: "arrow.up.circle")
                .foregroundStyle(AppTheme.formulaAccent)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(AppTheme.errorAccent)
        }
    }
}
