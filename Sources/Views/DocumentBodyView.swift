import SwiftUI

/// Renders a Document as a flow of paragraphs where:
///   - Non-formula prose is a Text view with inline formula spans rendered
///     in pale green (via InlineFormulaRenderer)
///   - Every =input span becomes a live InputFieldView — typing into it
///     calls DocumentViewModel.setInputBinding which re-evaluates every
///     formula that references @name
///
/// This is the "form mode" of Markdown editing — users see and interact
/// with real form fields inline, and every dependent formula recomputes
/// live.
struct DocumentBodyView: View {
    @Bindable var vm: DocumentViewModel

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

    /// One visual line/paragraph in the body. Either plain prose (possibly
    /// containing non-input formula spans) or an =input declaration.
    private struct Paragraph: Identifiable {
        let id: Int
        enum Kind { case prose(range: Range<Int>), input(span: FormulaSpan, range: Range<Int>) }
        let kind: Kind
    }

    /// Walk the document, splitting on =input spans. Each =input span
    /// becomes its own paragraph; everything else is grouped into the
    /// surrounding prose paragraphs.
    private var paragraphs: [Paragraph] {
        let raw = vm.rawText
        let ns = raw as NSString
        let total = ns.length
        var out: [Paragraph] = []
        var cursor = 0
        var nextID = 0

        let inputSpans = vm.document.spans.filter {
            if case .input = $0.call { return true }
            return false
        }.sorted { $0.range.lowerBound < $1.range.lowerBound }

        for span in inputSpans {
            if span.range.lowerBound > cursor {
                out.append(Paragraph(
                    id: nextID,
                    kind: .prose(range: cursor..<span.range.lowerBound)
                ))
                nextID += 1
            }
            out.append(Paragraph(
                id: nextID,
                kind: .input(span: span, range: span.range)
            ))
            nextID += 1
            cursor = span.range.upperBound
        }
        if cursor < total {
            out.append(Paragraph(
                id: nextID,
                kind: .prose(range: cursor..<total)
            ))
        }
        if out.isEmpty {
            out.append(Paragraph(id: 0, kind: .prose(range: 0..<0)))
        }
        return out
    }

    @ViewBuilder
    private func row(for paragraph: Paragraph) -> some View {
        switch paragraph.kind {
        case .prose(let range):
            let sub = proseDocument(slicing: range)
            Text(InlineFormulaRenderer.render(sub))
                .font(.body)
                .lineSpacing(6)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .input(let span, _):
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

    /// Build a mini-document covering a sub-range of the raw text so the
    /// InlineFormulaRenderer can render inline formula spans correctly
    /// within a single paragraph.
    private func proseDocument(slicing range: Range<Int>) -> Document {
        let ns = vm.rawText as NSString
        let loc = max(0, range.lowerBound)
        let len = max(0, range.upperBound - range.lowerBound)
        let safeLen = max(0, min(ns.length - loc, len))
        let sub = ns.substring(with: NSRange(location: loc, length: safeLen))
        // Build a fresh Document from the sub-text. Span indices are
        // relative to the sub-text, which is what we want.
        let doc = (try? Document(rawMarkdown: sub)) ?? .empty
        // Carry over evaluated values from the parent document so the
        // prose rows show "8760" instead of "=math(365*24)". If the same
        // formula appears twice in the same paragraph, keep the most
        // recent successful value — never crash on duplicates.
        let parentBySource = Dictionary(
            vm.document.spans.map { ($0.source, $0.value) },
            uniquingKeysWith: { _, b in b }
        )
        var merged = doc
        for i in merged.spans.indices {
            if let v = parentBySource[merged.spans[i].source] {
                merged.spans[i].value = v
            }
        }
        return merged
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
