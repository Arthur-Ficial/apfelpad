import SwiftUI
import UniformTypeIdentifiers

struct FormulaCatalogueSidebarView: View {
    @Bindable var vm: FormulaCatalogueSidebarViewModel

    // Visual palette (matches apfelpad's pale/dark green identity)
    private static let paleGreen = Color(red: 0.94, green: 0.98, blue: 0.93)
    private static let darkGreen = Color(red: 0.16, green: 0.49, blue: 0.22)
    private static let panelBg   = Color(white: 0.97)
    private static let rowHover  = Color(red: 0.90, green: 0.96, blue: 0.89)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchField
            Divider()
            if vm.totalVisibleCount == 0 {
                emptyState
            } else {
                list
            }
        }
        .frame(width: 340)
        .background(Self.panelBg)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.separator),
            alignment: .leading
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Formulas")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Self.darkGreen)
            Spacer()
            Text("\(vm.totalVisibleCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Button {
                vm.close()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Close formula catalogue")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search formulas…", text: $vm.searchQuery)
                .textFieldStyle(.plain)
                .font(.body)
            if !vm.searchQuery.isEmpty {
                Button {
                    vm.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(vm.visibleSections) { section in
                    Section {
                        ForEach(section.entries) { entry in
                            row(entry)
                        }
                    } header: {
                        sectionHeader(section.category)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ category: FormulaCatalogueEntry.Category) -> some View {
        Text(category.title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 6)
            .background(Self.panelBg)
    }

    private func row(_ entry: FormulaCatalogueEntry) -> some View {
        Button {
            vm.insert(entry)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.signature)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Self.darkGreen)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.down.right.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(entry.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                // Pale-green preview of the example
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Self.darkGreen)
                        .frame(width: 2)
                    Text(entry.example)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Self.darkGreen)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                }
                .background(Self.paleGreen)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Insert \(entry.name)")
        .accessibilityHint(entry.description)
        .help("Click to insert \(entry.signature) · drag to drop it into the document")
        .draggable(entry.example) {
            Text(entry.example)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Self.darkGreen)
                .padding(6)
                .background(Self.paleGreen)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator),
            alignment: .bottom
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No formulas match \"\(vm.searchQuery)\"")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Clear search") {
                vm.searchQuery = ""
            }
            .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
