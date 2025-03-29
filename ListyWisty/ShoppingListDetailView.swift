//
//  ListDetailView.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI

struct ShoppingListDetailView: View {
    @ObservedObject var list: ShoppingList
    @State private var newItem = ""
    
    var body: some View {
        VStack {
            List {
                ForEach(list.items, id: \.self) { item in
                    Text(item)
                }
            }
            
            HStack {
                TextField("New item", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    guard !newItem.isEmpty else { return }
                    list.items.append(newItem)
                    newItem = "" // Clear input
                }) {
                    Image(systemName: "plus")
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle(list.name)
    }
}
