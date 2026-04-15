import Testing
@testable import apfelpad

@Suite("FormulaSpan", .serialized)
struct FormulaSpanTests {
    @Test("stores source range and parsed call")
    func makeSpan() {
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .idle
        )
        #expect(span.source == "=math(1+1)")
        #expect(span.call == .math(expression: "1+1"))
        #expect(span.value == .idle)
    }

    @Test("value transitions are equatable")
    func valueEquality() {
        #expect(FormulaValue.ready(text: "2") == FormulaValue.ready(text: "2"))
        #expect(FormulaValue.ready(text: "2") != FormulaValue.ready(text: "3"))
        #expect(FormulaValue.idle != FormulaValue.evaluating)
    }
}
