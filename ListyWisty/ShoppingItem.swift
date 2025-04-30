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
    var quantity: Decimal
    var unit: String?
    
    // Initialiser remais simple
    init(id: UUID = UUID(), name: String, isChecked: Bool = false, checkedTimestamp: Date? = nil, price: Decimal? = nil, quantity: Decimal = 1, unit: String? = nil) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.checkedTimestamp = checkedTimestamp
        self.price = price
        // Ensure quantity is never less than 0.001 on init
        self.quantity = max(0.001, quantity) // Added assignment and validation
        self.unit = unit?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
    }
    
    // --- Codable Conformance ---

    // 1. Define Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, name, isChecked, checkedTimestamp, price, quantity, unit
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
        
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        
        // --- Handle Quantity Decoding (Decimal or Int fallback) ---
        do {
            // Try decoding as Decimal first (new format)
            let decodedDecimal = try container.decodeIfPresent(Decimal.self, forKey: .quantity) ?? 1.0
            quantity = max(Decimal(0.001), decodedDecimal) // Validate
        } catch DecodingError.typeMismatch {
            // If type mismatch, try decoding as Int (old format)
            print("ShoppingItem Decoding: Quantity was not Decimal, trying Int fallback for \(name)...")
            let decodedInt = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
            quantity = max(Decimal(0.001), Decimal(decodedInt)) // Convert Int to Decimal and validate
        } catch {
            // Other decoding errors
            print("ShoppingItem Decoding: Error decoding quantity for \(name). Defaulting to 1. Error: \(error)")
            quantity = 1.0 // Default if any other error occurs
        }
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
        try container.encode(max(Decimal(0.001), quantity), forKey: .quantity)
        try container.encodeIfPresent(unit, forKey: .unit)
    }
}
