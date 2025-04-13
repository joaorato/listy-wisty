//
//  ShoppingListViewModel.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//
import SwiftUI

class ShoppingListViewModel: ObservableObject {
    @Published var lists: [ShoppingList] = []
    
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
    
    // public endpoint to trigger a save when something *inside* a list changes
    func listDidChange() {
        print("ℹ️ List content changed, triggering save.")
        saveLists()
    }
}
