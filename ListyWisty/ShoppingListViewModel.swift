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
    
    private var dataFileURL: URL {
        // Use the app's document directory
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShoppingLists.json")
    }
    
    init() {
        loadLists() // Load lists when the ViewModel is created
    }
    
    // --- SAVE Function ---
    func saveLists() {
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

            // Add the parsed items to the specific list's items array
            var updatedItems = lists[listIndex].items
            for parsedItem in parsedItems {
                // Default quantity to 1 if LLM returns nil (shouldn't happen with good prompt but defensive)
                let quantity = parsedItem.quantity ?? 1
                let newItem = ShoppingItem(name: parsedItem.name, quantity: quantity, unit: parsedItem.unit)
                updatedItems.append(newItem)
                print("   ViewModel: Preparing to add item - \(newItem.name), Qty: \(newItem.quantity), Unit: \(newItem.unit ?? "nil")")
            }

            // Update the list's items - this triggers @Published update for ShoppingListDetailView
            lists[listIndex].items = updatedItems
            print("✅ ViewModel: Added \(parsedItems.count) items to list '\(lists[listIndex].name)'")

            // Trigger save
            listDidChange()
        } catch {
            print("❌ ViewModel: Error parsing or adding items: \(error)")
            throw error
        }
    }
}
