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

    // Helper to create ViewModel instance
    private func createViewModelSUT(initialLists: [ShoppingList]? = []) -> ShoppingListViewModel {
         // Pass an empty array by default to ensure a clean state for most tests
         print("Test Setup: Initializing ViewModel with injected list state (count: \(initialLists?.count ?? 0)).")
         return ShoppingListViewModel(initialLists: initialLists)
    }

    // Helper to get a specific list from the ViewModel for assertions
    private func getList(id: UUID, from viewModel: ShoppingListViewModel) throws -> ShoppingList {
        try #require(viewModel.lists.first { $0.id == id })
    }


    @Test("ViewModel addItem - Adds Item to Correct List")
    func viewModelAddItemAddsToCorrectList() async throws {
        // Arrange
        let sut = createViewModelSUT()
        let list1 = sut.addList(name: "Groceries", listType: .shopping) // Use ViewModel's addList
        let list2 = sut.addList(name: "Tasks", listType: .task)
        let itemName = "Milk"
        let list1InitialItemCount = list1.items.count

        // Act
        await sut.addItem(name: itemName, toList: list1) // Call the ViewModel method

        // Assert
        // Fetch the updated lists from the ViewModel's published array
        let updatedList1 = try #require(sut.lists.first { $0.id == list1.id })
        let updatedList2 = try #require(sut.lists.first { $0.id == list2.id })

        #expect(updatedList1.items.count == list1InitialItemCount + 1, "Item count for list1 should increase")
        #expect(updatedList2.items.count == list2.items.count, "Item count for list2 should NOT change")
        #expect(updatedList1.items.last?.name == itemName, "Correct item name should be added to list1")
    }

    @Test("ViewModel addItem - Adds Item With Details Correctly")
    func viewModelAddItemWithDetails() async throws {
        // Arrange
        let sut = createViewModelSUT()
        let list = sut.addList(name: "Hardware Store", listType: .shopping)
        let itemName = "Screws"; let quantity = 50; let unit: String? = "box"; let price: Decimal? = 4.95

        // Act
        await sut.addItem(name: itemName, quantity: quantity, unit: unit, price: price, toList: list)

        // Assert
        let updatedList = try #require(sut.lists.first { $0.id == list.id })
        #expect(updatedList.items.count == 1)
        let addedItem = try #require(updatedList.items.first)
        #expect(addedItem.name == itemName)
        #expect(addedItem.quantity == quantity)
        #expect(addedItem.unit == unit)
        #expect(addedItem.price == price)
    }

    @Test("ViewModel addItem - Trims Name Whitespace")
    func viewModelAddItemTrimsName() async throws {
        // Arrange
        let sut = createViewModelSUT()
        let list = sut.addList(name: "List", listType: .shopping)
        let nameWithSpace = "  Item Name \n"
        let expectedName = "Item Name"

        // Act
        await sut.addItem(name: nameWithSpace, toList: list)

        // Assert
        let updatedList = try #require(sut.lists.first { $0.id == list.id })
        let addedItem = try #require(updatedList.items.first)
        #expect(addedItem.name == expectedName, "Name should be trimmed by ViewModel addItem")
    }

    @Test("ViewModel addItem - Ignores Empty Name")
    func viewModelAddItemIgnoresEmptyName() async throws {
        // Arrange
        let sut = createViewModelSUT()
        let list = sut.addList(name: "List", listType: .shopping)
        let initialCount = list.items.count
        let emptyName = "   "

        // Act
        await sut.addItem(name: emptyName, toList: list)

        // Assert
        let updatedList = try #require(sut.lists.first { $0.id == list.id })
        #expect(updatedList.items.count == initialCount, "Item count should not change for empty name")
    }

    @Test("ViewModel addItem - Handles Nonexistent List Gracefully")
    func viewModelAddItemNonexistentList() async throws {
        // Arrange
        let sut = createViewModelSUT()
        _ = sut.addList(name: "Real List", listType: .shopping) // Add at least one list
        let fakeList = ShoppingList(name: "Fake", listType: .shopping) // A list not actually in the ViewModel
        let initialViewModelLists = sut.lists.map { $0.items } // Capture initial state

        // Act
        await sut.addItem(name: "Test Item", toList: fakeList)

        // Assert
        // Check that no list in the ViewModel was modified
        #expect(sut.lists.count == 1, "ViewModel list count should remain 1")
        #expect(sut.lists[0].items == initialViewModelLists[0], "Items in the real list should be unchanged")
        // We expect a console log message "List not found..." from the ViewModel function
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
