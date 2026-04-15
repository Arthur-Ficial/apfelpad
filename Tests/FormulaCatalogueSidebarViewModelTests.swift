import Testing
import Foundation
@testable import apfelpad

@Suite("FormulaCatalogueSidebarViewModel", .serialized)
@MainActor
struct FormulaCatalogueSidebarViewModelTests {
    @Test("isOpen defaults to false")
    func defaultClosed() {
        let vm = FormulaCatalogueSidebarViewModel()
        #expect(vm.isOpen == false)
    }

    @Test("toggle flips isOpen")
    func toggleFlips() {
        let vm = FormulaCatalogueSidebarViewModel()
        vm.toggle()
        #expect(vm.isOpen == true)
        vm.toggle()
        #expect(vm.isOpen == false)
    }

    @Test("open() and close() set isOpen directly")
    func openClose() {
        let vm = FormulaCatalogueSidebarViewModel()
        vm.open()
        #expect(vm.isOpen == true)
        vm.close()
        #expect(vm.isOpen == false)
    }

    @Test("visibleSections defaults to every section when query is empty")
    func visibleDefault() {
        let vm = FormulaCatalogueSidebarViewModel()
        #expect(vm.visibleSections.count == FormulaCatalogue.grouped().count)
    }

    @Test("searchQuery filters visibleSections")
    func searchFilters() {
        let vm = FormulaCatalogueSidebarViewModel()
        vm.searchQuery = "upper"
        let names = vm.visibleSections.flatMap(\.entries).map(\.name)
        #expect(names.contains("=upper"))
        #expect(!names.contains("=math"))
    }

    @Test("searchQuery = '' restores everything")
    func clearSearch() {
        let vm = FormulaCatalogueSidebarViewModel()
        vm.searchQuery = "upper"
        vm.searchQuery = ""
        #expect(vm.visibleSections.count == FormulaCatalogue.grouped().count)
    }

    @Test("insert(entry:) invokes onInsert callback with the entry's example")
    func insertInvokesCallback() {
        let vm = FormulaCatalogueSidebarViewModel()
        var inserted: String?
        vm.onInsert = { source in inserted = source }
        let entry = FormulaCatalogue.all.first { $0.name == "=upper" }!
        vm.insert(entry)
        #expect(inserted == entry.example)
    }

    @Test("insert without a callback is a no-op (does not crash)")
    func insertWithoutCallback() {
        let vm = FormulaCatalogueSidebarViewModel()
        let entry = FormulaCatalogue.all.first!
        vm.insert(entry)  // must not throw / crash
    }

    @Test("isOpen persists via UserDefaults (via persistKey)")
    func persistence() {
        let key = "apfelpad_test_sidebar_open_\(UUID().uuidString)"
        UserDefaults.standard.removeObject(forKey: key)
        let vm1 = FormulaCatalogueSidebarViewModel(persistKey: key)
        vm1.open()
        // New VM reads the persisted value
        let vm2 = FormulaCatalogueSidebarViewModel(persistKey: key)
        #expect(vm2.isOpen == true)
        UserDefaults.standard.removeObject(forKey: key)
    }
}
