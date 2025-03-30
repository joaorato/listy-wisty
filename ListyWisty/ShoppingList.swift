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
    
    // Computed property for sorted items
    var sortedItems: [ShoppingItem] {
        items.sorted{ (item1, item2) -> Bool in
            // Rule 1: Uncheked items come before checked items
            if !item1.isChecked && item2.isChecked {
                return true
            }
            if item1.isChecked && !item2.isChecked {
                return false
            }
            
            // Rule 2: If both are checked, sort by timestamp descending (newest first)
            if item1.isChecked && item2.isChecked {
                // Handle potential nil timestamps defensively, though they should exist if checked
                let ts1 = item1.checkedTimestamp ?? Date.distantPast
                let ts2 = item2.checkedTimestamp ?? Date.distantPast
                return ts1 > ts2 // Most recent checked item first
            }
            
            // Rule 3: If both are unchecked, maintain their relative order (or sort alphabetically, etc.)
            // For now, we rely on the stability of the sort if they are equal according to rules above.
            // If we want alphabetical for unchecked:
            // if !item1.isChecked && !item2.isChecked {
            //     return item1.name < item2.name
            // }
            return false // Keep relative order for unchecked items
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
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isChecked.toggle()
            // Update timestamp when checked, clear when unchecked
            items[index].checkedTimestamp = items[index].isChecked ? Date() : nil
            // Note: Modifying items array directly triggers @Published update
        }
    }
    
    func updateItem(id: UUID, newName: String, newPrice: Decimal?) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].name = newName
            items[index].price = newPrice
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        // We need to map the offsets from the *sorted* view back to the original `items` array
        // This is safer if sorting logic becomes complex
        let idsToDelete = offsets.map { sortedItems[$0].id }
        items.removeAll { idsToDelete.contains($0.id) }
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
