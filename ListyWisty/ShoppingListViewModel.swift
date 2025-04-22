//
//  ShoppingListViewModel.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//
import SwiftUI

class ShoppingListViewModel: ObservableObject {
    @Published var lists: [ShoppingList] = []
    private let aiService = AIService()
    
    // Keep track if we loaded data or used injected data
    private var didLoadFromFile = false
    
    private var dataFileURL: URL {
        // Use the app's document directory
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShoppingLists.json")
    }
    
    // Existing initializer becomes a convenience initializer
    convenience init() {
        // Pass nil to the designated initializer to trigger loading
        self.init(initialLists: nil)
    }
    
    init(initialLists: [ShoppingList]?) {
        if let listsToUse = initialLists {
            print("🔄 ViewModel Initialized with injected data (\(listsToUse.count) lists). Skipping file load.")
            self.lists = listsToUse
            self.didLoadFromFile = false // Mark that we didn't load
        } else {
            print("🔄 ViewModel Initializing, will attempt to load from file.")
            loadLists() // Call loadLists only if no initial data provided
            self.didLoadFromFile = true // Mark that we attempted load
        }
    }
    
    // --- SAVE Function ---
    func saveLists() {
        // Optionally, only save if data was originally loaded from file or modified since injection
        // This prevents tests that inject data from overwriting the user's real data file accidentally.
        guard didLoadFromFile || !lists.isEmpty else { // Basic check: Save if loaded or if injected data exists
            print("💾 Skipping save: Data was injected and is now empty, or initial load failed/was empty.")
            return
        }
        print("💾 Attempting to save lists...")
        // --- Debug Print Start ---
        if let listToDebug = lists.first, let itemToDebug = listToDebug.items.first {
             print("   Saving List '\(listToDebug.name)', First Item '\(itemToDebug.name)', isChecked: \(itemToDebug.isChecked)")
        } else if let listToDebug = lists.first {
            print("   Saving List '\(listToDebug.name)', No items yet.")
        } else {
             print("   Saving: No lists to save.")
        }
        // --- Debug Print End ---
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Makes JSON readable

        do {
            let data = try encoder.encode(lists) // Encode the whole array
            try data.write(to: dataFileURL, options: [.atomicWrite]) // Save atomically
            print("✅ Lists saved successfully to: \(dataFileURL.path)")
        } catch {
            print("❌ Error saving lists: \(error.localizedDescription)")
            // Consider showing an error to the user here
        }
    }
    
    // --- LOAD Function ---
    private func loadLists() {
        guard FileManager.default.fileExists(atPath: dataFileURL.path) else {
            print("ℹ️ No save file found, starting fresh.")
            return // No file exists yet
        }
        print("💾 Attempting to load lists from: \(dataFileURL.path)")
        do {
            let data = try Data(contentsOf: dataFileURL)
            let decoder = JSONDecoder()
            let loadedLists = try decoder.decode([ShoppingList].self, from: data)
            
            // --- Debug Print Start ---
            if let listToDebug = loadedLists.first, let itemToDebug = listToDebug.items.first {
                 print("   Loaded List '\(listToDebug.name)', First Item '\(itemToDebug.name)', isChecked: \(itemToDebug.isChecked)")
            } else if let listToDebug = loadedLists.first {
               print("   Loaded List '\(listToDebug.name)', No items yet.")
            } else {
                 print("   Loaded: No lists found in file.")
            }
            // --- Debug Print End ---
            self.lists = loadedLists // Assign to @Published property
            print("✅ Lists loaded successfully.")
        } catch {
            print("❌ Error loading lists: \(error.localizedDescription)")
            print("--- Error Details ---")
            dump(error) // Prints more detailed info about the decoding error
            print("---------------------")
            // Consider deleting the corrupt file or informing the user
            // For now, we still start fresh if loading fails:
            print("⚠️ Starting with empty list due to load error.")
            lists = []
        }
    }
    
    @discardableResult
    func addList(name: String, listType: ListType) -> ShoppingList {
        let newList = ShoppingList(name: name, listType: listType)
        lists.append(newList)
        saveLists() // Save after adding
        return newList
    }
    
    func deleteList(id: UUID) {
        lists.removeAll { $0.id == id }
        saveLists() // Save after deleting
    }
    
    func moveList(from source: IndexSet, to destination: Int) {
        print("➡️ Attempting to move lists from \(source) to \(destination)")
        lists.move(fromOffsets: source, toOffset: destination)
        // Save the new order immediately
        saveLists()
        print("✅ Lists moved and saved.")
    }
    
    // public endpoint to trigger a save when something *inside* a list changes
    func listDidChange() {
        print("ℹ️ List content changed, triggering save.")
        saveLists()
    }
    
    @MainActor
    func addItem(
        name: String,
        quantity: Int = 1, // Default quantity
        unit: String? = nil, // Default unit
        price: Decimal? = nil, // Default price
        toList list: ShoppingList // Keep list parameter non-optional
    ) async { // Keep async if potential future versions need it, otherwise make sync
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            print("ℹ️ ViewModel: addItem - Name was empty.")
            return
        }
        guard let listIndex = lists.firstIndex(where: { $0.id == list.id }) else {
            print("❌ ViewModel: List not found for adding item.")
            return
        }

        // Validate quantity is at least 1
        let finalQuantity = max(1, quantity)
        // Ensure unit is nil if empty/whitespace
        let finalUnit = unit?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()

        let newItem = ShoppingItem(
            name: trimmedName,
            price: price, // Use provided price or default nil
            quantity: finalQuantity, // Use provided quantity or default 1 (validated)
            unit: finalUnit // Use provided unit or default nil (cleaned)
        )
        
        // --- Find the correct insertion index ---
        let insertionIndex = lists[listIndex].items.firstIndex { $0.isChecked } ?? lists[listIndex].items.endIndex

        // Append and Save
        lists[listIndex].items.insert(newItem, at: insertionIndex)
        print("✅ ViewModel: Inserted item '\(newItem.name)' at index \(insertionIndex) (Qty: \(newItem.quantity), Unit: \(newItem.unit ?? "nil"), Price: \(String(describing: newItem.price))) to list '\(lists[listIndex].name)'")

        listDidChange() // Trigger save
    }
    
    @MainActor // Ensure updates to list happen on the main thread
    func parseAndAddItems(text: String, to list: ShoppingList) async throws {
        guard let listIndex = lists.firstIndex(where: { $0.id == list.id }) else {
            print("❌ ViewModel: List not found for adding items.")
            return
        }
        
        do {
            let parsedItems = try await aiService.parseItems(from: text, listType: list.listType)

            guard !parsedItems.isEmpty else {
                 print("ℹ️ ViewModel: AI Service returned no items to add.")
                 return // Nothing to add
             }

            // Create ShoppingItem objects from parsed data
            let newItemsToAdd = parsedItems.map { parsedItem -> ShoppingItem in
                let quantity = max(1, parsedItem.quantity ?? 1) // Ensure quantity >= 1
                let unit = parsedItem.unit?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
                return ShoppingItem(name: parsedItem.name, isChecked: false, quantity: quantity, unit: unit)
                // Note: Price is not currently parsed by AI in this setup
            }

            // --- Find the correct insertion index (same logic as addItem) ---
            let insertionIndex = lists[listIndex].items.firstIndex { $0.isChecked } ?? lists[listIndex].items.endIndex

            // --- Insert all new items at that index ---
            // This keeps the batch together and places them before checked items.
            lists[listIndex].items.insert(contentsOf: newItemsToAdd, at: insertionIndex)
            print("✅ ViewModel: Inserted \(newItemsToAdd.count) parsed items at index \(insertionIndex) in list '\(lists[listIndex].name)'")

            // Trigger save
            listDidChange()
        } catch {
            print("❌ ViewModel: Error parsing or adding items: \(error)")
            throw error
        }
    }
}
