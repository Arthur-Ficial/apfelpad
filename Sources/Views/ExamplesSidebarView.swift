import SwiftUI

struct ExamplesSidebarView: View {
    @Bindable var vm: ExamplesSidebarViewModel

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
        .frame(width: 300)
        .background(AppTheme.chromeBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.separator),
            alignment: .leading
        )
    }

    private var header: some View {
        HStack {
            Text("Examples")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AppTheme.formulaAccent)
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
            .help("Close examples library")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search examples…", text: $vm.searchQuery)
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

    private func sectionHeader(_ category: ExampleDocument.Category) -> some View {
        Text(category.title)
            .font(.caption.weight(.semibold))
            .tracking(1)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 6)
            .background(AppTheme.chromeBackground)
    }

    private func row(_ entry: ExampleDocument) -> some View {
        Button {
            vm.load(entry)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                // Issue #21: tiny pre-rendered thumbnail replaces the SF
                // Symbol so users see a glimpse of the example's body
                // content. Cached on disk, invalidated on version bump.
                Image(nsImage: vm.thumbnailGenerator.thumbnail(
                    for: entry,
                    size: NSSize(width: 60, height: 40)
                ))
                .resizable()
                .frame(width: 60, height: 40)
                .cornerRadius(4)
                .padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(entry.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.title)
        .accessibilityHint(entry.blurb)
        .help("Load \"\(entry.title)\" — replaces the current document")
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator),
            alignment: .bottom
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No examples match \"\(vm.searchQuery)\"")
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
