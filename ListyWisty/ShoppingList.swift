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
    
    let id: UUID
    
    init(id: UUID = UUID(), name: String, items: [ShoppingItem] = []) {
        self.id = id
        self.name = name
        self.items = items
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
        // Use reduce to sum up the prices.
        // Treat items with nil price as 0 for the total calculation
        // FUTURE: When quantity is added, this calculation will change to:
        // sum += (item.oruce ?? .zero) * Decimal(item.quantity)
        items.reduce(Decimal.zero) { sum, item in
            sum + (item.price ?? .zero) // Add item's price, or 0 if nil
        }
    }
    
    
    // MARK: - Item Management Methods
    func addItem(name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newItem = ShoppingItem(name: name)
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
    
    func updateItem(id: UUID, newName: String, newPrice: Decimal?) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if update is actually needed before sending notification
            if !trimmedNewName.isEmpty && items[index].name != trimmedNewName {
                items[index].name = trimmedNewName
            }
            if items[index].price != newPrice {
                items[index].price = newPrice
            }
        }
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
        case id, name, items
    }
    
    // Initializer for decoding from JSON
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode regular properties directly
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        items = try container.decode([ShoppingItem].self, forKey: .items)
        // Note: @Published properties are initialized with decoded values
    }
    
    // Function for encoding to JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode properties directly
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(items, forKey: .items)
    }
}
