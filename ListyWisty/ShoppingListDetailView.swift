//
//  ShoppingListDetailView.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI

struct ShoppingListDetailView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    @ObservedObject var list: ShoppingList
    @State private var newItemName = ""
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack {
            List {
                ForEach(list.sortedItems) { item in
                    HStack {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(item.isChecked ? .green : .blue)
                            .font(.title2)
                            .onTapGesture {
                                // Toggle item using the list's method
                                list.toggleItem(id: item.id)
                            }
                        
                        Text(item.name)
                            .font(.body)
                            .strikethrough(item.isChecked, color: .gray) // Strikethrough if checked
                            .foregroundColor(item.isChecked ? .gray : .primary) // Grey out if checked
                            .padding(.vertical, 4)
                        
                        Spacer() // Push text and image to the left
                    }
                    // Apply tap gesture to the whole HStack for easier tapping
                    .contentShape(Rectangle()) // Make entire row tappable area
                    .onTapGesture {
                        list.toggleItem(id: item.id)
                        viewModel.listDidChange() // Trigger save
                    }
                }
                .onDelete(perform: deleteItem) // Enable swipe-to-delete
            }
            .listStyle(.plain) // ✅ Minimalist list style
            
            HStack {
                TextField("New item...", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: {
                    list.addItem(name: newItemName)
                    viewModel.listDidChange() // Trigger save
                    newItemName = "" // Clear input
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                }
                .padding(.trailing) // Add padding only on the right
                .padding(.vertical, 5) // Reduce vertical padding a bit
            }
            .background(Color(.systemGray6)) // ✅ Light gray background
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle(list.name)
        .toolbar{
            // Toolbar button for list deletion
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Show confirmation alert
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete List?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteList(id: list.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Are you sure you want to delete the list \"\(list.name)\"? This action cannot be undone.") }
        .id(list.id)
    }
    
    // Deleting item
    private func deleteItem(at offsets: IndexSet) {
        list.deleteItems(at: offsets)
        viewModel.listDidChange() // Trigger save
    }
}
