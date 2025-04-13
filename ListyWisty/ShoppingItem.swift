//
//  ShoppingItem.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//
import Foundation

struct ShoppingItem: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var isChecked: Bool
    var checkedTimestamp: Date? // Track when item was checked for sorting
    var price: Decimal?
    var quantity: Int
    
    // Initialiser remais simple
    init(id: UUID = UUID(), name: String, isChecked: Bool = false, checkedTimestamp: Date? = nil, price: Decimal? = nil, quantity: Int = 1) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.checkedTimestamp = checkedTimestamp
        self.price = price
        // Ensure quantity is never less than 1 on init
        self.quantity = max(1, quantity) // Added assignment and validation
    }
    
    // --- Codable Conformance ---

    // 1. Define Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, name, isChecked, checkedTimestamp, price, quantity
    }

    // 2. Implement Decoder Initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode properties that are expected to be there
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        // Decode optional properties using decodeIfPresent
        price = try container.decodeIfPresent(Decimal.self, forKey: .price)
        checkedTimestamp = try container.decodeIfPresent(Date.self, forKey: .checkedTimestamp)

        // Decode properties with defaults if missing
        isChecked = try container.decodeIfPresent(Bool.self, forKey: .isChecked) ?? false // Default for Bool
        
        // *** The Key Fix ***
        // Try decoding quantity. If the key is missing, use the default value 1.
        // Also ensure the decoded value is at least 1.
        let decodedQuantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        quantity = max(1, decodedQuantity) // Use default 1 AND validate >= 1
    }

    // 3. Implement Encoder (Good practice)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isChecked, forKey: .isChecked)
        // Use encodeIfPresent for optionals to avoid writing "null" keys if value is nil
        try container.encodeIfPresent(checkedTimestamp, forKey: .checkedTimestamp)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
    }
}
