//
//  ShoppingListViewModelTests.swift
//  ListyWisty
//
//  Created by João Rato on 21/04/2025.
//


import Testing
import Foundation
@testable import ListyWisty // Your app target

@Suite("ShoppingListViewModel Tests")
struct ShoppingListViewModelTests {

    /// Creates a ViewModel instance configured for testing with a unique, temporary data file.
    /// - Parameter initialLists: Optional initial lists to inject into the ViewModel.
    /// - Returns: A tuple containing the configured ViewModel and the unique filename used.
    private func createViewModelSUT(initialLists: [ShoppingList]? = []) throws -> (viewModel: ShoppingListViewModel, fileName: String) {
        let uniqueId = UUID().uuidString
        let testFileName = "TestShoppingLists-\(uniqueId).json"
        print("Test Setup: Creating ViewModel with unique test file: \(testFileName)")

        // Ensure the test file doesn't exist initially (belt-and-suspenders)
        let testURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(testFileName)
        try? FileManager.default.removeItem(at: testURL) // Ignore error if file doesn't exist

        // Initialize ViewModel using the designated initializer with the test filename
        let viewModel = ShoppingListViewModel(initialLists: initialLists, testFileName: testFileName)
        return (viewModel, testFileName)
    }

    /// Cleans up (deletes) the specified test data file from the documents directory.
    /// - Parameter fileName: The name of the test file to delete.
    private func cleanupTestFile(fileName: String) {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("Test Cleanup: Successfully deleted test file: \(fileName)")
            } else {
                print("Test Cleanup: Test file not found (already deleted or never created): \(fileName)")
            }
        } catch {
            print("⚠️ Test Cleanup: Failed to delete test file '\(fileName)': \(error)")
            // Don't fail the test itself for cleanup failure, but log it.
        }
    }

    // Helper to get a specific list from the ViewModel for assertions
    private func getList(id: UUID, from viewModel: ShoppingListViewModel) throws -> ShoppingList {
        try #require(viewModel.lists.first { $0.id == id })
    }
    
    @Test("ViewModel addList - Adds List and Saves")
    func viewModelAddList() throws {
        // Arrange
        let (sut, testFileName) = try createViewModelSUT(initialLists: [])
        // Ensure cleanup happens even if test fails
        defer { cleanupTestFile(fileName: testFileName) }

        let listName = "New Test List"
        let listType = ListType.task

        // Act
        let newList = sut.addList(name: listName, listType: listType)

        // Assert
        #expect(sut.lists.count == 1)
        let addedList = try #require(sut.lists.first)
        #expect(addedList.id == newList.id)
        #expect(addedList.name == listName)
        #expect(addedList.listType == listType)

        // Assert Persistence (Optional but good): Load a new VM instance using the *same test file*
        // to verify the save worked.
        print("Test Assert: Verifying persistence by reloading from \(testFileName)")
        let verificationVM = ShoppingListViewModel(initialLists: nil, testFileName: testFileName) // Load from the specific test file
        #expect(verificationVM.lists.count == 1, "Verification VM should load 1 list")
        let reloadedList = try #require(verificationVM.lists.first)
        #expect(reloadedList.id == newList.id, "Reloaded list ID should match")
        #expect(reloadedList.name == listName, "Reloaded list name should match")
    }

    @Test("ViewModel deleteList - Removes List and Saves")
    func viewModelDeleteList() throws {
        // Arrange
        let listToDelete = ShoppingList(name: "Delete Me", listType: .shopping)
        let listToKeep = ShoppingList(name: "Keep Me", listType: .task)
        let (sut, testFileName) = try createViewModelSUT(initialLists: [listToDelete, listToKeep])
        defer { cleanupTestFile(fileName: testFileName) }

        #expect(sut.lists.count == 2)

        // Act
        sut.deleteList(id: listToDelete.id)

        // Assert
        #expect(sut.lists.count == 1)
        #expect(sut.lists.first?.id == listToKeep.id)
        #expect(sut.lists.contains(where: { $0.id == listToKeep.id }))
        #expect(!sut.lists.contains(where: { $0.id == listToDelete.id }))

        // Assert Persistence
        print("Test Assert: Verifying persistence by reloading from \(testFileName)")
        let verificationVM = ShoppingListViewModel(initialLists: nil, testFileName: testFileName)
        #expect(verificationVM.lists.count == 1, "Verification VM should load 1 list after delete")
        #expect(verificationVM.lists.first?.id == listToKeep.id, "Verification VM should only contain the kept list")
    }

    @Test("ViewModel moveList - Reorders Lists and Saves")
    func viewModelMoveList() throws {
        // Arrange
        let listA = ShoppingList(name: "A", listType: .shopping)
        let listB = ShoppingList(name: "B", listType: .shopping)
        let listC = ShoppingList(name: "C", listType: .shopping)
        let (sut, testFileName) = try createViewModelSUT(initialLists: [listA, listB, listC])
        defer { cleanupTestFile(fileName: testFileName) }

        let source = IndexSet(integer: 0) // Move "A"
        let destination = 3 // To the end

        // Act
        sut.moveList(from: source, to: destination)

        // Assert - Order in ViewModel
        let currentIDs = sut.lists.map { $0.id }
        #expect(currentIDs == [listB.id, listC.id, listA.id], "Lists should be reordered to B, C, A")

        // Assert Persistence
        print("Test Assert: Verifying persistence by reloading from \(testFileName)")
        let verificationVM = ShoppingListViewModel(initialLists: nil, testFileName: testFileName)
        #expect(verificationVM.lists.map { $0.id } == [listB.id, listC.id, listA.id], "Reloaded lists should have the new order B, C, A")
    }


    @Test("ViewModel addItem - Adds Item to Correct List and Saves")
    func viewModelAddItemAddsToCorrectListAndSaves() async throws {
        // Arrange
        let list1 = ShoppingList(name: "Groceries", listType: .shopping)
        let list2 = ShoppingList(name: "Tasks", listType: .task)
        let (sut, testFileName) = try createViewModelSUT(initialLists: [list1, list2])
        defer { cleanupTestFile(fileName: testFileName) }

        let itemName = "Milk"
        let list1InitialItemCount = list1.items.count

        // Act
        await sut.addItem(name: itemName, toList: list1) // Call the ViewModel method

        // Assert - State change in ViewModel
        let updatedList1 = try getList(id: list1.id, from: sut)
        let updatedList2 = try getList(id: list2.id, from: sut)
        #expect(updatedList1.items.count == list1InitialItemCount + 1)
        #expect(updatedList2.items.count == list2.items.count)
        #expect(updatedList1.items.last?.name == itemName)

        // Assert Persistence
        print("Test Assert: Verifying persistence by reloading from \(testFileName)")
        let verificationVM = ShoppingListViewModel(initialLists: nil, testFileName: testFileName)
        let reloadedList1 = try getList(id: list1.id, from: verificationVM)
        #expect(reloadedList1.items.count == list1InitialItemCount + 1, "Reloaded list1 should have the added item")
        #expect(reloadedList1.items.last?.name == itemName, "Reloaded item name should match")
        let reloadedList2 = try getList(id: list2.id, from: verificationVM)
        #expect(reloadedList2.items.isEmpty, "Reloaded list2 should still be empty")
    }

    @Test("ViewModel addItem - Adds Item With Details Correctly and Saves")
    func viewModelAddItemWithDetailsAndSaves() async throws {
        // Arrange
        let list = ShoppingList(name: "Hardware Store", listType: .shopping)
        let (sut, testFileName) = try createViewModelSUT(initialLists: [list])
        defer { cleanupTestFile(fileName: testFileName) }

        let itemName = "Screws"; let quantity = 50; let unit: String? = "box"; let price: Decimal? = 4.95

        // Act
        await sut.addItem(name: itemName, quantity: quantity, unit: unit, price: price, toList: list)

        // Assert - State
        let updatedList = try getList(id: list.id, from: sut)
        #expect(updatedList.items.count == 1)
        let addedItem = try #require(updatedList.items.first)
        #expect(addedItem.name == itemName)
        #expect(addedItem.quantity == quantity)
        #expect(addedItem.unit == unit)
        #expect(addedItem.price == price)

        // Assert - Persistence
        print("Test Assert: Verifying persistence by reloading from \(testFileName)")
        let verificationVM = ShoppingListViewModel(initialLists: nil, testFileName: testFileName)
        let reloadedList = try getList(id: list.id, from: verificationVM)
        #expect(reloadedList.items.count == 1, "Reloaded list should have 1 item")
        let reloadedItem = try #require(reloadedList.items.first)
        #expect(reloadedItem.name == itemName && reloadedItem.quantity == quantity && reloadedItem.unit == unit && reloadedItem.price == price, "Reloaded item details should match")
    }

    @Test("ViewModel addItem - Adds Item at Correct Index (Before Checked) and Saves")
    func viewModelAddItemCorrectIndexAndSaves() async throws {
        // Arrange
        let list = ShoppingList(name: "Groceries", listType: .shopping)
        list.items = [
            ShoppingItem(name: "Existing Unchecked", isChecked: false),
            ShoppingItem(name: "Existing Checked", isChecked: true, checkedTimestamp: Date())
        ]
        let (sut, testFileName) = try createViewModelSUT(initialLists: [list])
        defer { cleanupTestFile(fileName: testFileName) }

        let newItemName = "New Unchecked Item"

        // Act
        await sut.addItem(name: newItemName, toList: list)

        // Assert - State
        let updatedList = try getList(id: list.id, from: sut)
        #expect(updatedList.items.count == 3)
        #expect(updatedList.items[0].name == "Existing Unchecked", "First item should remain")
        #expect(updatedList.items[1].name == newItemName, "New item should be inserted at index 1")
        #expect(updatedList.items[2].name == "Existing Checked", "Checked item should be last")

        // Assert - Persistence
        print("Test Assert: Verifying persistence by reloading from \(testFileName)")
        let verificationVM = ShoppingListViewModel(initialLists: nil, testFileName: testFileName)
        let reloadedList = try getList(id: list.id, from: verificationVM)
        #expect(reloadedList.items.count == 3, "Reloaded list should have 3 items")
        #expect(reloadedList.items.map { $0.name } == ["Existing Unchecked", newItemName, "Existing Checked"], "Reloaded list should maintain correct order")
    }

    // --- Tests that DON'T need persistence check (already covered by addItem tests) ---

    @Test("ViewModel addItem - Trims Name Whitespace")
    func viewModelAddItemTrimsName() async throws {
        // Arrange
        let list = ShoppingList(name: "List", listType: .shopping)
        let (sut, testFileName) = try createViewModelSUT(initialLists: [list])
        defer { cleanupTestFile(fileName: testFileName) }

        let nameWithSpace = "  Item Name \n"
        let expectedName = "Item Name"

        // Act
        await sut.addItem(name: nameWithSpace, toList: list)

        // Assert
        let updatedList = try getList(id: list.id, from: sut)
        let addedItem = try #require(updatedList.items.first)
        #expect(addedItem.name == expectedName)
    }

    @Test("ViewModel addItem - Ignores Empty Name")
    func viewModelAddItemIgnoresEmptyName() async throws {
        // Arrange
        let list = ShoppingList(name: "List", listType: .shopping)
        let (sut, testFileName) = try createViewModelSUT(initialLists: [list])
        defer { cleanupTestFile(fileName: testFileName) }

        let initialCount = list.items.count
        let emptyName = "   "

        // Act
        await sut.addItem(name: emptyName, toList: list)

        // Assert
        let updatedList = try getList(id: list.id, from: sut)
        #expect(updatedList.items.count == initialCount)
    }

    @Test("ViewModel addItem - Handles Nonexistent List Gracefully")
    func viewModelAddItemNonexistentList() async throws {
        // Arrange
        let realList = ShoppingList(name: "Real List", listType: .shopping)
        let (sut, testFileName) = try createViewModelSUT(initialLists: [realList])
        defer { cleanupTestFile(fileName: testFileName) }

        let fakeList = ShoppingList(name: "Fake", listType: .shopping)
        let initialViewModelLists = sut.lists // Get a copy

        // Act
        await sut.addItem(name: "Test Item", toList: fakeList)

        // Assert
        #expect(sut.lists.count == initialViewModelLists.count)
        #expect(sut.lists[0].items == initialViewModelLists[0].items) // Compare items too
        // Expect console log: "List not found..."
    }

    // TODO: Test that viewModel.addItem triggers listDidChange() / saveLists()
    // This often requires more advanced techniques like mocking the save mechanism
    // or checking file modification dates, which can make tests slower/more brittle.
    // For now, we assume listDidChange() is called based on code inspection.

}

// String helper extension (move to shared location)
extension String {
    func nilIfEmpty() -> String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
     var isBlank: Bool {
         self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
     }
}
