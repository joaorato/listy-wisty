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
    @State private var itemEditQuantity: Int = 1
    
    @State private var showingEditTitleAlert = false
    @State private var editableListName: String = ""
    
    @Environment(\.editMode) var editMode
    
    // Helper to check if the current list supports quantity/price
    private var supportsQuantity: Bool { list.listType.supportsQuantity }
    private var supportsPrice: Bool { list.listType.supportsPrice }
    
    var body: some View {
        VStack {
            List {
                ForEach(list.items) { item in
                    // --- EDITING STATE ---
                    if item.id == editingItemID {
                        VStack(alignment: .leading, spacing: 8) {
                            
                            TextField("Item Name", text: $itemEditText)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit(commitItemEdit)
                            
                            HStack {
                                if supportsQuantity {
                                    Stepper("Qty: \(itemEditQuantity)", value: $itemEditQuantity, in: 1...999) // Use Stepper for Quantity
                                    Spacer() // Push Done button right
                                }
                                
                                if supportsPrice {
                                    TextField("Price", text: $itemEditPrice)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.decimalPad)
                                        .frame(minWidth: 80, maxWidth: 100) // Adjusted width
                                }
                            }

                            Button("Done", action: commitItemEdit)
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity, alignment: .trailing)
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
                                
                                // --- Conditional Quantity/Price Display ---
                                HStack(spacing: 6) { // Group quantity/price display
                                    if supportsQuantity && item.quantity > 1 { // Only show if > 1
                                        Text("Qty: \(item.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 5)
                                            .background(Color.gray.opacity(0.15))
                                            .clipShape(Capsule())
                                    }

                                    if supportsPrice, let price = item.price {
                                        Text(Formatters.formatPriceForDisplay(price))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
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
                                        if !(editMode?.wrappedValue.isEditing ?? false) && editingItemID != item.id {
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
                .onMove(perform: moveItem) // Enable moving of items
                .onDelete(perform: deleteItem) // Enable swipe-to-delete
            }
            .listStyle(.plain) // ✅ Minimalist list style
            .environment(\.editMode, editMode)
            
            HStack {
                TextField("New item...", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                    .onSubmit {
                        addItemAction()
                    }
                
                Button(action: addItemAction) {
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
            
            // --- Conditional Total Price ---
            if supportsPrice { // Only show total for shopping lists
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Total: \(Formatters.formatPriceForDisplay(list.totalPrice))") // Added "Total: " prefix
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) { // Common placement
                EditButton() // <<< ADD HERE
            }
            
            // Toolbar for editing list
            ToolbarItem(placement: .navigationBarTrailing) {
                 Button {
                     editableListName = list.name // Pre-fill state
                     showingEditTitleAlert = true
                 } label: {
                     Image(systemName: "pencil.circle") // Or "info.circle"
                 }
             }
            
            // Toolbar button for deleting list
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
                resetEditingState() // dismiss without saving
            } else {
                hideKeyboard() // Just hide keyboard if not inline editing
           }
        }
    }
    
    // --- Helper Functions ---
    
    private func addItemAction() {
        list.addItem(name: newItemName)
        viewModel.listDidChange() // Trigger save
        newItemName = "" // Clear input
    }
    
    private func startEditingItem(_ item: ShoppingItem) {
        guard editingItemID == nil && !(editMode?.wrappedValue.isEditing ?? false) else { return }
        print("--- Attempting to start editing item: \(item.name) (ID: \(item.id)) ---")
        editingItemID = item.id
        itemEditText = item.name
        itemEditQuantity = item.quantity
        
        // Populate price only if supported and present
        if supportsPrice {
            if let price = item.price {
                itemEditPrice = Formatters.decimalInputFormatter.string(for: price) ?? ""
            } else {
                itemEditPrice = ""
            }
        } else {
            itemEditPrice = "" // Ensure it's empty if not supported
        }
        print("   Set editingItemID to: \(String(describing: editingItemID))")
    }
    
    private func commitItemEdit() {
        guard let editingID = editingItemID else { return }
        print("--- Committing Edit for Item ID: \(editingID) ---")
        print("   Name field: '\(itemEditText)'")
        print("   Price field: '\(itemEditPrice)' (Supported: \(supportsPrice))")
        print("   Quantity field: \(itemEditQuantity) (Supported: \(supportsQuantity))")


        // Find the *actual* index in the original list.items array
        guard let index = list.items.firstIndex(where: { $0.id == editingID }) else {
             print("   ERROR: Could not find item with ID \(editingID) in list.items")
             resetEditingState() // Reset state even if item not found (shouldn't happen)
             return
        }

        // --- Prepare Values ---
        let originalItem = list.items[index]
        let newName = itemEditText.trimmingCharacters(in: .whitespacesAndNewlines)
        var newPrice: Decimal? = originalItem.price // Start with original
        var newQuantity: Int? = originalItem.quantity // Start with original

        var needsSave = false

        // --- Check for Name Change ---
        if !newName.isEmpty && newName != originalItem.name {
            // newName is already assigned above
            print("   Updating Name from '\(originalItem.name)' to '\(newName)'")
            needsSave = true
        } else if newName.isEmpty {
            print("   Name field was empty, keeping original '\(originalItem.name)'.")
            // Keep original name if input was empty
            // Note: list.updateItem handles the empty check again, but doing it here avoids unnecessary calls/prints
            // Revert newName to original if it was emptied
            if originalItem.name != newName {
                 // This case shouldn't happen due to the guard in list.updateItem,
                 // but being defensive. Resetting newName prevents accidental update with empty.
                 // We rely on list.updateItem's logic primarily.
                 print("   WARNING: Name field was empty; updateItem should prevent this, but resetting.")
            }
        } else {
             print("   Name unchanged ('\(originalItem.name)').")
        }
        
        // --- Check for Price Change (Only if supported) ---
        if supportsPrice {
            let priceString = itemEditPrice.trimmingCharacters(in: .whitespacesAndNewlines)
            var parsedDecimal: Decimal? = nil

            if priceString.isEmpty {
                print("   Price string is empty.")
                parsedDecimal = nil // Explicitly set to nil if field is empty
            } else {
                print("   Attempting to parse price string '\(priceString)'...")
                if let number = Formatters.decimalInputFormatter.number(from: priceString) {
                    parsedDecimal = number.decimalValue
                    print("   Parse SUCCESS: \(parsedDecimal!)")
                } else {
                    print("   Parse FAILED for string '\(priceString)'. Keeping original price.")
                    // Keep original price if parsing fails
                    parsedDecimal = originalItem.price
                    // Optionally show user error here
                }
            }

            // Check if the parsed price differs from the original
            if originalItem.price != parsedDecimal {
                newPrice = parsedDecimal // Assign the parsed value (could be nil)
                print("   Updating Price from '\(String(describing: originalItem.price))' to '\(String(describing: newPrice))'")
                needsSave = true
            } else {
                 print("   Price unchanged ('\(String(describing: originalItem.price))').")
            }
        } else {
             print("   Price not supported for this list type.")
             newPrice = nil // Ensure price is nil if not supported
             if originalItem.price != nil { // If original had a price, this is a change
                 needsSave = true
                 print("   Forcing price to nil as type changed or item moved.")
             }
        }
        
        // --- Check for Quantity Change (Only if supported) ---
        if supportsQuantity {
             // itemEditQuantity is bound to the Stepper, ensure it's at least 1
             let validQuantity = max(1, itemEditQuantity)
             if originalItem.quantity != validQuantity {
                 newQuantity = validQuantity
                 print("   Updating Quantity from \(originalItem.quantity) to \(newQuantity!)")
                 needsSave = true
             } else {
                 print("   Quantity unchanged (\(originalItem.quantity)).")
             }
        } else {
             print("   Quantity not supported for this list type.")
             newQuantity = 1 // Reset to default if not supported
             if originalItem.quantity != 1 { // If original wasn't 1, this is a change
                 needsSave = true
                 print("   Forcing quantity to 1 as type changed or item moved.")
             }
        }


        // --- Perform Update and Trigger Save ---
        if needsSave {
            print("   Changes detected, calling list.updateItem.")
            // Call the updated method in ShoppingList
            // Pass the *potentially* modified name, price, and quantity
            list.updateItem(id: editingID,
                            newName: newName.isEmpty ? originalItem.name : newName, // Ensure non-empty name passed
                            newPrice: newPrice,
                            newQuantity: newQuantity)
            viewModel.listDidChange() // Trigger save via ViewModel
        } else {
             print("   No changes detected, save not triggered.")
        }

        resetEditingState()
    }

    // Helper to reset editing state variables
    private func resetEditingState() {
        editingItemID = nil
        itemEditText = ""
        itemEditPrice = ""
        itemEditQuantity = 1 // Reset quantity to default
        hideKeyboard()
         print("--- Editing State Reset ---")
    }

    
    // Moving item
    private func moveItem(from source: IndexSet, to destination: Int) {
        print("Moving item from \(source) to \(destination)")
        list.moveItem(from: source, to: destination)
        viewModel.listDidChange() // Trigger save
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
