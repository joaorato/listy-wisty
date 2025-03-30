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
    var isChecked: Bool = false
    var checkedTimestamp: Date? = nil // Track when item was checked for sorting
    
    // Initialiser remais simple
    init(id: UUID = UUID(), name: String, isChecked: Bool = false, checkedTimestamp: Date? = nil) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.checkedTimestamp = checkedTimestamp
    }
}
