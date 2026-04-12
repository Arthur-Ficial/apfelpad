import SwiftUI
import MarkdownUI

/// Renders a Document in "form mode":
///   - Non-formula prose is rendered as full markdown via MarkdownUI —
///     headings, tables, lists, code blocks, quotes, horizontal rules.
///   - Every =input span becomes a live InputFieldView that re-evaluates
///     every dependent formula (@name references) as the user types.
///
/// Formula values are spliced into the raw markdown before it hits MarkdownUI:
/// `=math(365*24)` becomes `` `8760` `` — an inline-code span. The
/// `formulaTheme` then styles inline code in pale green so the spans keep
/// their signature look even though the surrounding prose now flows through
/// a real markdown renderer.
struct DocumentBodyView: View {
    @Bindable var vm: DocumentViewModel

    private static let paleGreen = Color(red: 0.94, green: 0.98, blue: 0.93)
    private static let darkGreen = Color(red: 0.16, green: 0.49, blue: 0.22)
    private static let errorBg   = Color(red: 0.99, green: 0.93, blue: 0.93)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(paragraphs, id: \.id) { paragraph in
                    row(for: paragraph)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .dropDestination(for: String.self) { items, _ in
            for item in items { vm.insertAtCursor(item) }
            return !items.isEmpty
        }
    }

    // MARK: - Paragraph decomposition

    private struct Paragraph: Identifiable {
        let id: Int
        enum Kind { case prose(text: String), input(span: FormulaSpan) }
        let kind: Kind
    }

    /// Walk the document, splitting on =input spans. Prose chunks get the
    /// evaluated-value substitution applied before MarkdownUI renders them.
    private var paragraphs: [Paragraph] {
        let ns = vm.rawText as NSString
        let total = ns.length
        var out: [Paragraph] = []
        var cursor = 0
        var nextID = 0

        let inputSpans = vm.document.spans.filter {
            if case .input = $0.call { return true }
            return false
        }.sorted { $0.range.lowerBound < $1.range.lowerBound }

        func appendProse(_ upper: Int) {
            guard upper > cursor else { return }
            let loc = cursor
            let len = upper - cursor
            guard loc >= 0, loc + len <= ns.length else { return }
            let slice = ns.substring(with: NSRange(location: loc, length: len))
            let substituted = DocumentBodySubstitution.substitute(
                slice: slice,
                sliceStart: loc,
                spans: vm.document.spans
            )
            out.append(Paragraph(id: nextID, kind: .prose(text: substituted)))
            nextID += 1
        }

        for span in inputSpans {
            appendProse(span.range.lowerBound)
            out.append(Paragraph(id: nextID, kind: .input(span: span)))
            nextID += 1
            cursor = span.range.upperBound
        }
        appendProse(total)
        if out.isEmpty {
            out.append(Paragraph(id: 0, kind: .prose(text: "")))
        }
        return out
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for paragraph: Paragraph) -> some View {
        switch paragraph.kind {
        case .prose(let text):
            Markdown(text)
                .markdownTheme(Self.formulaTheme)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .input(let span):
            inputRow(span)
        }
    }

    private func inputRow(_ span: FormulaSpan) -> some View {
        guard case .input(let name, let type, let defaultValue) = span.call else {
            return AnyView(EmptyView())
        }
        return AnyView(
            InputRow(
                vm: vm,
                name: name,
                type: type,
                defaultValue: defaultValue
            )
        )
    }

    // MARK: - Theme

    /// MarkdownUI theme that paints inline code spans pale green / dark green
    /// and removes the default link underline so clickable formulas keep
    /// their signature look. Everything else inherits default MarkdownUI
    /// styling (headings, tables, lists, blockquotes, code blocks).
    private static let formulaTheme: Theme = Theme()
        .text {
            FontSize(14)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.95))
            ForegroundColor(darkGreen)
            BackgroundColor(paleGreen)
        }
        .link {
            ForegroundColor(darkGreen)
            UnderlineStyle(.init(pattern: .solid, color: .clear))
        }
        .table { configuration in
            configuration.label
                .markdownTableBorderStyle(.init(color: Color(white: 0.85)))
                .markdownTableBackgroundStyle(
                    .alternatingRows(Color.white, Color(white: 0.97))
                )
        }
}

/// One live input row. Owns its own @State text so typing doesn't thrash
/// the document VM on every character; commits on every change via the
/// reactive binding path.
private struct InputRow: View {
    @Bindable var vm: DocumentViewModel
    let name: String
    let type: InputType
    let defaultValue: String?

    @State private var text: String = ""
    @State private var isInitialised: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Label("\(name):", systemImage: "function")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 80, alignment: .leading)
            InputFieldView(name: name, type: type, value: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    vm.setInputBinding(name, to: newValue)
                }
            ))
            .frame(maxWidth: 280)
            Spacer()
        }
        .padding(.vertical, 4)
        .onAppear {
            if !isInitialised {
                text = vm.bindings.value(for: name) ?? defaultValue ?? ""
                if !text.isEmpty, vm.bindings.value(for: name) == nil {
                    vm.setInputBinding(name, to: text)
                }
                isInitialised = true
            }
        }
    }
}
