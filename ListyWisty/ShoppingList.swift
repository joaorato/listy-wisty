//
//  ShoppingList.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI
import Foundation

class ShoppingList: ObservableObject, Identifiable, Hashable, Codable {
    @Published var name: String
    @Published var items: [ShoppingItem]
    var listType: ListType
    var createdAt: Date
    var modifiedAt: Date
    let id: UUID
    
    init(id: UUID = UUID(), name: String, items: [ShoppingItem] = [], listType: ListType = .shopping, createdAt: Date? = nil, modifiedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.items = items
        self.listType = listType
        let now = Date()
        self.createdAt = createdAt ?? now
        self.modifiedAt = modifiedAt ?? now
    }
    
    // --- Sorting Logic Helper (can be static or private) ---
    // Encapsulates the comparison logic used both for display (if needed elsewhere)
    // and for finding insertion points.
    private static func sortPredicate(item1: ShoppingItem, item2: ShoppingItem) -> Bool {
        if !item1.isChecked && item2.isChecked { return true } // Unchecked before checked
        if item1.isChecked && !item2.isChecked { return false } // Checked after unchecked

        if item1.isChecked && item2.isChecked { // Both checked: Sort by timestamp DESC (newest first)
            let ts1 = item1.checkedTimestamp ?? Date.distantPast
            let ts2 = item2.checkedTimestamp ?? Date.distantPast
            return ts1 > ts2
        }

        // Both unchecked: maintain relative order (or add other criteria like name)
        // Returning false here relies on sort stability or original order for unchecked items.
        return false
    }
    
    // Computed propery for total price
    var totalPrice: Decimal {
        // Only calculate total price for shopping lists
        guard listType == .shopping else { return .zero }
        // Use reduce to sum up the prices.
        // Treat items with nil price as 0 for the total calculation
        return items.reduce(Decimal.zero) { sum, item in
            // Multiply price by quantity for shopping lists
            let itemPrice = item.price ?? .zero
            return sum + (itemPrice * item.quantity)
        }
    }
    
    var completionPercentage: Double {
        guard listType == .task else { return 0.0 } // Only for task lists
        guard !items.isEmpty else { return 0.0 } // Empty list is 0% complete

        let checkedCount = items.filter { $0.isChecked }.count
        return Double(checkedCount) / Double(items.count)
    }
    
    // MARK: - Item Management Methods
    func addItem(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }
        let newItem = ShoppingItem(name: trimmedName)
        // Append ensures new unchecked items appear at the end of the unchecked section
        items.append(newItem)
    }
    
    func toggleItem(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }

        // 1. Toggle the state and timestamp
        items[index].isChecked.toggle()
        items[index].checkedTimestamp = items[index].isChecked ? Date() : nil

        // 2. Get the item that was just modified
        let toggledItem = items[index]

        // 3. Remove the item temporarily to find its new correct position
        items.remove(at: index)

        // 4. Find the correct insertion index based on the sorting rules
        let newIndex = items.firstIndex { existingItem in
            // We want to insert 'toggledItem' *before* the first 'existingItem'
            // that should come *after* 'toggledItem' according to our sort predicate.
            // The sort predicate returns 'true' if item1 should come before item2.
            // So, we find the first existingItem where sortPredicate(toggledItem, existingItem) is true.
            Self.sortPredicate(item1: toggledItem, item2: existingItem)
        } ?? items.endIndex // If no such item exists, insert at the end

        // 5. Insert the item at its new sorted position
        items.insert(toggledItem, at: newIndex)

        // @Published takes care of notifying observers about the array change.
        // The View observing 'list' (ShoppingListDetailView) and calling
        // viewModel.listDidChange() will handle saving.
    }
    
    func updateItem(id: UUID, newName: String, newPrice: Decimal?, newQuantity: Decimal?, newUnit: String?) {
        // 1. Find the item index
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            print("⚠️ updateItem failed: Could not find item with ID \(id)")
            return
        }

        // 2. Prepare Potential New Name
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Keep track if any actual change happened
        var didUpdate = false

        // 3. Update Name (if valid and different)
        if !trimmedNewName.isEmpty && items[index].name != trimmedNewName {
            items[index].name = trimmedNewName
            print("   Item \(id): Updated Name to '\(trimmedNewName)'")
            didUpdate = true
        }

        // 4. Update Price (conditional on list type)
        if listType.supportsPrice {
            // Only update if the new price value is actually different from the current one
            if items[index].price != newPrice {
                items[index].price = newPrice
                print("   Item \(id): Updated Price to \(String(describing: newPrice))")
                didUpdate = true
            }
        } else {
            // Type does NOT support price. Ensure item's price is nil.
            if items[index].price != nil { // If it currently has a non-nil price...
                items[index].price = nil // ...reset it to nil.
                print("   Item \(id): Reset Price to nil (type '\(listType.rawValue)' doesn't support price)")
                didUpdate = true
            }
        }

        // 5. Update Quantity (conditional on list type)
        if listType.supportsQuantity {
            // Validate the incoming quantity: ensure it's at least 0.001.
            // Default to 1 if nil is somehow passed.
            let validatedQuantity = max(0.001, newQuantity ?? 1.0) // Apply validation *before* comparison
            // Only update if the *validated* quantity is different from the current one.
            if items[index].quantity != validatedQuantity {
                items[index].quantity = validatedQuantity // Assign the validated value
                print("   Item \(id): Updated Quantity to \(validatedQuantity)")
                didUpdate = true
            }
            
            // --- Update Unit ---
            // Treat empty string as nil for consistency
            let validatedUnit: String? = newUnit?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty() // Use helper extension below
            if items[index].unit != validatedUnit {
                 items[index].unit = validatedUnit
                 print("   Item \(id): Updated Unit to '\(validatedUnit ?? "nil")'")
                 didUpdate = true
            }
        } else {
            // Type does NOT support quantity. Ensure item's quantity is 1.
            if items[index].quantity != 1.0 { // If it's currently not 1...
                items[index].quantity = 1.0 // ...reset it to 1.
                print("   Item \(id): Reset Quantity to 1 (type '\(listType.rawValue)' doesn't support quantity)")
                didUpdate = true
            }
            if items[index].unit != nil { // Also reset unit if type doesn't support quantity
                items[index].unit = nil
                print("   Item \(id): Reset Unit to nil (type '\(listType.displayName)' doesn't support quantity/unit)")
                didUpdate = true
            }
        }

        // 6. Log if updates happened (Optional)
        if !didUpdate {
            print("   Item \(id): No changes detected during update call.")
        }
        
        // IMPORTANT: No need to call objectWillChange.send() or viewModel.listDidChange() here.
        // Direct modification of `items[index]` properties, since `items` is @Published,
        // automatically notifies observers of the ShoppingList object (like ShoppingListDetailView).
        // The ShoppingListDetailView is responsible for calling viewModel.listDidChange() *after*
        // this `updateItem` function returns, to trigger the save.
    }
    
    func updateName(newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && self.name != trimmedName {
            self.name = trimmedName
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
    
    // MARK: - Conformance to Hashable
    static func == (lhs: ShoppingList, rhs: ShoppingList) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable Conformance (Manual Implementation)

    // Define coding keys to map properties to JSON keys
    enum CodingKeys: String, CodingKey {
        case id, name, items, listType, createdAt, modifiedAt
    }
    
    // Initializer for decoding from JSON
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode regular properties directly
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        items = try container.decode([ShoppingItem].self, forKey: .items)
        // Note: @Published properties are initialized with decoded values
        listType = try container.decodeIfPresent(ListType.self, forKey: .listType) ?? .shopping
        let now = Date()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? now
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? now
    }
    
    // Function for encoding to JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode properties directly
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(items, forKey: .items)
        try container.encode(listType, forKey: .listType)
        try container.encode(createdAt, forKey: .createdAt) // <-- Encode dates
        try container.encode(modifiedAt, forKey: .modifiedAt) // <-- Encode dates
    }
}

extension String {
    /// Returns nil if the string is empty after trimming whitespace, otherwise returns the trimmed string.
    func nilIfEmpty() -> String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
