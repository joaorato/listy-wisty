//
//  ListViewModel.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//
import SwiftUI

class ShoppingListViewModel: ObservableObject {
    @Published var lists: [ShoppingList] = []
    
    func addList(name: String) -> ShoppingList {
        let newList = ShoppingList(name: name)
        lists.append(newList)
        return newList
    }
    
}
