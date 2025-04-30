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
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteConfirmation = false
    
    @State private var editingItemID: UUID? = nil
    @State private var itemEditText: String = ""
    @State private var itemEditPrice: String = ""
    @State private var itemEditQuantityString: String = "1"
    @State private var itemEditUnit: String = ""
    
    @State private var showingEditTitleAlert = false
    @State private var editableListName: String = ""
    
    @State private var shareableItem: ShareableURL? = nil
        
    @State private var showingAddItemSheet = false
    
    @FocusState private var focusedFieldId: UUID?
    
    @Environment(\.editMode) var editMode
    
    @State private var itemIndicesToDelete: IndexSet? = nil // Store IndexSet
    @State private var showingItemDeleteAlert = false
    
    // Helper to check if the current list supports quantity/price
    private var supportsQuantity: Bool { list.listType.supportsQuantity }
    private var supportsPrice: Bool { list.listType.supportsPrice }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(list.items) { item in
                    // --- EDITING STATE ---
                    if item.id == editingItemID {
                        VStack(alignment: .leading, spacing: 8) {
                            
                            TextField("Item Name", text: $itemEditText, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit(commitItemEdit)
                                .focused($focusedFieldId, equals: item.id) // Bind focus
                            
                            HStack {
                                if supportsQuantity {
                                    Text("Qty:").font(.subheadline)
                                    
                                    Button { decrementQuantity() } label: {
                                        Image(systemName: "minus.circle")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(decimalQuantityValue <= 0.001) // Disable if at minimum
                                    
                                    TextField("Qty", text: $itemEditQuantityString)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 60) // Adjust width as needed
                                        .multilineTextAlignment(.center)
                                    
                                    // Plus Button
                                    Button { incrementQuantity() } label: {
                                        Image(systemName: "plus.circle")
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    TextField("Unit", text: $itemEditUnit)
                                        .textFieldStyle(.roundedBorder)
                                        .autocapitalization(.none)
                                        .frame(maxWidth: 80)
                                        .focused($focusedFieldId, equals: item.id)
                                }
                                
                                Spacer() // Push price field right
                                
                                if supportsPrice {
                                    HStack(spacing: 2) { // Group price field and unit label
                                        TextField("Price", text: $itemEditPrice)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.decimalPad)
                                            .frame(minWidth: 70, maxWidth: 90) // Adjusted width
                                            .focused($focusedFieldId, equals: item.id) // General focus ID

                                        // Dynamic Price Unit Label
                                        Text(priceUnitLabel)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .transition(.opacity.animation(.easeInOut(duration: 0.2))) // Animate change
                                            .id("priceUnitLabel_\(itemEditUnit)") // Help transition
                                    }
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
                        .id(item.id)
                        .onAppear {
                            populateEditingState(for: item)
                        }
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
                                                viewModel.listDidChange(listId: list.id)
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
                                        Text("Qty: \(formattedQuantity(item.quantity)) \(unit)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 5)
                                            .background(Color.gray.opacity(0.15))
                                            .clipShape(Capsule())
                                    } else if item.quantity != 1 && list.listType.supportsQuantity { // Only show Qty if > 1 AND no unit
                                        // Display only quantity (if > 1 and type supports it)
                                        Text("Qty: \(formattedQuantity(item.quantity))")
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
                                            .padding(.leading, (item.unit != nil || item.quantity != 1) ? 4 : 0)
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
                                    viewModel.listDidChange(listId: list.id)
                                }
                            } label: {
                                Label("Toggle", systemImage: item.isChecked ? "arrow.uturn.backward.circle" : "checkmark.circle.fill")
                            }
                            .tint(item.isChecked ? .orange : .green) // Use colors to indicate action
                        }
                    }
                }
                .onMove(perform: moveItem) // Enable moving of items
                .onDelete { indexSet in
                    prepareToDeleteItems(at: indexSet) // <--- Call helper
                }
            }
            .listStyle(.plain) // ✅ Minimalist list style
            .environment(\.editMode, editMode)
            .navigationTitle(list.name)
            .onChange(of: focusedFieldId) { oldValue, newValue in // <-- Monitor focus changes
                // Check if focus moved TO a field WITHIN the currently edited item
                if let currentFocusId = newValue, currentFocusId == editingItemID {
                    print("Focus changed to field in editing item \(currentFocusId), scrolling...")
                    // Use a slight delay to ensure layout calculations are done after keyboard appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Adjust delay if needed
                        withAnimation {
                            proxy.scrollTo(currentFocusId, anchor: .bottom) // Scroll to the VStack's ID, ensuring bottom is visible
                        }
                    }
                } else {
                    print("Focus changed (old: \(String(describing: oldValue)), new: \(String(describing: newValue))), but not to the currently editing item or focus lost.")
                }
            }
            .alert("Delete Item?", isPresented: $showingItemDeleteAlert, presenting: itemIndicesToDelete) { indices in
                Button("Delete", role: .destructive) {
                    deleteItem(at: indices)
                    self.itemIndicesToDelete = nil // Clear state
                }
                Button("Cancel", role: .cancel) {
                    self.itemIndicesToDelete = nil // Clear state
                }
            } message: { indices in
                // Create a message based on the items being deleted
                Text("Are you sure you want to delete \(getNamesForDeletion(at: indices))?")
            }
            
        }
        .overlay(alignment: .bottom) { // <--- Use overlay
            // --- Add Item Button (Conditional Visibility) ---
             if focusedFieldId == nil { // <--- Check if focus is NOT active
                 Button {
                     showingAddItemSheet = true
                 } label: {
                     Label("Add Item", systemImage: "plus.circle.fill")
                         .font(.title2)
                         .foregroundColor(.white)
                         .padding()
                         .background(Color.blue)
                         .clipShape(Capsule())
                         .shadow(radius: 5)
                 }
                 .padding(.bottom)
                 // Add a transition for smoother appearance/disappearance
                 .transition(.move(edge: .bottom).combined(with: .opacity))
             } // End if focusedFieldId == nil
        } // End overlay
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
                } else if list.listType == .task {
                    // Show Completion Percentage for Task lists
                    Text("\(Int(list.completionPercentage * 100))%") // Use the computed property
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    viewModel.listDidChange(listId: list.id) // Trigger save
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the new name for this list.")
        }
        .sheet(isPresented: $showingAddItemSheet) {
             // Present the new AddItemView
             AddItemView(viewModel: viewModel, list: list)
        }
        .id(list.id)
        .animation(.easeInOut(duration: 0.2), value: focusedFieldId)
    }
    
    // --- Helper Functions ---
    
    // Computed property to parse quantity string for validation/buttons
    private var decimalQuantityValue: Decimal {
        // Use the standard decimal formatter for locale awareness
        Formatters.decimalInputFormatter.number(from: itemEditQuantityString)?.decimalValue ?? 0
    }

    // Computed property for the dynamic price unit label
    private var priceUnitLabel: String {
        let unit = itemEditUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        if unit.isEmpty {
            return "€ / item" // Or just "€"
        } else {
            return "€ / \(unit)"
        }
    }

    // Function to populate state when starting edit
    private func populateEditingState(for item: ShoppingItem) {
        // Called from .onAppear of the editing VStack or inside startEditingItem
        itemEditText = item.name
        itemEditUnit = item.unit ?? ""
        // Format the decimal quantity for the TextField string
        itemEditQuantityString = Formatters.decimalInputFormatter.string(for: item.quantity) ?? "1"

        if supportsPrice {
            itemEditPrice = Formatters.decimalInputFormatter.string(for: item.price) ?? ""
        } else {
            itemEditPrice = ""
        }
        print("Populated editing state for \(item.name). Qty String: '\(itemEditQuantityString)'")
    }
    
    // Action for Quantity Increment Button
    private func incrementQuantity() {
        let currentValue = decimalQuantityValue
        // Increment logic (e.g., by 1 or 0.1 depending on context? Let's use 1 for now)
        let newValue = currentValue + 1
        itemEditQuantityString = Formatters.decimalInputFormatter.string(for: newValue) ?? itemEditQuantityString
    }

    // Action for Quantity Decrement Button
    private func decrementQuantity() {
        let currentValue = decimalQuantityValue
        // Decrement logic, ensuring minimum of 0.001
        let newValue = max(Decimal(0.001), currentValue - 1)
        itemEditQuantityString = Formatters.decimalInputFormatter.string(for: newValue) ?? itemEditQuantityString
    }
    
    // Format Decimal Quantity for Display State
    private func formattedQuantity(_ quantity: Decimal) -> String {
        // Use NumberFormatter that handles decimals appropriately
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0 // Avoid trailing ".0"
        formatter.maximumFractionDigits = 2 // Show up to 2 decimal places if needed
        return formatter.string(for: quantity) ?? "\(quantity)" // Fallback
    }
    
    private func prepareToDeleteItems(at offsets: IndexSet) {
        self.itemIndicesToDelete = offsets
        self.showingItemDeleteAlert = true
    }
    
    private func getNamesForDeletion(at offsets: IndexSet) -> String { // Accept non-optional IndexSet from alert
        // Use compactMap with index validation to safely get items
        let itemsToDelete = offsets.compactMap { index -> ShoppingItem? in
            // --- Check if index is valid *before* accessing ---
            if list.items.indices.contains(index) {
                return list.items[index]
            } else {
                // Log if an invalid index is encountered (helps debugging timing issues)
                print("⚠️ Warning: Index \(index) out of bounds in getNamesForDeletion. List count: \(list.items.count). Offsets: \(offsets)")
                return nil // Skip this index
            }
        }

        // Generate message based on safely retrieved items
        if itemsToDelete.isEmpty {
             // This might happen if the list changed drastically before message render
            return "selected items"
        } else if itemsToDelete.count == 1 {
            return "\"\(itemsToDelete[0].name)\""
        } else {
            return "\(itemsToDelete.count) items"
        }
    }
    
    private func startEditingItem(_ item: ShoppingItem) {
        // Reset focus state *before* potentially setting a new editing item
        // This prevents the onChange from firing with the *old* editingItemID
        focusedFieldId = nil
        hideKeyboard() // Dismiss keyboard if it was open from a previous edit
        
        guard editingItemID == nil && !(editMode?.wrappedValue.isEditing ?? false) else { return }
        print("--- Attempting to start editing item: \(item.name) (ID: \(item.id)) ---")
        editingItemID = item.id
//        itemEditText = item.name
//        itemEditQuantity = item.quantity
//        itemEditUnit = item.unit ?? ""
//        
//        // Populate price only if supported and present
//        if supportsPrice {
//            itemEditPrice = Formatters.decimalInputFormatter.string(for: item.price) ?? ""
//        } else {
//            itemEditPrice = ""
//        }
//        print("   Set editingItemID to: \(String(describing: editingItemID))")
//        print("   Set itemEditUnit to: '\(itemEditUnit)'")
    }
    
    private func commitItemEdit() {
        guard let editingID = editingItemID else { return }
        print("--- Committing Edit for Item ID: \(editingID) ---")
        print("   Name field: '\(itemEditText)'")
        print("   Price field: '\(itemEditPrice)' (Supported: \(supportsPrice))")
        print("   Quantity field: \(itemEditQuantityString) (Supported: \(supportsQuantity))")
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
        var newQuantityDecimal: Decimal? = originalItem.quantity // Start with original
        if supportsQuantity {
            if let parsedQty = Formatters.decimalInputFormatter.number(from: itemEditQuantityString)?.decimalValue {
                 newQuantityDecimal = max(Decimal(0.001), parsedQty) // Validate minimum
                print("   Parsed Quantity: \(String(describing: newQuantityDecimal))")
            } else {
                print("   Parse FAILED for quantity string '\(itemEditQuantityString)'. Keeping original quantity.")
                newQuantityDecimal = originalItem.quantity
                // Optionally show user error
            }
        } else {
             newQuantityDecimal = 1.0 // Reset to 1 if type doesn't support qty
        }
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
            if originalItem.quantity != newQuantityDecimal {
                 needsSave = true
            }
            let validatedUnit: String? = unitString.isEmpty ? nil : unitString
            if originalItem.unit != validatedUnit {
                newUnit = validatedUnit
                needsSave = true
            }
        } else {
            if originalItem.quantity != 1 { needsSave = true }
            newQuantityDecimal = 1.0 // Reset
            if originalItem.unit != nil { needsSave = true }
            newUnit = nil // Reset
        }


        // --- Perform Update and Trigger Save ---
        if needsSave {
            print("   Changes detected, calling list.updateItem.")
            // Call the updated method in ShoppingList
            // Pass the *potentially* modified name, price, and quantity
            list.updateItem(id: editingID,
                            newName: newName.isEmpty ? originalItem.name : newName, // Ensure non-empty name passed
                            newPrice: newPrice,
                            newQuantity: newQuantityDecimal,
                            newUnit: newUnit)
            viewModel.listDidChange(listId: list.id) // Trigger save via ViewModel
        } else {
             print("   No changes detected, save not triggered.")
        }

        resetEditingState()
    }

    // Helper to reset editing state variables
    private func resetEditingState() {
        print("--- Resetting Editing State ---")
        let currentlyEditing = editingItemID // Store ID before resetting
        editingItemID = nil
        itemEditText = ""
        itemEditPrice = ""
        itemEditQuantityString = "1"
        itemEditUnit = ""

        // Only change focus if it was previously set to the item we were editing
        if focusedFieldId == currentlyEditing {
            focusedFieldId = nil
            hideKeyboard()
        }
        // If keyboard is up but focus wasn't technically on our field (e.g., stepper interaction)
        // still try to hide it.
        else if focusedFieldId == nil && currentlyEditing != nil {
             hideKeyboard() // Ensure keyboard dismisses on Cancel/Done regardless of focus state
        }
        print("   FocusedFieldId reset to nil.")
    }

    
    // Moving item
    private func moveItem(from source: IndexSet, to destination: Int) {
        print("Moving item from \(source) to \(destination)")
        withAnimation {
            list.moveItem(from: source, to: destination)
            viewModel.listDidChange(listId: list.id) // Trigger save
        }
    }
    
    // Deleting item
    private func deleteItem(at offsets: IndexSet) {
        withAnimation {
            list.deleteItems(at: offsets)
            viewModel.listDidChange(listId: list.id) // Trigger save
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
