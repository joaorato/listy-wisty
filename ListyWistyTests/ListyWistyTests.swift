//
//  ListyWistyTests.swift
//  ListyWistyTests
//
//  Created by João Rato on 29/03/2025.
//

import Testing
import Foundation
@testable import ListyWisty

struct ListyWistyTests {
    
    // Helper to create a list instance for tests (Updated)
    private func createSUT(name: String = "Test List", type: ListType = .shopping) -> ShoppingList {
        // Pass the type to the initializer
        return ShoppingList(name: name, listType: type)
    }
    
    @Test("Add Item - Defaults Quantity to 1")
    func addItemDefaultsQuantityToOne() async throws {
        // Arrange
        let sut = createSUT(type: .shopping) // Use shopping list for quantity test

        // Act
        sut.addItem(name: "New Item")

        // Assert
        let addedItem = try #require(sut.items.last)
        #expect(addedItem.quantity == 1, "Newly added item should have quantity 1 by default")
    }

    @Test("Add Item - Increases Count and Has Correct Name/State")
    func nameaddItemIncreasesCountAndHasCorrectName() async throws {
        // Arrange
        let sut = createSUT()
        let initialCount = sut.items.count
        let itemName = "Milk"

        // Act
        sut.addItem(name: itemName)

        // Assert
        #expect(sut.items.count == initialCount + 1, "Item count should increase by 1")

        let addedItem = try #require(sut.items.last, "Should be able to get the last added item")
        #expect(addedItem.name == itemName, "Last added item should have the correct name")
        #expect(!addedItem.isChecked, "Newly added item should be unchecked")
    }
    
    @Test("Add Item - Does Not Add Empty Name")
    func addItemDoesNotAddEmptyName() async throws {
        // Arrange
        let sut = createSUT()
        let initialCount = sut.items.count
        let emptyName = "   " // Whitespace only

        // Act
        sut.addItem(name: emptyName)

        // Assert
        #expect(sut.items.count == initialCount, "Item count should not increase for empty name")
    }
    
    @Test("Toggle Item - Check Moves To Checked Section, Sets Timestamp, Sorts Correctly")
    func toggleItemCheckMovesSetsTimestampSorts() async throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Bread") // Will be checked
        sut.addItem(name: "Eggs")  // Will remain unchecked
        let breadID = try #require(sut.items.first?.id, "Should find Bread item ID")
        let _ = sut.items[0].checkedTimestamp // Should be nil

        // Act
        sut.toggleItem(id: breadID) // Check "Bread"

        // Assert State
        let breadItem = try #require(sut.items.first(where: { $0.id == breadID }), "Failed to find Bread after toggle")
        #expect(breadItem.isChecked, "Item should be checked")
        #expect(breadItem.checkedTimestamp != nil, "Checked timestamp should be set")
        // We can't easily compare timestamps directly due to potential slight variations
        // #expect(breadItem.checkedTimestamp != initialTimestamp) // Not very robust

        // Assert Position
        #expect(sut.items.count == 2, "Should still have 2 items")
        #expect(sut.items[0].name == "Eggs", "Unchecked item 'Eggs' should now be first")
        #expect(sut.items[1].name == "Bread", "Checked item 'Bread' should now be last")
        #expect(sut.items[1].id == breadID)
    }
    
    @Test("Toggle Item - Uncheck Moves To Unchecked Section, Clears Timestamp, Sorts Correctly")
    func toggleItemUncheckMovesClearsTimestampSorts() async throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Juice")  // Unchecked
        sut.addItem(name: "Butter") // Will be checked then unchecked
        let butterID = try #require(sut.items.last?.id, "Should find Butter item ID")

        // Check "Butter" first
        sut.toggleItem(id: butterID)
        #expect(sut.items.last?.id == butterID, "Butter should be last after checking")
        #expect(sut.items.last?.isChecked == true)
        let _ = try #require(sut.items.last?.checkedTimestamp) // Make sure it got set

        // Act: Uncheck "Butter"
        sut.toggleItem(id: butterID)

        // Assert State
        let butterItem = try #require(sut.items.first(where: { $0.id == butterID }), "Failed to find Butter after unchecking")
        #expect(!butterItem.isChecked, "Item should be unchecked")
        #expect(butterItem.checkedTimestamp == nil, "Checked timestamp should be nil")

        // Assert Position (assuming relative order of unchecked is maintained)
        #expect(sut.items.count == 2)
        #expect(sut.items[0].name == "Juice", "Original unchecked item 'Juice' should be first")
        #expect(sut.items[1].name == "Butter", "Newly unchecked item 'Butter' should be second")
        #expect(sut.items[1].id == butterID)
    }
    
    @Test("Toggle Item - Multiple Checked Items Sort By Timestamp Descending")
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) // Required for Clock.sleep
    func toggleItemMultipleCheckedSortsByTimestampDescending() async throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Item A")
        sut.addItem(name: "Item B")
        sut.addItem(name: "Item C")
        let idA = sut.items[0].id
        let idB = sut.items[1].id
        let idC = sut.items[2].id

        // Act: Check items in order C, A, B with slight delays
        // Note: Using sleep in tests is generally discouraged. Consider injecting a Clock for better control.
        // Using async sleep from Concurrency
        sut.toggleItem(id: idC); try await Task.sleep(for: .milliseconds(10)) // Check C first (oldest timestamp)
        sut.toggleItem(id: idA); try await Task.sleep(for: .milliseconds(10)) // Check A second
        sut.toggleItem(id: idB)           // Check B last (newest timestamp)

        // Assert: All items are checked, order should be B, A, C (newest checked first)
        #expect(sut.items.count == 3)
        #expect(sut.items.allSatisfy { $0.isChecked }, "All items should be checked")
        #expect(sut.items[0].id == idB, "Item B (newest checked) should be first")
        #expect(sut.items[1].id == idA, "Item A (middle checked) should be second")
        #expect(sut.items[2].id == idC, "Item C (oldest checked) should be third")
    }
    
    @Test("Delete Item - Removes Correct Item and Decreases Count")
    func deleteItemRemovesCorrectly() async throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Delete Me")
        sut.addItem(name: "Keep Me")
        let deleteIndexSet = IndexSet(integer: 0) // Index of "Delete Me"
        let initialCount = sut.items.count
        let deleteID = try #require(sut.items.first?.id)
        let keepID = try #require(sut.items.last?.id)

        // Act
        sut.deleteItems(at: deleteIndexSet)

        // Assert
        #expect(sut.items.count == initialCount - 1, "Count should decrease by 1")
        #expect(sut.items.contains(where: { $0.id == keepID }), "Item 'Keep Me' should remain")
        #expect(!sut.items.contains(where: { $0.id == deleteID }), "Item 'Delete Me' should be gone")
    }
    
    @Test("Move Item - Reorders Items Correctly")
    func moveItemReordersCorrectly() async throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "A")
        sut.addItem(name: "B")
        sut.addItem(name: "C")
        // Initial order: A, B, C

        // Act: Move item at index 0 ("A") to index 3 (end)
        let source = IndexSet(integer: 0)
        let destination = 3
        sut.moveItem(from: source, to: destination)

        // Assert: Order should be B, C, A
        let currentNames = sut.items.map { $0.name }
        #expect(currentNames == ["B", "C", "A"], "Items should be reordered to B, C, A. Got: \(currentNames)")
    }
    
    @Test("Total Price - Calculates Correctly with Quantity")
    func totalPriceCalculatesCorrectlyWithQuantity() async throws {
        // Arrange
        let sut = createSUT(type: .shopping) // Must be shopping type
        sut.addItem(name: "Item 1"); sut.items[0].price = 1.50; sut.items[0].quantity = 2 // Qty 2
        sut.addItem(name: "Item 2"); sut.items[1].price = 2.25; sut.items[1].quantity = 1 // Qty 1
        sut.addItem(name: "Item 3"); sut.items[2].quantity = 5 // No price, Qty 5 (should not affect total)
        sut.addItem(name: "Item 4"); sut.items[3].price = 0.50; sut.items[3].quantity = 3 // Qty 3

        // Act
        let total = sut.totalPrice

        // Assert
        // Expected: (1.50 * 2) + (2.25 * 1) + (0 * 5) + (0.50 * 3) = 3.00 + 2.25 + 0 + 1.50 = 6.75
        let expectedTotal = try #require(Decimal(string: "6.75"))
        #expect(total == expectedTotal, "Total price should factor in quantity. Expected \(expectedTotal), got \(total)")
    }
    
    @Test("Total Price - Is Zero for Non-Shopping Lists")
    func totalPriceIsZeroForTaskLists() throws {
        // Arrange
        let sut = createSUT(type: .task) // Create a Task list
        sut.addItem(name: "Task 1"); sut.items[0].price = 10.0 // Assign price (should be ignored)
        sut.items[0].quantity = 2

        // Act
        let total = sut.totalPrice

        // Assert
        #expect(total == .zero, "Total price should be zero for non-shopping list types, got \(total)")
    }
    
    @Test("Total Price - Calculates Correctly Ignoring Nil Prices")
    func totalPriceCalculatesCorrectly() async throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Item 1"); sut.items[0].price = Decimal(string: "1.50")
        sut.addItem(name: "Item 2"); sut.items[1].price = Decimal(string: "2.25")
        sut.addItem(name: "Item 3") // No price (nil)

        // Act
        let total = sut.totalPrice

        // Assert
        let expectedTotal = try #require(Decimal(string: "3.75"))
        #expect(total == expectedTotal, "Total price should sum non-nil prices. Expected \(expectedTotal), got \(total)")
    }
    
    @Test("Update Item - Only Name Changes Correctly (Keeps Qty/Price)")
    func updateItemOnlyNameKeepsQtyPrice() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let originalName = "Old Name"; let originalPrice: Decimal? = 1.00; let originalQuantity = 2
        sut.addItem(name: originalName)
        let itemIndex = try #require(sut.items.firstIndex(where: { $0.name == originalName }))
        sut.items[itemIndex].price = originalPrice
        sut.items[itemIndex].quantity = originalQuantity
        let itemID = sut.items[itemIndex].id
        let newName = "New Name"

        // Act
        // Pass original price and quantity to updateItem
        sut.updateItem(id: itemID, newName: newName, newPrice: originalPrice, newQuantity: originalQuantity)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == newName, "Name should be updated")
        #expect(updatedItem.price == originalPrice, "Price should remain unchanged")
        #expect(updatedItem.quantity == originalQuantity, "Quantity should remain unchanged")
    }

    @Test("Update Item - Only Price Changes Correctly (Value to Value)")
    func updateItemOnlyPriceValueToValue() async throws {
        // Arrange
        let sut = createSUT()
        let originalName = "Original Name"
        let originalQuantity = 3
        sut.addItem(name: originalName)
        #expect(sut.items.count == 1)
        sut.items[0].price = try #require(Decimal(string: "1.0")) // <-- Modify directly
        sut.items[0].quantity = originalQuantity
        let itemID = sut.items[0].id
        let newPrice = try #require(Decimal(string: "2.50"))

        // Act
        sut.updateItem(id: itemID, newName: originalName, newPrice: newPrice, newQuantity: originalQuantity) // Keep original name

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == originalName, "Name should remain unchanged")
        #expect(updatedItem.price == newPrice, "Price should be updated")
    }

    @Test("Update Item - Only Price Changes Correctly (Nil to Value)")
    func updateItemOnlyPriceNilToValue() async throws {
        // Arrange
        let sut = createSUT()
        let originalName = "Original Name"
        let originalQuantity = 1
        sut.addItem(name: originalName)
        #expect(sut.items.count == 1)
        sut.items[0].price = nil
        sut.items[0].quantity = originalQuantity
        let itemID = sut.items[0].id
        let newPrice = try #require(Decimal(string: "3.00"))

        // Act
        sut.updateItem(id: itemID, newName: originalName, newPrice: newPrice, newQuantity: originalQuantity)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == originalName, "Name should remain unchanged")
        #expect(updatedItem.price == newPrice, "Price should be updated from nil")
    }

    @Test("Update Item - Only Price Changes Correctly (Value to Nil)")
    func updateItemOnlyPriceValueToNil() async throws {
        // Arrange
        let sut = createSUT()
        let originalName = "Original Name"
        let originalQuantity = 4
        sut.addItem(name: originalName)
        #expect(sut.items.count == 1)
        sut.items[0].price = try #require(Decimal(string: "5.00")) // <-- Modify directly
        sut.items[0].quantity = originalQuantity
        let itemID = sut.items[0].id

        // Act
        sut.updateItem(id: itemID, newName: originalName, newPrice: nil, newQuantity: originalQuantity) // Set price to nil

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == originalName, "Name should remain unchanged")
        #expect(updatedItem.price == nil, "Price should be updated to nil")
    }
    
    @Test("Update Item - Only Quantity Changes Correctly")
    func updateItemOnlyQuantity() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let originalName = "Item"; let originalPrice: Decimal? = 5.00; let originalQuantity = 1
        sut.addItem(name: originalName)
        let itemIndex = try #require(sut.items.firstIndex(where: { $0.name == originalName }))
        sut.items[itemIndex].price = originalPrice
        sut.items[itemIndex].quantity = originalQuantity
        let itemID = sut.items[itemIndex].id
        let newQuantity = 3

        // Act
        sut.updateItem(id: itemID, newName: originalName, newPrice: originalPrice, newQuantity: newQuantity)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == originalName, "Name should remain unchanged")
        #expect(updatedItem.price == originalPrice, "Price should remain unchanged")
        #expect(updatedItem.quantity == newQuantity, "Quantity should be updated")
    }

    @Test("Update Item - Quantity Does Not Go Below 1")
    func updateItemQuantityMinimumOne() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        sut.addItem(name: "Item"); sut.items[0].quantity = 2
        let itemID = sut.items[0].id
        let invalidQuantity = 0 // Attempt to set below 1
        let invalidQuantityNegative = -5 // Attempt to set below 1

        // Act 1: Try setting to 0
        sut.updateItem(id: itemID, newName: "Item", newPrice: nil, newQuantity: invalidQuantity)
        let updatedItem1 = try #require(sut.items.first(where: { $0.id == itemID }))

        // Assert 1
        #expect(updatedItem1.quantity == 1, "Quantity should be capped at 1 when trying to set 0. Got \(updatedItem1.quantity)")

        // Act 2: Try setting to -5
        sut.updateItem(id: itemID, newName: "Item", newPrice: nil, newQuantity: invalidQuantityNegative)
        let updatedItem2 = try #require(sut.items.first(where: { $0.id == itemID }))

        // Assert 2
        #expect(updatedItem2.quantity == 1, "Quantity should be capped at 1 when trying to set negative. Got \(updatedItem2.quantity)")
    }


    @Test("Update Item - Price/Quantity Ignored for Non-Shopping List")
    func updateItemIgnoresPriceQuantityForTask() throws {
        // Arrange
        let sut = createSUT(type: .task) // TASK list
        let originalName = "Task Name"
        sut.addItem(name: originalName)
        sut.items[0].price = 5.00 // Set initial price/qty (should be ignored on update)
        sut.items[0].quantity = 3
        let itemID = sut.items[0].id
        let newName = "Updated Task Name"
        let attemptedNewPrice: Decimal? = 10.00
        let attemptedNewQuantity: Int? = 5

        // Act
        sut.updateItem(id: itemID, newName: newName, newPrice: attemptedNewPrice, newQuantity: attemptedNewQuantity)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == newName, "Name should be updated for task list")
        // Price and quantity should be reset/defaulted by the updateItem logic for non-supported types
        #expect(updatedItem.price == nil, "Price should become nil for task list during update, even if attempted. Got \(String(describing: updatedItem.price))")
        #expect(updatedItem.quantity == 1, "Quantity should become 1 for task list during update, even if attempted. Got \(updatedItem.quantity)")
    }

    @Test("Update Item - Both Name and Price Change Correctly (Keeps Qty)") // Updated test name
    func updateItemBothNameAndPriceKeepsQty() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let oldName = "Old Name"; let oldPrice: Decimal? = 1.0; let originalQuantity = 2
        sut.addItem(name: oldName)
        let itemIndex = try #require(sut.items.firstIndex(where: {$0.name == oldName }))
        sut.items[itemIndex].price = oldPrice
        sut.items[itemIndex].quantity = originalQuantity
        let itemID = sut.items[itemIndex].id
        let newName = "New Name"; let newPrice: Decimal? = 9.99

        // Act
        sut.updateItem(id: itemID, newName: newName, newPrice: newPrice, newQuantity: originalQuantity) // Pass original quantity

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == newName, "Name should be updated")
        #expect(updatedItem.price == newPrice, "Price should be updated")
        #expect(updatedItem.quantity == originalQuantity, "Quantity should remain unchanged")
    }

    @Test("Update Item - No Change If New Name Is Empty")
    func updateItemNoChangeOnEmptyName() async throws {
        // Arrange
        let sut = createSUT()
        let originalName = "Keep This Name"
        let originalPrice = try #require(Decimal(string: "1.0"))
        let originalQuantity = 1
        sut.addItem(name: originalName)
        #expect(sut.items.count == 1)
        sut.items[0].price = originalPrice // <-- Modify directly
        sut.items[0].quantity = originalQuantity
        let itemID = sut.items[0].id
        let emptyName = "   "

        // Act
        sut.updateItem(id: itemID, newName: emptyName, newPrice: originalPrice, newQuantity: originalQuantity)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == originalName, "Name should NOT be updated with empty string")
        #expect(updatedItem.price == originalPrice, "Price should remain unchanged")
    }

     @Test("Update Item - Does Nothing For Invalid ID")
     func updateItemInvalidID() async throws {
         // Arrange
         let sut = createSUT()
         sut.addItem(name: "Existing Item")
         let invalidID = UUID() // A random, non-existent ID
         let initialItems = sut.items // Copy for comparison

         // Act
         sut.updateItem(id: invalidID, newName: "Attempt Update", newPrice: 10.0, newQuantity: 5)

         // Assert
         // Check if the items array is identical to the initial one
         #expect(sut.items.count == initialItems.count, "Item count should not change")
         // This comparison relies on ShoppingItem conforming to Equatable (which it does via Hashable)
         #expect(sut.items == initialItems, "Items array should be unchanged for invalid ID")
     }

    @Test("Update List Name - Changes Correctly")
    func updateListNameChangesCorrectly() async throws {
        // Arrange
        let sut = createSUT(name: "Old List Name")
        let newListName = "My Groceries"

        // Act
        sut.updateName(newName: newListName)

        // Assert
        #expect(sut.name == newListName, "List name should be updated")
    }

    @Test("Update List Name - No Change If New Name Is Empty")
    func updateListNameNoChangeOnEmptyName() async throws {
        // Arrange
        let originalListName = "Important List"
        let sut = createSUT(name: originalListName)
        let emptyName = " \n\t " // Whitespace/newlines

        // Act
        sut.updateName(newName: emptyName)

        // Assert
        #expect(sut.name == originalListName, "List name should NOT be updated with empty string")
    }


    // --- Edge Case Tests ---

    @Test("Toggle Item - Does Nothing For Invalid ID")
    func toggleItemInvalidID() async throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "An Item")
        let invalidID = UUID()
        let initialItems = sut.items // Copy for comparison

        // Act
        sut.toggleItem(id: invalidID)

        // Assert
        #expect(sut.items == initialItems, "Items array should be unchanged when toggling invalid ID")
    }

    @Test("Delete Items - Does Nothing On Empty List")
    func deleteItemsEmptyList() async throws {
        // Arrange
        let sut = createSUT() // Starts empty
        let indexSet = IndexSet(integer: 0) // IndexSet that would be invalid anyway

        // Act
        sut.deleteItems(at: indexSet)

        // Assert
        #expect(sut.items.isEmpty, "List should remain empty")
    }

    @Test("Move Item - Does Nothing On Single Item List")
     func moveItemSingleItemList() async throws {
         // Arrange
         let sut = createSUT()
         sut.addItem(name: "Solo")
         let initialItems = sut.items
         let source = IndexSet(integer: 0)
         let destination = 1 // Attempt to move past end

         // Act
         sut.moveItem(from: source, to: destination)

         // Assert
         #expect(sut.items == initialItems, "Items should remain unchanged for single item list move")
     }

     // (Optional) Basic Codable Test - requires ShoppingItem to be Equatable
    @Test("Codable - Encodes and Decodes Correctly with Type and Quantity")
    func listCodableWithTypeAndQuantity() throws {
        // Arrange
        let originalList = createSUT(name: "Codable Shopping", type: .shopping) // Explicitly shopping
        originalList.addItem(name: "Item 1"); originalList.items[0].price = 1.23; originalList.items[0].quantity = 3
        originalList.addItem(name: "Item 2"); originalList.items[1].isChecked = true; originalList.items[1].checkedTimestamp = Date(); originalList.items[1].quantity = 1

        let originalTaskList = createSUT(name: "Codable Task", type: .task) // Explicitly task
        originalTaskList.addItem(name: "Task A"); originalTaskList.items[0].quantity = 5 // Qty should still encode/decode
        originalTaskList.items[0].price = 99.99 // Price should still encode/decode, even if not used by logic


        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let decoder = JSONDecoder()

        // Act: Encode/Decode Shopping List
        let encodedData = try encoder.encode(originalList)
        // print("Encoded Shopping:\n\(String(data: encodedData, encoding: .utf8) ?? "Encode failed")") // Debug
        let decodedList = try decoder.decode(ShoppingList.self, from: encodedData)

        // Act: Encode/Decode Task List
        let encodedTaskData = try encoder.encode(originalTaskList)
        // print("Encoded Task:\n\(String(data: encodedTaskData, encoding: .utf8) ?? "Encode failed")") // Debug
        let decodedTaskList = try decoder.decode(ShoppingList.self, from: encodedTaskData)


        // Assert Shopping List
        #expect(decodedList.id == originalList.id)
        #expect(decodedList.name == originalList.name)
        #expect(decodedList.listType == .shopping) // Check type
        #expect(decodedList.items.count == originalList.items.count)
        #expect(decodedList.items == originalList.items) // Relies on ShoppingItem Equatable
        #expect(decodedList.totalPrice == originalList.totalPrice) // Check calculated price

        // Assert Task List
        #expect(decodedTaskList.id == originalTaskList.id)
        #expect(decodedTaskList.name == originalTaskList.name)
        #expect(decodedTaskList.listType == .task) // Check type
        #expect(decodedTaskList.items.count == originalTaskList.items.count)
        #expect(decodedTaskList.items == originalTaskList.items)
        #expect(decodedTaskList.totalPrice == .zero) // Total price should be zero for tasks
    }
}
