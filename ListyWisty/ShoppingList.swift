//
//  List.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI

class ShoppingList: ObservableObject, Identifiable, Hashable {
    let id = UUID()
    @Published var name: String
    @Published var items: [String]
    
    init(name: String, items: [String] = []) {
        self.name = name
        self.items = items
    }
    
    // MARK: - Conformance to Hashable
        static func == (lhs: ShoppingList, rhs: ShoppingList) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
}
