//
//  ListyWistyTests.swift
//  ListyWistyTests
//
//  Created by João Rato on 29/03/2025.
//

import Testing
import Foundation
@testable import ListyWisty // Ensure this matches your app target name

@Suite("ShoppingList Model Tests") // Organize tests with a Suite
struct ListyWistyTests {

    // Helper to create a list instance for tests
    private func createSUT(name: String = "Test List", type: ListType = .shopping) -> ShoppingList {
        return ShoppingList(name: name, listType: type)
    }

    // MARK: - Add Item Tests

    @Test("Add Item - Basic Adds Item with Name and Defaults")
    func addItemBasic() throws {
        // Arrange
        let sut = createSUT()
        let initialCount = sut.items.count
        let itemName = "Milk"

        // Act
        // Use the unified addItem method (async context not strictly needed here, but keep for consistency if ViewModel uses await)
        sut.addItem(name: itemName) // Pass list ref if addItem needs it (based on final ViewModel impl.)
                                                               // For direct model test, simpler SUT method can be used if refactored
        // --- OR --- If you have a direct sync add method on SUT for testing:
        // sut.addItem(name: itemName) // Assuming direct add method for testability

        // Assert
        #expect(sut.items.count == initialCount + 1, "Item count should increase by 1")
        let addedItem = try #require(sut.items.last, "Should be able to get the last added item")
        #expect(addedItem.name == itemName, "Added item should have the correct name")
        #expect(!addedItem.isChecked, "Newly added item should be unchecked")
        #expect(addedItem.quantity == 1, "Newly added item should have quantity 1 by default")
        #expect(addedItem.unit == nil, "Newly added item should have nil unit by default")
        #expect(addedItem.price == nil, "Newly added item should have nil price by default")
    }

    @Test("Add Item - With All Details Sets Properties Correctly")
    func addItemWithAllDetails() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let itemName = "Apples"; let quantity = 5; let unit = "kg"; let price: Decimal? = 3.99

        // Act
        // Assuming addItem exists directly on ShoppingList for testing
        // If it only exists on ViewModel, you'd test the ViewModel instead
        sut.addItem(name: itemName, quantity: quantity, unit: unit, price: price)

        // Assert
        #expect(sut.items.count == 1)
        let addedItem = try #require(sut.items.first)
        #expect(addedItem.name == itemName)
        #expect(addedItem.quantity == quantity)
        #expect(addedItem.unit == unit)
        #expect(addedItem.price == price)
        #expect(!addedItem.isChecked)
    }

    @Test("Add Item - Does Not Add Empty Name")
    func addItemDoesNotAddEmptyName() throws {
        // Arrange
        let sut = createSUT()
        let initialCount = sut.items.count
        let emptyName = "   " // Whitespace only

        // Act
        sut.addItem(name: emptyName) // Assume direct add method

        // Assert
        #expect(sut.items.count == initialCount, "Item count should not increase for empty name")
    }

    @Test("Add Item - Trims Whitespace from Name")
    func addItemTrimsWhitespace() throws {
        // Arrange
        let sut = createSUT()
        let nameWithSpace = "  Cheese \n "
        let expectedName = "Cheese"

        // Act
        sut.addItem(name: nameWithSpace)

        // Assert
        #expect(sut.items.count == 1)
        let addedItem = try #require(sut.items.first)
        #expect(addedItem.name == expectedName, "Whitespace should be trimmed from name")
    }

    // MARK: - Toggle Item Tests

    @Test("Toggle Item - Check Moves To Checked Section, Sets Timestamp, Sorts Correctly")
    func toggleItemCheckMovesSetsTimestampSorts() throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Bread") // Will be checked
        sut.addItem(name: "Eggs")  // Will remain unchecked
        let breadID = try #require(sut.items.first?.id, "Should find Bread item ID")

        // Act
        sut.toggleItem(id: breadID) // Check "Bread"

        // Assert State
        let breadItem = try #require(sut.items.first(where: { $0.id == breadID }), "Failed to find Bread after toggle")
        #expect(breadItem.isChecked)
        #expect(breadItem.checkedTimestamp != nil)

        // Assert Position
        #expect(sut.items.count == 2)
        #expect(sut.items[0].name == "Eggs", "Unchecked item 'Eggs' should now be first")
        #expect(sut.items[1].name == "Bread", "Checked item 'Bread' should now be last")
    }

    @Test("Toggle Item - Uncheck Moves To Unchecked Section, Clears Timestamp, Sorts Correctly")
    func toggleItemUncheckMovesClearsTimestampSorts() throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Juice")  // Unchecked
        sut.addItem(name: "Butter") // Will be checked then unchecked
        let butterID = try #require(sut.items.last?.id)

        sut.toggleItem(id: butterID) // Check "Butter" first
        #expect(sut.items.last?.id == butterID)
        #expect(sut.items.last?.isChecked == true)
        let _ = try #require(sut.items.last?.checkedTimestamp)

        // Act: Uncheck "Butter"
        sut.toggleItem(id: butterID)

        // Assert State
        let butterItem = try #require(sut.items.first(where: { $0.id == butterID }))
        #expect(!butterItem.isChecked)
        #expect(butterItem.checkedTimestamp == nil)

        // Assert Position (assuming relative order of unchecked is maintained)
        #expect(sut.items.count == 2)
        #expect(sut.items[0].name == "Juice")
        #expect(sut.items[1].name == "Butter")
    }

    @Test("Toggle Item - Multiple Checked Items Sort By Timestamp Descending")
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func toggleItemMultipleCheckedSortsByTimestampDescending() async throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Item A"); let idA = sut.items[0].id
        sut.addItem(name: "Item B"); let idB = sut.items[1].id
        sut.addItem(name: "Item C"); let idC = sut.items[2].id

        // Act: Check items in order C, A, B with slight delays
        sut.toggleItem(id: idC); try await Task.sleep(for: .milliseconds(10))
        sut.toggleItem(id: idA); try await Task.sleep(for: .milliseconds(10))
        sut.toggleItem(id: idB)

        // Assert: Order should be B, A, C (newest checked first)
        #expect(sut.items.count == 3)
        #expect(sut.items.allSatisfy { $0.isChecked })
        #expect(sut.items[0].id == idB)
        #expect(sut.items[1].id == idA)
        #expect(sut.items[2].id == idC)
    }

    @Test("Toggle Item - Does Nothing For Invalid ID")
    func toggleItemInvalidID() throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "An Item")
        let invalidID = UUID()
        let initialItems = sut.items

        // Act
        sut.toggleItem(id: invalidID)

        // Assert
        #expect(sut.items == initialItems, "Items array should be unchanged when toggling invalid ID")
    }


    // MARK: - Delete Item Tests

    @Test("Delete Item - Removes Correct Item and Decreases Count")
    func deleteItemRemovesCorrectly() throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "Delete Me")
        sut.addItem(name: "Keep Me")
        let deleteIndexSet = IndexSet(integer: 0)
        let initialCount = sut.items.count
        let deleteID = try #require(sut.items.first?.id)
        let keepID = try #require(sut.items.last?.id)

        // Act
        sut.deleteItems(at: deleteIndexSet)

        // Assert
        #expect(sut.items.count == initialCount - 1)
        #expect(sut.items.contains(where: { $0.id == keepID }))
        #expect(!sut.items.contains(where: { $0.id == deleteID }))
    }

    @Test("Delete Items - Does Nothing On Empty List")
    func deleteItemsEmptyList() throws {
        // Arrange
        let sut = createSUT()
        let indexSet = IndexSet(integer: 0)

        // Act
        sut.deleteItems(at: indexSet)

        // Assert
        #expect(sut.items.isEmpty)
    }

    // MARK: - Move Item Tests

    @Test("Move Item - Reorders Items Correctly")
    func moveItemReordersCorrectly() throws {
        // Arrange
        let sut = createSUT()
        sut.addItem(name: "A"); sut.addItem(name: "B"); sut.addItem(name: "C")
        let source = IndexSet(integer: 0)
        let destination = 3 // Move "A" to the end

        // Act
        sut.moveItem(from: source, to: destination)

        // Assert: Order should be B, C, A
        let currentNames = sut.items.map { $0.name }
        #expect(currentNames == ["B", "C", "A"], "Items should be reordered to B, C, A. Got: \(currentNames)")
    }

    @Test("Move Item - Does Nothing On Single Item List")
     func moveItemSingleItemList() throws {
         // Arrange
         let sut = createSUT(); sut.addItem(name: "Solo")
         let initialItems = sut.items
         let source = IndexSet(integer: 0)
         let destination = 1

         // Act
         sut.moveItem(from: source, to: destination)

         // Assert
         #expect(sut.items == initialItems)
     }

    // MARK: - Total Price Tests

    @Test("Total Price - Calculates Correctly (Ignores Quantity)")
    func totalPriceCalculatesCorrectly() throws {
        // Arrange
        let sut = createSUT(type: .shopping) // Must be shopping type
        sut.addItem(name: "Item 1", quantity: 2, price: 1.50)  // Price 3.00
        sut.addItem(name: "Item 2", quantity: 1, price: 2.25)  // Price 2.25
        sut.addItem(name: "Item 3", quantity: 5)               // Price nil (ignored)
        sut.addItem(name: "Item 4", quantity: 3, price: 0.50)  // Price 1.50

        // Act
        let total = sut.totalPrice

        // Assert
        // Expected: 3.00 + 2.25 + 0 + 1.50 = 6.75
        let expectedTotal = try #require(Decimal(string: "6.75"))
        #expect(total == expectedTotal, "Total price should sum item prices, taking quantity into account. Expected \(expectedTotal), got \(total)")
    }

    @Test("Total Price - Is Zero for Non-Shopping Lists")
    func totalPriceIsZeroForTaskLists() throws {
        // Arrange
        let sut = createSUT(type: .task)
        sut.addItem(name: "Task 1", quantity: 2, price: 10.00) // Price/Qty should be ignored

        // Act
        let total = sut.totalPrice

        // Assert
        #expect(total == .zero, "Total price should be zero for non-shopping list types, got \(total)")
    }

    // MARK: - Update Item Tests

    @Test("Update Item - Only Name Changes Correctly (Keeps Qty/Price/Unit)")
    func updateItemOnlyName() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let originalName = "Old Name"; let originalPrice: Decimal? = 1.00; let originalQuantity = 2; let originalUnit: String? = "box"
        sut.addItem(name: originalName, quantity: originalQuantity, unit: originalUnit, price: originalPrice)
        let itemID = try #require(sut.items.first?.id)
        let newName = "New Name"

        // Act
        // Pass original values for unchanged fields
        sut.updateItem(id: itemID, newName: newName, newPrice: originalPrice, newQuantity: originalQuantity, newUnit: originalUnit)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == newName)
        #expect(updatedItem.price == originalPrice)
        #expect(updatedItem.quantity == originalQuantity)
        #expect(updatedItem.unit == originalUnit)
    }

    @Test("Update Item - Only Price Changes Correctly")
    func updateItemOnlyPrice() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let name = "Item"; let quantity = 3; let unit = "L"
        sut.addItem(name: name, quantity: quantity, unit: unit, price: 1.00)
        let itemID = try #require(sut.items.first?.id)
        let newPrice: Decimal? = 2.50

        // Act
        sut.updateItem(id: itemID, newName: name, newPrice: newPrice, newQuantity: quantity, newUnit: unit)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == name)
        #expect(updatedItem.price == newPrice)
        #expect(updatedItem.quantity == quantity)
        #expect(updatedItem.unit == unit)
    }

    @Test("Update Item - Only Quantity Changes Correctly")
    func updateItemOnlyQuantity() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let name = "Item"; let price: Decimal? = 5.00; let unit: String? = "pack"; let quantity = 1
        sut.addItem(name: name, quantity: quantity, unit: unit, price: price)
        let itemID = try #require(sut.items.first?.id)
        let newQuantity = 3

        // Act
        sut.updateItem(id: itemID, newName: name, newPrice: price, newQuantity: newQuantity, newUnit: unit)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == name)
        #expect(updatedItem.price == price)
        #expect(updatedItem.quantity == newQuantity)
        #expect(updatedItem.unit == unit)
    }

    @Test("Update Item - Only Unit Changes Correctly (Nil to Value)")
    func updateItemUnitNilToValue() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let name = "Water"; let price: Decimal? = 0.99; let quantity = 2; let originalUnit: String? = nil
        sut.addItem(name: name, quantity: quantity, unit: originalUnit, price: price)
        let itemID = try #require(sut.items.first?.id)
        let newUnit = "bottle"

        // Act
        sut.updateItem(id: itemID, newName: name, newPrice: price, newQuantity: quantity, newUnit: newUnit)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == name)
        #expect(updatedItem.price == price)
        #expect(updatedItem.quantity == quantity)
        #expect(updatedItem.unit == newUnit, "Unit should be updated from nil")
    }

    @Test("Update Item - Only Unit Changes Correctly (Value to Nil)")
    func updateItemUnitValueToNil() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let name = "Flour"; let price: Decimal? = 2.49; let quantity = 1; let originalUnit: String? = "bag"
        sut.addItem(name: name, quantity: quantity, unit: originalUnit, price: price)
        let itemID = try #require(sut.items.first?.id)
        let newUnit: String? = nil

        // Act
        sut.updateItem(id: itemID, newName: name, newPrice: price, newQuantity: quantity, newUnit: newUnit)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == name)
        #expect(updatedItem.price == price)
        #expect(updatedItem.quantity == quantity)
        #expect(updatedItem.unit == newUnit, "Unit should be updated to nil")
    }

     @Test("Update Item - Only Unit Changes Correctly (Value to Value)")
    func updateItemUnitValueToValue() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let name = "Rice"; let price: Decimal? = 5.00; let quantity = 1; let originalUnit: String? = "5lb bag"
        sut.addItem(name: name, quantity: quantity, unit: originalUnit, price: price)
        let itemID = try #require(sut.items.first?.id)
        let newUnit = "10lb bag"

        // Act
        sut.updateItem(id: itemID, newName: name, newPrice: price, newQuantity: quantity, newUnit: newUnit)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == name)
        #expect(updatedItem.price == price)
        #expect(updatedItem.quantity == quantity)
        #expect(updatedItem.unit == newUnit, "Unit should be updated to new value")
    }

    @Test("Update Item - Only Unit Changes Correctly (Value to Empty String -> Nil)")
    func updateItemUnitValueToEmpty() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let name = "Salt"; let price: Decimal? = 1.10; let quantity = 1; let originalUnit: String? = "container"
        sut.addItem(name: name, quantity: quantity, unit: originalUnit, price: price)
        let itemID = try #require(sut.items.first?.id)
        let newUnit = "   " // Empty string after trimming

        // Act
        sut.updateItem(id: itemID, newName: name, newPrice: price, newQuantity: quantity, newUnit: newUnit)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == name)
        #expect(updatedItem.price == price)
        #expect(updatedItem.quantity == quantity)
        #expect(updatedItem.unit == nil, "Unit should become nil when updated with empty string")
    }

    @Test("Update Item - Quantity Does Not Go Below 1")
    func updateItemQuantityMinimumOne() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        sut.addItem(name: "Item")
        let itemID = try #require(sut.items.first?.id)

        // Act 1: Try setting to 0
        sut.updateItem(id: itemID, newName: "Item", newPrice: nil, newQuantity: 0, newUnit: nil)
        let updatedItem1 = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem1.quantity == 1, "Quantity should be capped at 1 when trying to set 0")

        // Act 2: Try setting to -5
        sut.updateItem(id: itemID, newName: "Item", newPrice: nil, newQuantity: -5, newUnit: nil)
        let updatedItem2 = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem2.quantity == 1, "Quantity should be capped at 1 when trying to set negative")
    }

    @Test("Update Item - Price/Quantity/Unit Ignored for Non-Shopping List")
    func updateItemIgnoresFieldsForTask() throws {
        // Arrange
        let sut = createSUT(type: .task)
        sut.addItem(name: "Task Name", quantity: 3, unit: "hours", price: 5.00) // Set initial values
        let itemID = try #require(sut.items.first?.id)
        let newName = "Updated Task Name"
        let attemptedNewPrice: Decimal? = 10.00
        let attemptedNewQuantity: Int? = 5
        let attemptedNewUnit: String? = "days"

        // Act
        sut.updateItem(id: itemID, newName: newName, newPrice: attemptedNewPrice, newQuantity: attemptedNewQuantity, newUnit: attemptedNewUnit)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == newName, "Name should be updated for task list")
        #expect(updatedItem.price == nil, "Price should become nil for task list during update")
        #expect(updatedItem.quantity == 1, "Quantity should become 1 for task list during update")
        #expect(updatedItem.unit == nil, "Unit should become nil for task list during update")
    }

    @Test("Update Item - No Change If New Name Is Empty")
    func updateItemNoChangeOnEmptyName() throws {
        // Arrange
        let sut = createSUT(type: .shopping)
        let originalName = "Keep Name"
        sut.addItem(name: originalName, quantity: 1, unit: nil, price: 1.0)
        let itemID = try #require(sut.items.first?.id)
        let emptyName = "   "

        // Act
        sut.updateItem(id: itemID, newName: emptyName, newPrice: 1.0, newQuantity: 1, newUnit: nil)

        // Assert
        let updatedItem = try #require(sut.items.first(where: { $0.id == itemID }))
        #expect(updatedItem.name == originalName, "Name should NOT be updated with empty string")
    }

     @Test("Update Item - Does Nothing For Invalid ID")
     func updateItemInvalidID() throws {
         // Arrange
         let sut = createSUT()
         sut.addItem(name: "Existing Item")
         let invalidID = UUID()
         let initialItems = sut.items

         // Act
         sut.updateItem(id: invalidID, newName: "Attempt Update", newPrice: 10.0, newQuantity: 5, newUnit: "invalid")

         // Assert
         #expect(sut.items == initialItems, "Items array should be unchanged for invalid ID")
     }

    // MARK: - Update List Name Tests

    @Test("Update List Name - Changes Correctly")
    func updateListNameChangesCorrectly() throws {
        // Arrange
        let sut = createSUT(name: "Old List Name")
        let newListName = "My Groceries"

        // Act
        sut.updateName(newName: newListName)

        // Assert
        #expect(sut.name == newListName)
    }

    @Test("Update List Name - No Change If New Name Is Empty")
    func updateListNameNoChangeOnEmptyName() throws {
        // Arrange
        let originalListName = "Important List"
        let sut = createSUT(name: originalListName)
        let emptyName = " \n\t "

        // Act
        sut.updateName(newName: emptyName)

        // Assert
        #expect(sut.name == originalListName)
    }

    // MARK: - Codable Tests

    @Test("Codable - Encodes and Decodes Correctly with Type, Quantity, and Unit")
    func listCodable() throws {
        // Arrange
        let originalList = createSUT(name: "Codable Shopping", type: .shopping)
        originalList.addItem(name: "Item 1", quantity: 3, unit: "kg", price: 1.23)
        originalList.addItem(name: "Item 2", quantity: 1, unit: nil, price: 5.00)
        originalList.items[1].isChecked = true; originalList.items[1].checkedTimestamp = Date()

        let originalTaskList = createSUT(name: "Codable Task", type: .task)
        originalTaskList.addItem(name: "Task A", quantity: 5, unit: "steps", price: 99.99) // Qty/Unit/Price still encode/decode

        let encoder = JSONEncoder(); encoder.outputFormatting = .prettyPrinted
        let decoder = JSONDecoder()

        // Act: Encode/Decode Shopping List
        let encodedData = try encoder.encode(originalList)
        let decodedList = try decoder.decode(ShoppingList.self, from: encodedData)

        // Act: Encode/Decode Task List
        let encodedTaskData = try encoder.encode(originalTaskList)
        let decodedTaskList = try decoder.decode(ShoppingList.self, from: encodedTaskData)

        // Assert Shopping List
        #expect(decodedList.id == originalList.id)
        #expect(decodedList.name == originalList.name)
        #expect(decodedList.listType == .shopping)
        #expect(decodedList.items.count == originalList.items.count)
        #expect(decodedList.items == originalList.items, "Decoded shopping items should match original") // Relies on ShoppingItem Equatable
        #expect(decodedList.items.first?.unit == "kg")
        #expect(decodedList.items.last?.unit == nil)
        #expect(decodedList.totalPrice == originalList.totalPrice) // totalPrice logic updated

        // Assert Task List
        #expect(decodedTaskList.id == originalTaskList.id)
        #expect(decodedTaskList.name == originalTaskList.name)
        #expect(decodedTaskList.listType == .task)
        #expect(decodedTaskList.items.count == originalTaskList.items.count)
        #expect(decodedTaskList.items == originalTaskList.items, "Decoded task items should match original")
        #expect(decodedTaskList.items.first?.unit == "steps") // Unit still decodes
        #expect(decodedTaskList.totalPrice == .zero) // Total price should be zero for tasks
    }
}

// Helper extension for ShoppingList to simplify adding items in tests
// Note: This assumes addItem doesn't NEED the ViewModel context for the *model* logic itself.
// If addItem logic relies heavily on ViewModel state, testing the ViewModel is necessary.
extension ShoppingList {
    // Synchronous helper for adding items in tests
    func addItem(name: String, quantity: Int = 1, unit: String? = nil, price: Decimal? = nil) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let finalQuantity = max(1, quantity)
        let finalUnit = unit?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()

        let newItem = ShoppingItem(
            name: trimmedName,
            price: price,
            quantity: finalQuantity,
            unit: finalUnit
        )
        items.append(newItem) // Directly modify items for test simplicity
    }
}
