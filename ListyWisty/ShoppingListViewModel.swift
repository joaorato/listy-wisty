//
//  ShoppingListViewModel.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//
import SwiftUI

class ShoppingListViewModel: ObservableObject {
    @Published var lists: [ShoppingList] = []
    
    // Example Data (useful for testing)
    init() {
        let exampleList = ShoppingList(name: "Groceries")
        exampleList.addItem(name: "Milk")
        exampleList.addItem(name: "Eggs")
        exampleList.addItem(name: "Bread")
        lists.append(exampleList)
    }
    
    @discardableResult
    func addList(name: String) -> ShoppingList {
        let newList = ShoppingList(name: name)
        lists.append(newList)
        return newList
    }
    
    func deleteList(id: UUID) {
        lists.removeAll { $0.id == id }
    }
}
