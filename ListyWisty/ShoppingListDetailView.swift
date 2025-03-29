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
                    HStack {
                        Image(systemName: "circle") // ⭕ Placeholder for checkmark later
                        Text(item)
                            .font(.body)
                            .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain) // ✅ Minimalist list style
            
            HStack {
                TextField("New item...", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    guard !newItem.isEmpty else { return }
                    list.items.append(newItem)
                    newItem = "" // Clear input
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                }
                .padding()
            }
            .background(Color(.systemGray6)) // ✅ Light gray background
            .cornerRadius(10)
            .padding()
        }
        .navigationTitle(list.name)
    }
}
