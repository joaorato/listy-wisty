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
    
    @State private var editingItemID: UUID? = nil
    @State private var itemEditText: String = ""
    @State private var itemEditPrice: String = ""
    
    @State private var showingEditTitleAlert = false
    @State private var editableListName: String = ""
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.currencyCode = "EUR"
        return formatter
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(list.sortedItems) { item in
                    let _ = print("Rendering row for \(item.name). Is it editing target? \(item.id == editingItemID)")
                    
                    // --- EDITING STATE ---
                    if item.id == editingItemID {
                        VStack(alignment: .leading) {
                            
                            TextField("Item Text", text: $itemEditText)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit(commitItemEdit)
                            
                            HStack {
                                TextField("Price", text: $itemEditPrice)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 100)
                                Spacer()
                                Button("Done", action: commitItemEdit)
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    // --- DISPLAY STATE ---
                    else {
                        HStack {
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isChecked ? .green : .blue)
                                .font(.title2)
                                .highPriorityGesture(
                                    TapGesture()
                                        .onEnded { _ in
                                            print("High priority TOGGLE gesture hit")
                                            list.toggleItem(id: item.id)
                                            viewModel.listDidChange()
                                        }
                                )
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .strikethrough(item.isChecked, color: .gray) // Strikethrough if checked
                                    .foregroundColor(item.isChecked ? .gray : .primary) // Grey out if checked
                                
                                // Display formatted price if available
                                if let price = item.price {
                                    Text(formatPrice(price))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            // Text are tappable to START editing
                            .highPriorityGesture(
                                TapGesture()
                                    .onEnded { _ in // Use .onEnded for TapGesture within highPriority
                                        print("High priority edit gesture hit") // Log for this gesture
                                        // Only start editing if not already editing this specific item
                                        if editingItemID != item.id {
                                            startEditingItem(item)
                                        }
                                    }
                            )
                            
                            Spacer() // Push text and image to the left
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) { // Swipe from left-to-right
                            Button {
                                print("Swipe TOGGLE action triggered (full or tap)")
                                list.toggleItem(id: item.id)
                                viewModel.listDidChange()
                            } label: {
                                Label("Toggle", systemImage: item.isChecked ? "arrow.uturn.backward.circle" : "checkmark.circle.fill")
                            }
                            .tint(item.isChecked ? .orange : .green) // Use colors to indicate action
                        }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                 Button {
                     editableListName = list.name // Pre-fill state
                     showingEditTitleAlert = true
                 } label: {
                     Image(systemName: "pencil.circle") // Or "info.circle"
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
        .alert("Edit List Name", isPresented: $showingEditTitleAlert) {
            TextField("List Name", text: $editableListName)
            Button("Save") {
                let trimmedName = editableListName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty && trimmedName != list.name {
                    viewModel.objectWillChange.send() // This tells ContentView (observing viewModel) to prepare for an update
                    list.name = trimmedName // Update the list directly
                    viewModel.listDidChange() // Trigger save
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the new name for this list.")
        }
        .id(list.id)
        .onTapGesture { // Dismiss keyboard/editing if tapped outside list
            if editingItemID != nil {
                commitItemEdit() // maybe dismiss without saving instead of this
            }
        }
    }
    
    // --- Helper Functions ---
    private func formatPrice(_ price: Decimal?) -> String {
        guard let price = price else { return "" }
        // Convert Decimal to NSDecimalNumber for NumberFormatter
        return currencyFormatter.string(from: price as NSDecimalNumber) ?? ""
    }
    
    private func startEditingItem(_ item: ShoppingItem) {
        print("--- Attempting to start editing item: \(item.name) (ID: \(item.id)) ---")
        editingItemID = item.id
        itemEditText = item.name
        itemEditPrice = item.price?.description ?? ""
        print("   Set editingItemID to: \(String(describing: editingItemID))")
    }
    
    private func commitItemEdit() {
        guard let editingID = editingItemID else { return }
        
        // Find the *actual* index in the original list.items array
        if let index = list.items.firstIndex(where: { $0.id == editingID }){
            // Validate and update
            let newName = itemEditText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newName.isEmpty {
                list.items[index].name = newName
            }
            
            // Convert price string back to Decimal?
            if itemEditPrice.isEmpty {
                list.items[index].price = nil
            } else {
                // Use a formatter that handles locale-specific separators (e.g., "," vs ".")
                // For simplicity here, assuming Decimal(string:) works for basic cases
                list.items[index].price = Decimal(string: itemEditPrice)
            }
            
            // Important: Notify ViewModel AFTER update
            viewModel.listDidChange()
        }
        
        // Reset editing state
        editingItemID = nil
        itemEditText = ""
        itemEditPrice = ""
        hideKeyboard()
    }
    
    // Deleting item
    private func deleteItem(at offsets: IndexSet) {
        list.deleteItems(at: offsets)
        viewModel.listDidChange() // Trigger save
    }
    
    #if canImport(UIKit)
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
}
