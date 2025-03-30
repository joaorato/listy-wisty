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

        do {
            let data = try Data(contentsOf: dataFileURL)
            let decoder = JSONDecoder()
            lists = try decoder.decode([ShoppingList].self, from: data)
            print("✅ Lists loaded successfully.")
        } catch {
            print("❌ Error loading lists: \(error.localizedDescription)")
            // Handle error, maybe delete corrupted file or start fresh
             lists = [] // Start fresh if decoding fails
        }
    }
    
    @discardableResult
    func addList(name: String) -> ShoppingList {
        let newList = ShoppingList(name: name)
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
