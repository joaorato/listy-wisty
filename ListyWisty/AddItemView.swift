//
//  AddItemView.swift
//  ListyWisty
//
//  Created by João Rato on 19/04/2025.
//

import SwiftUI

struct AddItemView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    let list: ShoppingList // Pass the specific list we're adding to

    // Environment
    @Environment(\.dismiss) var dismiss

    // Item State
    @State private var itemName: String = ""
    @State private var itemQuantityString: String = "1"
    @State private var itemUnit: String = ""
    @State private var itemPriceString: String = "" // Use String for TextField binding

    // AI State
    @State private var useAIParser: Bool = false // Toggle for AI
    @State private var isProcessing: Bool = false // Loading indicator
    @State private var processingError: String? = nil // Error display

    // Focus State
    @FocusState private var isNameFieldFocused: Bool

    // Computed properties for convenience
    private var supportsQuantity: Bool { list.listType.supportsQuantity }
    private var supportsPrice: Bool { list.listType.supportsPrice }

    var body: some View {
        NavigationView {
            Form {
                // --- AI Parser Toggle ---
                Section {
                    Toggle("Parse multiple items with AI ✨", isOn: $useAIParser.animation())
                }

                // --- Input Fields ---
                Section(header: Text(useAIParser && list.listType == .shopping ? "Enter Items (e.g., 2 apples, milk)" : "Item Details")) {
                    TextField("Name", text: $itemName)
                        .focused($isNameFieldFocused)

                    // Show standard fields only if NOT using AI parser
                    if !useAIParser {
                        if supportsQuantity {
                            HStack { // Use HStack for custom quantity input
                                Text("Qty:")
                                Button { decrementQuantity() } label: { Image(systemName: "minus.circle") }
                                    .buttonStyle(.borderless)
                                    .disabled(decimalQuantityValue <= 0.001)

                                TextField("Qty", text: $itemQuantityString)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.center)

                                Button { incrementQuantity() } label: { Image(systemName: "plus.circle") }
                                     .buttonStyle(.borderless)

                                Spacer() // Push unit field right
                            } // End Quantity HStack

                            TextField("Unit (e.g., kg, box)", text: $itemUnit)
                                .autocapitalization(.none)
                        }
                        if supportsPrice {
                            HStack { // Group price field and label
                                TextField("Price", text: $itemPriceString)
                                    .keyboardType(.decimalPad)
                                Text(priceUnitLabel) // Use computed label
                                     .font(.caption)
                                     .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // --- Error Display ---
                if let error = processingError {
                    Section {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Item(s)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            await addItemAction()
                        }
                    }
                    .disabled(itemName.isBlank || isProcessing) // Disable if empty or processing
                }
            }
            .overlay { // Loading overlay
                if isProcessing {
                    ProgressView(useAIParser ? "Parsing..." : "Adding...")
                        .padding()
                        .background(.ultraThickMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .onAppear {
                // Delay focus slightly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isNameFieldFocused = true
                }
            }
        }
    }

    // --- Action Logic ---
    private func addItemAction() async {
        let nameToAdd = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nameToAdd.isEmpty else { return }

        isProcessing = true
        processingError = nil

        do {
            if useAIParser {
                // Call AI parsing method in ViewModel
                try await viewModel.parseAndAddItems(text: nameToAdd, to: list)
            } else {
                // --- Add Single Detailed Item ---
                // Parse price string
                let priceDecimal: Decimal? = parsePrice(itemPriceString)

                // Get unit (nil if empty)
                let finalUnit = itemUnit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()

                // Ensure quantity is valid
                let quantityDecimal: Decimal
                if let parsedQty = Formatters.decimalInputFormatter.number(from: itemQuantityString)?.decimalValue {
                    quantityDecimal = max(Decimal(0.001), parsedQty) // Validate minimum
                } else {
                    print("⚠️ AddItemView: Invalid quantity '\(itemQuantityString)', defaulting to 1.")
                    quantityDecimal = 1.0 // Default if parsing fails
                }

                // Call a *new* ViewModel method for detailed single item addition
                await viewModel.addItem(
                    name: nameToAdd,
                    quantity: quantityDecimal,
                    unit: finalUnit,
                    price: priceDecimal, // Pass parsed price
                    toList: list
                )
                 // Assuming addDetailedItem doesn't throw for now
            }
            // Success
            dismiss()

        } catch let error as AIServiceError {
             print("❌ AddItemView: AIServiceError - \(error)")
             processingError = errorMessage(for: error) // Use existing helper
        } catch {
             print("❌ AddItemView: Unknown error - \(error)")
             processingError = "An unexpected error occurred."
        }

        isProcessing = false
    }

    // --- Helper Functions ---

    private var decimalQuantityValue: Decimal {
        Formatters.decimalInputFormatter.number(from: itemQuantityString)?.decimalValue ?? 0
    }
    
    private func incrementQuantity() {
        let newValue = decimalQuantityValue + 1
        itemQuantityString = Formatters.decimalInputFormatter.string(for: newValue) ?? itemQuantityString
    }
    
    private func decrementQuantity() {
        let newValue = max(Decimal(0.001), decimalQuantityValue - 1)
        itemQuantityString = Formatters.decimalInputFormatter.string(for: newValue) ?? itemQuantityString
    }
    
    private var priceUnitLabel: String {
        let unit = itemUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        return unit.isEmpty ? "€ / item" : "€ / \(unit)"
    }
    
    private func parsePrice(_ priceString: String) -> Decimal? {
        let trimmedString = priceString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return nil }
        return Formatters.decimalInputFormatter.number(from: trimmedString)?.decimalValue
    }

    private func errorMessage(for error: AIServiceError) -> String {
         switch error {
         case .networkError: return "Please check your internet connection."
         case .decodingError: return "Received an unexpected response from the server."
         case .serverError(_, let message): return message ?? "The AI server returned an error."
         case .invalidResponseFormat: return "Received an invalid response format."
         case .apiKeyMissing: return "AI service configuration error."
         case .backendProxyError(let message): return "AI service failed: \(message)"
         case .llmError(let details):
             print("LLM Error Details: \(details)")
             if details == "AI model is currently unavailable." {
                 return "The AI service is temporarily unavailable. Please try again later."
             }
             return "The AI failed to understand the items. Try phrasing differently or adding items manually."
         }
    }
}

// Add Previews if desired
#Preview {
     // Need a dummy list and view model
     let previewList = ShoppingList(name: "Sample Shopping", listType: .shopping)
     previewList.items = [ShoppingItem(name: "Existing")]
     let previewVM = ShoppingListViewModel()
     previewVM.lists = [previewList]

     // Wrap AddItemView for preview context
     return AddItemView(viewModel: previewVM, list: previewList)
}

// String extensions can be moved to a shared location
// extension String { ... isBlank, nilIfEmpty ... }
