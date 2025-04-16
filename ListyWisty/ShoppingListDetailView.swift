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
    @State private var itemEditUnit: String = ""
    
    @State private var showingEditTitleAlert = false
    @State private var editableListName: String = ""
    
    @State private var shareableItem: ShareableURL? = nil
    
    @State private var isParsingItems: Bool = false
    @State private var parseError: String? = nil
    
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
                                        .fixedSize()
                                    
                                    TextField("Unit", text: $itemEditUnit)
                                        .textFieldStyle(.roundedBorder)
                                        .autocapitalization(.none)
                                        .frame(maxWidth: 80)
                                }
                                
                                Spacer() // Push price field right
                                
                                if supportsPrice {
                                    TextField("Price", text: $itemEditPrice)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.decimalPad)
                                        .frame(minWidth: 80, maxWidth: 100) // Adjusted width
                                }
                            }
                            
                            HStack {
                                Spacer() // Push buttons to the right

                                Button("Cancel", role: .cancel) { // Explicit Cancel
                                    resetEditingState()
                                }
                                .buttonStyle(.bordered) // Less prominent style

                                Button("Done") { // Explicit Done/Save
                                    commitItemEdit()
                                }
                                .buttonStyle(.borderedProminent) // Primary action style
                            }
                        }
                        .padding(.vertical, 5)
                        // Subtle background to differentiate the editing row
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, -10)
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
                                            withAnimation {
                                                list.toggleItem(id: item.id)
                                                viewModel.listDidChange()
                                            }
                                        }
                                )
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .strikethrough(item.isChecked, color: .gray) // Strikethrough if checked
                                    .foregroundColor(item.isChecked ? .gray : .primary) // Grey out if checked
                                
                                // --- Conditional Quantity/Price Display ---
                                HStack(spacing: 6) { // Group quantity/price display
                                    if let unit = item.unit, !unit.isEmpty {
                                        // Display with unit
                                        Text("Qty: \(item.quantity) \(unit)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 5)
                                            .background(Color.gray.opacity(0.15))
                                            .clipShape(Capsule())
                                    } else if item.quantity > 1 && list.listType.supportsQuantity { // Only show Qty if > 1 AND no unit
                                        // Display only quantity (if > 1 and type supports it)
                                        Text("Qty: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 5)
                                        .background(Color.gray.opacity(0.15))
                                        .clipShape(Capsule())
                                    } // Else: If quantity is 1 and no unit, show nothing extra

                                    if supportsPrice, let price = item.price {
                                        Text(Formatters.formatPriceForDisplay(price))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            // Add spacing if both quantity/unit AND price are shown
                                            .padding(.leading, (item.unit != nil || item.quantity > 1) ? 4 : 0)
                                    }
                                }
                            }
                            .padding(.leading, 8)
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
                                withAnimation {
                                    list.toggleItem(id: item.id)
                                    viewModel.listDidChange()
                                }
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
            // Optional overlay ProgressView on List during parse
            .overlay {
                if isParsingItems {
                    ProgressView("Parsing...")
                        .padding()
                        .background(.ultraThickMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            
            HStack {
                
                TextField("Add new item...", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        // Default action on Enter: Standard Add
                        handleStandardAdd()
                    }
                    .disabled(isParsingItems)
                    .padding(.leading)
                    
                
                Button {
                    handleStandardAdd()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(isParsingItems || newItemName.isBlank)
                
                // Smart Add Button
                Button {
                     Task { await handleSmartAdd() }
                } label: {
                     Image(systemName: "brain") // Or "wand.and.stars"
                         .font(.title2)
                         .foregroundColor(.purple) // Differentiate color
                }
                .padding(.trailing)
                .disabled(isParsingItems || newItemName.isBlank)
            }
            .padding(.vertical, 5)
            .background(Color(.systemGray6)) // ✅ Light gray background
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle(list.name)
        .toolbar {
            // Group all trailing items together
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                // 1. Always Visible: Total Price (Conditional)
                if list.listType.supportsPrice {
                    Text(Formatters.formatPriceForDisplay(list.totalPrice))
                         .font(.subheadline)
                         .foregroundColor(.secondary)
                         // Add padding to separate from buttons maybe
                         // .padding(.trailing, 5)
                }

                // 2. Always Visible: Share Button
                Button {
                    if let url = ShareExportManager.exportListToFile(list) {
                        self.shareableItem = ShareableURL(url: url)
                        print("Share button tapped, setting shareableItem to trigger sheet for URL: \(url.path)")
                    } else {
                        print("Error: Could not generate file URL for sharing.")
                        // TODO: Show error alert
                    }
                } label: {
                    Label("Share List", systemImage: "square.and.arrow.up") // Use Label for accessibility
                }
                
                EditButton()
                
                // 3. "More" Menu for other actions
                Menu {

                    // Rename List action
                    Button {
                        editableListName = list.name // Pre-fill state
                        showingEditTitleAlert = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    // Delete List action (Destructive)
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                } label: {
                    // The label for the menu itself (the button shown in the toolbar)
                    Label("More Actions", systemImage: "ellipsis.circle")
                }
            } // End ToolbarItemGroup
        } // End toolbar modifier
        .sheet(item: $shareableItem) { itemWrapper in // Closure receives the ShareableURL instance
             // Access the actual URL via the wrapper's property
             ActivityViewRepresentable(activityItems: [itemWrapper.url])
                 .onDisappear {
                      // Optional cleanup
                      // print("Share sheet dismissed. Temp file: \(itemWrapper.url.path)")
                      // try? FileManager.default.removeItem(at: itemWrapper.url)
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
        .alert("Error Parsing Items", isPresented: .constant(parseError != nil), actions: {
            Button("OK") { parseError = nil }
        }, message: {
            Text(parseError ?? "An unknown error occurred.")
        })
        .id(list.id)
    }
    
    // --- Helper Functions ---
    
    private func addItemAction() {
        list.addItem(name: newItemName)
        viewModel.listDidChange() // Trigger save
        newItemName = "" // Clear input
    }
    
    private func handleStandardAdd() {
        let textToAdd = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToAdd.isEmpty else { return }

        viewModel.addSingleItem(name: textToAdd, to: list) // Call new ViewModel method

        newItemName = "" // Clear field
        hideKeyboard()
    }
    
    private func handleSmartAdd() async {
        let textToAdd = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToAdd.isEmpty else { return }
        
        // Clear field immediately for responsiveness\
        newItemName = ""
        // Hide keyboard
        hideKeyboard()
        
        isParsingItems = true
        parseError = nil
        
        do {
            try await viewModel.parseAndAddItems(text: textToAdd, to: list)
            // Success! Items were added by the ViewModel, UI should update via @Published
            print("✅ View: handleAddItem completed successfully.")
        } catch let error as AIServiceError {
            // Handle specific AI errors
            print("❌ View: AIServiceError - \(error)")
            parseError = "Failed to parse items. \(errorMessage(for: error))" // Set error message for alert
       } catch {
            // Handle other errors
            print("❌ View: Unknown error - \(error)")
            parseError = "An unexpected error occurred while adding items."
       }
        
        isParsingItems = false
    }
    
    // Helper to create user-friendly error messages
    private func errorMessage(for error: AIServiceError) -> String {
        switch error {
        case .networkError:
            return "Please check your internet connection."
        case .decodingError:
            return "Received an unexpected response from the server."
        case .serverError(_, let message):
            return message ?? "The AI server returned an error. Please try again later."
        case .invalidResponseFormat:
            return "Received an invalid response format."
        case .apiKeyMissing:
             return "AI service configuration error." // Generic message for user
        case .backendProxyError(let message):
             return "AI service failed: \(message)" // Show proxy message if available
        case .llmError(let details):
            print("LLM Error Details: \(details)")
            return "The AI failed to understand the items. Try phrasing differently or adding items manually."
        }
    }
    
    private func startEditingItem(_ item: ShoppingItem) {
        guard editingItemID == nil && !(editMode?.wrappedValue.isEditing ?? false) else { return }
        print("--- Attempting to start editing item: \(item.name) (ID: \(item.id)) ---")
        editingItemID = item.id
        itemEditText = item.name
        itemEditQuantity = item.quantity
        itemEditUnit = item.unit ?? ""
        
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
        print("   Set itemEditUnit to: '\(itemEditUnit)'")
    }
    
    private func commitItemEdit() {
        guard let editingID = editingItemID else { return }
        print("--- Committing Edit for Item ID: \(editingID) ---")
        print("   Name field: '\(itemEditText)'")
        print("   Price field: '\(itemEditPrice)' (Supported: \(supportsPrice))")
        print("   Quantity field: \(itemEditQuantity) (Supported: \(supportsQuantity))")
        print("   Unit field: '\(itemEditUnit)' (Supported: \(supportsQuantity))")

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
        let unitString = itemEditUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        var newUnit: String? = originalItem.unit // Start with original unit
        
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
            
            // Validate and Check Unit
            let validatedUnit: String? = unitString.isEmpty ? nil : unitString // Treat empty string as nil
            if originalItem.unit != validatedUnit {
                newUnit = validatedUnit // Assign the validated value (could be nil)
                print("   Updating Unit from '\(originalItem.unit ?? "nil")' to '\(newUnit ?? "nil")'")
                needsSave = true
            } else {
                print("   Unit unchanged ('\(originalItem.unit ?? "nil")').")
            }
            
        } else {
            print("   Quantity/Unit not supported for this list type.")
            // Reset Quantity to 1 if not supported
            if originalItem.quantity != 1 { needsSave = true }
            newQuantity = 1
            // Reset Unit to nil if not supported
            if originalItem.unit != nil { needsSave = true }
            newUnit = nil
        }


        // --- Perform Update and Trigger Save ---
        if needsSave {
            print("   Changes detected, calling list.updateItem.")
            // Call the updated method in ShoppingList
            // Pass the *potentially* modified name, price, and quantity
            list.updateItem(id: editingID,
                            newName: newName.isEmpty ? originalItem.name : newName, // Ensure non-empty name passed
                            newPrice: newPrice,
                            newQuantity: newQuantity,
                            newUnit: newUnit)
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
        itemEditUnit = ""
        hideKeyboard()
        print("--- Editing State Reset ---")
    }

    
    // Moving item
    private func moveItem(from source: IndexSet, to destination: Int) {
        print("Moving item from \(source) to \(destination)")
        withAnimation {
            list.moveItem(from: source, to: destination)
            viewModel.listDidChange() // Trigger save
        }
    }
    
    // Deleting item
    private func deleteItem(at offsets: IndexSet) {
        withAnimation {
            list.deleteItems(at: offsets)
            viewModel.listDidChange() // Trigger save
        }
    }
    
    #if canImport(UIKit)
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
}

extension String {
     var isBlank: Bool {
         self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
     }
     // nilIfEmpty() if you still need it elsewhere
}
