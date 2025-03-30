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
    
    // Formatter for DISPLAYING currency
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.currencyCode = "EUR"
        formatter.generatesDecimalNumbers = true
        return formatter
    }
    
    // Formatter for EDITING/PARSING decimal numbers (no currency symbol)
    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.generatesDecimalNumbers = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(list.sortedItems) { item in                    
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
                                    Text(formatPriceForDisplay(price))
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
    private func formatPriceForDisplay(_ price: Decimal?) -> String {
        guard let price = price else { return "" }
        // Convert Decimal to NSDecimalNumber for NumberFormatter
        return currencyFormatter.string(from: price as NSDecimalNumber) ?? ""
    }
    
    private func startEditingItem(_ item: ShoppingItem) {
        print("--- Attempting to start editing item: \(item.name) (ID: \(item.id)) ---")
        editingItemID = item.id
        itemEditText = item.name
        // Format the price using the DECIMAL formatter for the text field
        if let price = item.price {
            itemEditPrice = decimalFormatter.string(for: price) ?? ""
            print("   Populating itemEditPrice with formatted string: '\(itemEditPrice)' using locale \(decimalFormatter.locale.identifier)")
        } else {
            itemEditPrice = ""
            print("   Populating itemEditPrice with empty string (no price).")
        }
        print("   Set editingItemID to: \(String(describing: editingItemID))")
    }
    
    private func commitItemEdit() {
        guard let editingID = editingItemID else { return }
        print("--- Committing Edit for Item ID: \(editingID) ---")
        print("   Name field: '\(itemEditText)'")
        print("   Price field: '\(itemEditPrice)'")


        // Find the *actual* index in the original list.items array
        guard let index = list.items.firstIndex(where: { $0.id == editingID }) else {
             print("   ERROR: Could not find item with ID \(editingID) in list.items")
             resetEditingState() // Reset state even if item not found (shouldn't happen)
             return
        }

        var needsSave = false
        let originalName = list.items[index].name
        let originalPrice = list.items[index].price

        // --- Update Name ---
        let newName = itemEditText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty && newName != originalName {
            list.items[index].name = newName
            print("   Updated Name from '\(originalName)' to '\(newName)'")
            needsSave = true
        } else if newName.isEmpty {
             print("   Name field was empty, not updating name.")
        } else {
            print("   Name unchanged ('\(originalName)').")
        }

        // --- Update Price ---
        let priceString = itemEditPrice.trimmingCharacters(in: .whitespacesAndNewlines)
        var parsedDecimal: Decimal? = nil

        if priceString.isEmpty {
            print("   Price string is empty.")
            // If the original price was not nil, this is a change (setting to nil)
            if originalPrice != nil {
                parsedDecimal = nil
                print("   Setting price to nil.")
            } else {
                // Price was nil and is still nil (empty string) - no change
                 print("   Price remains nil.")
            }
        } else {
            // Attempt to parse using the DECIMAL formatter
            print("   Attempting to parse price string '\(priceString)' using locale \(decimalFormatter.locale.identifier)...")
            if let number = decimalFormatter.number(from: priceString) {
                parsedDecimal = number.decimalValue
                print("   Parse SUCCESS: \(parsedDecimal!)")
            } else {
                print("   Parse FAILED for string '\(priceString)'. Keeping original price.")
                // Keep original price if parsing fails - don't set to nil or invalid value
                parsedDecimal = originalPrice
                // Optionally, you could show an error to the user here
            }
        }

        // Only update and trigger save if the *parsed* price is different from original
        if originalPrice != parsedDecimal {
            list.items[index].price = parsedDecimal
            print("   Updated Price from '\(String(describing: originalPrice))' to '\(String(describing: parsedDecimal))'")
            needsSave = true
        } else {
             print("   Price unchanged ('\(String(describing: originalPrice))').")
        }


        // --- Trigger Save and Reset State ---
        if needsSave {
            print("   Changes detected, triggering save.")
            viewModel.listDidChange()
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
        hideKeyboard()
         print("--- Editing State Reset ---")
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
