//
//  ShoppingItem.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//
import Foundation

struct ShoppingItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var isChecked: Bool = false
    var checkedTimestamp: Date? = nil // Track when item was checked for sorting
    
    // Initialiser remais simple
    init(_ name: String, isChecked: Bool = false, checkedTimestamp: Date? = nil) {
        self.name = name
        self.isChecked = isChecked
        self.checkedTimestamp = checkedTimestamp
    }
}
