import SwiftUI
import AppKit

/// Shared editor surface for both Source and Render. Source edits the exact
/// markdown bytes. Render shows a projected view of the same markdown, with
/// atomic formula chips and live =input widgets anchored into the same
/// NSTextView.
struct EditableMarkdownView: NSViewRepresentable {
    @Binding var text: String
    let document: Document
    let documentGeneration: Int
    let mode: EditingMode
    let focusToken: Int
    let focusedInputName: String?
    let inputFocusToken: Int
    var inputValue: ((String) -> String?)? = nil
    var onInputChange: ((String, String) -> Void)? = nil
    var onSelectionChange: ((Int) -> Void)? = nil
    var onFormulaActivate: ((FormulaSpan) -> Void)? = nil

    private static let paleGreen = NSColor(red: 0.94, green: 0.98, blue: 0.93, alpha: 1)
    private static let darkGreen = NSColor(red: 0.16, green: 0.49, blue: 0.22, alpha: 1)
    private static let errorBg = NSColor(red: 0.99, green: 0.93, blue: 0.93, alpha: 1)

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = FormulaTextView.makeScrollable()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false

        guard let textView = scroll.documentView as? FormulaTextView else { return scroll }
        textView.isEditable = true
        textView.isRichText = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.usesFindBar = true
        textView.registerForDraggedTypes([.string, .URL])
        textView.delegate = context.coordinator
        textView.formulaCoordinator = context.coordinator
        textView.linkTextAttributes = [
            .foregroundColor: Self.darkGreen,
            .underlineStyle: 0,
        ]

        context.coordinator.textView = textView
        context.coordinator.parent = self
        applyState(to: textView, coordinator: context.coordinator)
        return scroll
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? FormulaTextView else { return }
        context.coordinator.parent = self
        applyState(to: textView, coordinator: context.coordinator)
    }

    private func applyState(to textView: NSTextView, coordinator: Coordinator) {
        switch mode {
        case .source:
            applySourceState(to: textView, coordinator: coordinator)
        case .render:
            applyRenderState(to: textView, coordinator: coordinator)
        }
        textView.setAccessibilityIdentifier("apfelpad.editor.\(mode.rawValue.lowercased())")
        requestFocusIfNeeded(for: textView, coordinator: coordinator)
        requestInputFocusIfNeeded(in: textView, coordinator: coordinator)
    }

    private func applySourceState(to textView: NSTextView, coordinator: Coordinator) {
        coordinator.currentProjection = nil
        clearInputWidgets(from: textView, coordinator: coordinator)
        let textChanged = textView.string != text
        if textChanged {
            let selected = textView.selectedRange()
            coordinator.isProgrammaticChange = true
            textView.string = text
            textView.setSelectedRange(clamp(selected, maxLength: (text as NSString).length))
            coordinator.isProgrammaticChange = false
        }
        // Only re-highlight (and re-set font) when the parsed spans change
        // (after debounced reparse), not on every keystroke. Setting
        // textView.font on every update would trigger a full storage relayout.
        let fingerprint = spanFingerprint(document.spans)
        if fingerprint != coordinator.lastHighlightedSpanFingerprint || textChanged {
            textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            applySourceHighlighting(to: textView)
            coordinator.lastHighlightedSpanFingerprint = fingerprint
        }
    }

    private func spanFingerprint(_ spans: [FormulaSpan]) -> Int {
        var hasher = Hasher()
        hasher.combine(spans.count)
        for span in spans {
            hasher.combine(span.range.lowerBound)
            hasher.combine(span.range.upperBound)
        }
        return hasher.finalize()
    }

    private func applyRenderState(to textView: NSTextView, coordinator: Coordinator) {
        // Skip the full rebuild if the document hasn't been reparsed since the
        // last render. During typing, the generation stays the same (the
        // debounced reparse hasn't fired), so the direct textStorage edit from
        // shouldChangeTextIn stays on screen without being overwritten.
        if documentGeneration == coordinator.lastRenderedGeneration {
            return
        }

        let previousProjection = coordinator.currentProjection
        let projection = RenderProjection(document: document)

        // Full rebuild.
        let visibleSelection: NSRange
        if let pendingRawSelection = coordinator.pendingRawSelection {
            let visible = projection.visibleLocation(forRawLocation: pendingRawSelection)
            visibleSelection = NSRange(location: visible, length: 0)
        } else if let previousProjection,
                  let rawSelection = previousProjection.rawBoundary(
                    forVisibleLocation: textView.selectedRange().location
                  ) {
            let visible = projection.visibleLocation(forRawLocation: rawSelection)
            visibleSelection = NSRange(location: visible, length: 0)
        } else {
            visibleSelection = NSRange(
                location: projection.visibleLocation(forRawLocation: (text as NSString).length),
                length: 0
            )
        }

        coordinator.currentProjection = projection
        coordinator.lastRenderedGeneration = documentGeneration
        let rendered = buildRenderAttributedString(from: projection)
        coordinator.isProgrammaticChange = true
        textView.textStorage?.setAttributedString(rendered)
        textView.setSelectedRange(clamp(visibleSelection, maxLength: rendered.length))
        coordinator.isProgrammaticChange = false
        coordinator.pendingRawSelection = nil
        syncInputWidgets(on: textView, projection: projection, coordinator: coordinator)
    }

    private func applySourceHighlighting(to textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: storage.length)
        storage.beginEditing()
        storage.setAttributes([
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.labelColor,
        ], range: fullRange)

        for span in document.spans {
            let range = NSRange(
                location: span.range.lowerBound,
                length: max(0, span.range.upperBound - span.range.lowerBound)
            )
            guard range.location >= 0, range.location + range.length <= storage.length else {
                continue
            }
            storage.addAttributes(sourceAttributes(for: span), range: range)
        }

        storage.endEditing()
    }

    private func buildRenderAttributedString(from projection: RenderProjection) -> NSAttributedString {
        let out = NSMutableAttributedString(string: projection.visibleText, attributes: [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor.labelColor,
        ])

        for segment in projection.segments {
            let visibleRange = NSRange(
                location: segment.visibleRange.lowerBound,
                length: segment.visibleRange.upperBound - segment.visibleRange.lowerBound
            )

            switch segment.kind {
            case .plain:
                applyRenderTypography(to: out, range: visibleRange)
            case .formula(let span):
                out.addAttributes(renderAttributes(for: span), range: visibleRange)
                out.addAttribute(
                    .link,
                    value: URL(string: "apfelpad://span/\(span.id.uuidString)") as Any,
                    range: visibleRange
                )
            case .input:
                out.addAttributes([
                    .foregroundColor: NSColor.clear,
                    .backgroundColor: NSColor.clear,
                ], range: visibleRange)
            }
        }

        return out
    }

    private func applyRenderTypography(to text: NSMutableAttributedString, range: NSRange) {
        let ns = text.string as NSString
        var paragraphStart = range.location
        let upperBound = range.location + range.length

        while paragraphStart < upperBound, paragraphStart < ns.length {
            let paragraphRange = ns.paragraphRange(for: NSRange(location: paragraphStart, length: 0))
            let paragraph = ns.substring(with: paragraphRange)

            if paragraph.hasPrefix("# ") {
                hideMarkdownPrefix(in: text, paragraphRange: paragraphRange, prefixLength: 2)
                text.addAttributes([
                    .font: NSFont.systemFont(ofSize: 28, weight: .bold),
                ], range: NSRange(location: paragraphRange.location + 2, length: max(0, paragraphRange.length - 2)))
            } else if paragraph.hasPrefix("## ") {
                hideMarkdownPrefix(in: text, paragraphRange: paragraphRange, prefixLength: 3)
                text.addAttributes([
                    .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
                ], range: NSRange(location: paragraphRange.location + 3, length: max(0, paragraphRange.length - 3)))
            } else if paragraph.hasPrefix("### ") {
                hideMarkdownPrefix(in: text, paragraphRange: paragraphRange, prefixLength: 4)
                text.addAttributes([
                    .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
                ], range: NSRange(location: paragraphRange.location + 4, length: max(0, paragraphRange.length - 4)))
            }

            let nextParagraphStart = paragraphRange.location + paragraphRange.length
            if nextParagraphStart <= paragraphStart { break }
            paragraphStart = nextParagraphStart
        }
    }

    private func hideMarkdownPrefix(
        in text: NSMutableAttributedString,
        paragraphRange: NSRange,
        prefixLength: Int
    ) {
        guard paragraphRange.length >= prefixLength else { return }
        text.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 1),
        ], range: NSRange(location: paragraphRange.location, length: prefixLength))
    }

    private func sourceAttributes(for span: FormulaSpan) -> [NSAttributedString.Key: Any] {
        let isError: Bool
        if case .error = span.value {
            isError = true
        } else {
            isError = false
        }

        return [
            .backgroundColor: isError ? Self.errorBg : Self.paleGreen,
            .foregroundColor: isError ? NSColor.systemRed : Self.darkGreen,
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
        ]
    }

    private func renderAttributes(for span: FormulaSpan) -> [NSAttributedString.Key: Any] {
        let isError: Bool
        if case .error = span.value {
            isError = true
        } else {
            isError = false
        }

        return [
            .backgroundColor: isError ? Self.errorBg : Self.paleGreen,
            .foregroundColor: isError ? NSColor.systemRed : Self.darkGreen,
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .semibold),
            .cursor: NSCursor.pointingHand,
        ]
    }

    private func syncInputWidgets(
        on textView: NSTextView,
        projection: RenderProjection,
        coordinator: Coordinator
    ) {
        let activeSegments = projection.inputSegments()
        let activeIDs = Set(activeSegments.compactMap { segment -> UUID? in
            if case .input(let spec) = segment.kind { return spec.span.id }
            return nil
        })

        let inactiveIDs = coordinator.inputHosts.keys.filter { !activeIDs.contains($0) }
        for id in inactiveIDs {
            coordinator.inputHosts[id]?.removeFromSuperview()
            coordinator.inputHosts.removeValue(forKey: id)
        }

        for segment in activeSegments {
            guard case .input(let spec) = segment.kind else { continue }

            let host = coordinator.inputHosts[spec.span.id] ?? {
                let newHost = AccessibleInputHostView(rootView: AnyView(EmptyView()))
                newHost.translatesAutoresizingMaskIntoConstraints = true
                textView.addSubview(newHost)
                coordinator.inputHosts[spec.span.id] = newHost
                return newHost
            }()
            host.inputName = spec.name

            host.rootView = AnyView(
                InputFieldView(
                    name: spec.name,
                    type: spec.type,
                    value: Binding(
                        get: { inputValue?(spec.name) ?? spec.defaultValue ?? "" },
                        set: { onInputChange?(spec.name, $0) }
                    )
                )
                .fixedSize()
                .accessibilityLabel("Input \(spec.name)")
                .accessibilityIdentifier("apfelpad.input.\(spec.name)")
            )

            guard let frame = inputFrame(for: segment, in: textView) else {
                host.isHidden = true
                continue
            }

            let fitting = host.fittingSize
            host.frame = NSRect(
                x: frame.minX,
                y: frame.minY,
                width: max(frame.width, fitting.width),
                height: max(frame.height, fitting.height)
            )
            host.isHidden = false
        }
    }

    private func clearInputWidgets(from textView: NSTextView, coordinator: Coordinator) {
        for host in coordinator.inputHosts.values {
            host.removeFromSuperview()
        }
        coordinator.inputHosts.removeAll()
    }

    private func inputFrame(for segment: RenderProjection.Segment, in textView: NSTextView) -> NSRect? {
        guard let layoutManager = textView.layoutManager,
              let container = textView.textContainer else {
            return nil
        }

        let charRange = NSRange(
            location: segment.visibleRange.lowerBound,
            length: max(1, segment.visibleRange.upperBound - segment.visibleRange.lowerBound)
        )
        layoutManager.ensureLayout(for: container)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
        var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
        rect.origin.x += textView.textContainerInset.width
        rect.origin.y += textView.textContainerInset.height
        if rect.width <= 0 {
            rect.size.width = 160
        }
        if rect.height <= 0 {
            rect.size.height = 28
        }
        return rect
    }

    private func clamp(_ range: NSRange, maxLength: Int) -> NSRange {
        let location = max(0, min(range.location, maxLength))
        let length = max(0, min(range.length, maxLength - location))
        return NSRange(location: location, length: length)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditableMarkdownView
        weak var textView: FormulaTextView?
        var currentProjection: RenderProjection?
        var pendingRawSelection: Int?
        var isProgrammaticChange = false
        var inputHosts: [UUID: AccessibleInputHostView] = [:]
        var lastFocusToken: Int = .min
        var lastInputFocusToken: Int = .min
        var lastHighlightedSpanFingerprint: Int = -1
        /// The document generation at the time of the last render rebuild.
        /// When the user types, the generation doesn't change (the debounced
        /// reparse hasn't fired yet), so the view skips the expensive rebuild.
        var lastRenderedGeneration: Int = -1

        init(parent: EditableMarkdownView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isProgrammaticChange,
                  parent.mode == .source,
                  let textView = notification.object as? NSTextView else {
                return
            }
            parent.text = textView.string
            parent.onSelectionChange?(textView.selectedRange().location)
        }

        func repositionInputWidgets() {
            guard let textView,
                  let projection = currentProjection else { return }
            for segment in projection.inputSegments() {
                guard case .input(let spec) = segment.kind,
                      let host = inputHosts[spec.span.id] else { continue }
                guard let frame = parent.inputFrame(for: segment, in: textView) else {
                    host.isHidden = true
                    continue
                }
                let fitting = host.fittingSize
                host.frame = NSRect(
                    x: frame.minX,
                    y: frame.minY,
                    width: max(frame.width, fitting.width),
                    height: max(frame.height, fitting.height)
                )
                host.isHidden = false
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isProgrammaticChange,
                  let textView = notification.object as? NSTextView else {
                return
            }

            switch parent.mode {
            case .source:
                parent.onSelectionChange?(textView.selectedRange().location)
            case .render:
                guard let projection = currentProjection else { return }
                let selection = textView.selectedRange()
                if selection.length == 0,
                   let span = projection.atomicSpan(atVisibleLocation: selection.location) {
                    parent.onFormulaActivate?(span)
                    if let chipRange = projection.segments.first(where: { $0.atomicSpan?.id == span.id })?.visibleRange {
                        isProgrammaticChange = true
                        textView.setSelectedRange(NSRange(
                            location: chipRange.lowerBound,
                            length: chipRange.upperBound - chipRange.lowerBound
                        ))
                        isProgrammaticChange = false
                    }
                    return
                }
                if let rawLocation = projection.rawBoundary(forVisibleLocation: selection.location) {
                    parent.onSelectionChange?(rawLocation)
                }
            }
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            guard parent.mode == .render,
                  let projection = currentProjection else {
                return true
            }

            let replacement = replacementString ?? ""
            guard let rawRange = projection.rawEditRange(forVisibleRange: affectedCharRange) else {
                if let span = projection.firstAtomicSpanIntersecting(visibleRange: affectedCharRange) {
                    parent.onFormulaActivate?(span)
                }
                NSSound.beep()
                return false
            }

            // Apply the edit directly to the text view's storage for instant
            // visual feedback. Then update the raw markdown for the debounced
            // reparse. The timestamp prevents applyRenderState from nuking the
            // storage with a full rebuild until the debounce fires.
            isProgrammaticChange = true
            textView.textStorage?.replaceCharacters(in: affectedCharRange, with: replacement)
            let newCursor = affectedCharRange.location + (replacement as NSString).length
            textView.setSelectedRange(NSRange(location: newCursor, length: 0))
            isProgrammaticChange = false

            let ns = parent.text as NSString
            let nextRaw = ns.replacingCharacters(in: rawRange, with: replacement)
            pendingRawSelection = rawRange.location + (replacement as NSString).length
            parent.text = nextRaw
            if let pendingRawSelection {
                parent.onSelectionChange?(pendingRawSelection)
            }
            return false
        }

        func textView(
            _ textView: NSTextView,
            clickedOnLink link: Any,
            at charIndex: Int
        ) -> Bool {
            guard parent.mode == .render else { return false }
            if let url = link as? URL,
               let span = SpanClickRouter.handle(url: url, in: parent.document) {
                parent.onFormulaActivate?(span)
                return true
            }
            return false
        }
    }

    private func requestFocusIfNeeded(for textView: NSTextView, coordinator: Coordinator) {
        guard coordinator.lastFocusToken != focusToken else { return }
        coordinator.lastFocusToken = focusToken
        DispatchQueue.main.async {
            guard let window = textView.window else { return }
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(textView)
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }
    }

    private func requestInputFocusIfNeeded(in textView: NSTextView, coordinator: Coordinator) {
        guard mode == .render,
              coordinator.lastInputFocusToken != inputFocusToken,
              let focusedInputName else {
            return
        }
        coordinator.lastInputFocusToken = inputFocusToken
        let wanted = focusedInputName.lowercased()
        guard let host = coordinator.inputHosts.values.first(where: {
            $0.inputName.lowercased() == wanted
        }) else {
            return
        }
        DispatchQueue.main.async {
            guard let window = textView.window else { return }
            let target = firstFocusableDescendant(in: host) ?? host
            window.makeFirstResponder(target)
            if let textField = target as? NSTextField {
                textField.selectText(nil)
            } else if let textView = target as? NSTextView {
                textView.selectAll(nil)
            }
        }
    }

    private func firstFocusableDescendant(in view: NSView) -> NSView? {
        if let textField = view as? NSTextField, textField.isEditable {
            return textField
        }
        if let textView = view as? NSTextView, textView.isEditable {
            return textView
        }
        if view is NSSlider || view is NSButton || view is NSDatePicker || view is NSColorWell {
            return view
        }
        for subview in view.subviews {
            if let found = firstFocusableDescendant(in: subview) {
                return found
            }
        }
        return nil
    }
}

/// NSTextView subclass with formula-aware copy: right-click context menu and
/// Cmd+C both copy the formula's visible content (result in render mode,
/// source in source mode).
final class FormulaTextView: NSTextView {
    weak var formulaCoordinator: EditableMarkdownView.Coordinator?

    /// Creates a scrollable FormulaTextView (mirrors NSTextView.scrollableTextView()).
    static func makeScrollable() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let contentSize = scrollView.contentSize
        let textContainer = NSTextContainer(containerSize: NSSize(
            width: contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        ))
        textContainer.widthTracksTextView = true

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)

        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)

        let textView = FormulaTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)

        scrollView.documentView = textView
        return scrollView
    }

    // MARK: - Reflow input widgets on resize

    override func layout() {
        super.layout()
        formulaCoordinator?.repositionInputWidgets()
    }

    // MARK: - Right-click context menu

    override func rightMouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let (result, source) = formulaTextUnderPoint(point) {
            let menu = NSMenu()
            let copyResult = NSMenuItem(title: "Copy Result", action: #selector(copyFormulaResult), keyEquivalent: "")
            copyResult.representedObject = result
            copyResult.target = self
            menu.addItem(copyResult)

            let copySource = NSMenuItem(title: "Copy Source", action: #selector(copyFormulaSource), keyEquivalent: "")
            copySource.representedObject = source
            copySource.target = self
            menu.addItem(copySource)

            NSMenu.popUpContextMenu(menu, with: event, for: self)
            return
        }
        super.rightMouseDown(with: event)
    }

    @objc private func copyFormulaResult(_ sender: NSMenuItem) {
        guard let text = sender.representedObject as? String else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    @objc private func copyFormulaSource(_ sender: NSMenuItem) {
        guard let text = sender.representedObject as? String else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Cmd+C copies formula content when span is selected

    override func copy(_ sender: Any?) {
        guard let coordinator = formulaCoordinator else {
            super.copy(sender)
            return
        }

        let selection = selectedRange()

        switch coordinator.parent.mode {
        case .render:
            guard let projection = coordinator.currentProjection,
                  let segment = projection.segments.first(where: { seg in
                      guard seg.atomicSpan != nil else { return false }
                      return selection.location >= seg.visibleRange.lowerBound
                          && selection.location < seg.visibleRange.upperBound
                  }),
                  let span = segment.atomicSpan else {
                super.copy(sender)
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(span.displayText, forType: .string)

        case .source:
            let doc = coordinator.parent.document
            if let span = doc.spans.first(where: {
                selection.location >= $0.range.lowerBound && selection.location < $0.range.upperBound
            }) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(span.source, forType: .string)
            } else {
                super.copy(sender)
            }
        }
    }

    // MARK: - Helpers

    /// Returns (displayText, source) for the formula span under the given point, if any.
    private func formulaTextUnderPoint(_ point: NSPoint) -> (result: String, source: String)? {
        guard let coordinator = formulaCoordinator else { return nil }
        let charIndex = characterIndexForInsertion(at: point)

        switch coordinator.parent.mode {
        case .render:
            guard let projection = coordinator.currentProjection,
                  let segment = projection.segments.first(where: {
                      if case .formula = $0.kind {
                          return charIndex >= $0.visibleRange.lowerBound
                              && charIndex < $0.visibleRange.upperBound
                      }
                      return false
                  }),
                  case .formula(let span) = segment.kind else {
                return nil
            }
            return (result: span.displayText, source: span.source)

        case .source:
            let doc = coordinator.parent.document
            guard let span = doc.spans.first(where: { $0.range.contains(charIndex) }) else {
                return nil
            }
            return (result: span.displayText, source: span.source)
        }
    }
}

final class AccessibleInputHostView: NSHostingView<AnyView> {
    var inputName: String = "" {
        didSet { applyAccessibility() }
    }

    required init(rootView: AnyView) {
        super.init(rootView: rootView)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        applyAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyAccessibility() {
        guard !inputName.isEmpty else { return }
        setAccessibilityLabel("Input \(inputName)")
        setAccessibilityIdentifier("apfelpad.input.\(inputName)")
    }
}
