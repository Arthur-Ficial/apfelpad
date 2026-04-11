import Testing
@testable import apfelpad

@Suite("FormulaBarViewModel")
@MainActor
struct FormulaBarViewModelTests {
    @Test("selecting a span shows its source")
    func select() {
        let vm = FormulaBarViewModel()
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .ready(text: "2")
        )
        vm.select(span)
        #expect(vm.sourceText == "=math(1+1)")
        #expect(vm.selectedSpanID == span.id)
    }

    @Test("clearing leaves placeholder")
    func clear() {
        let vm = FormulaBarViewModel()
        vm.clear()
        #expect(vm.sourceText == "")
        #expect(vm.placeholder == "click a formula span to edit its source")
        #expect(vm.selectedSpanID == nil)
    }
}
