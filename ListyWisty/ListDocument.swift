//
//  ListDocument.swift
//  ListyWisty
//
//  Created by João Rato on 15/04/2025.
//

import UIKit
import SwiftUI // For ShoppingList definition

class ListDocument: UIDocument {

    var shoppingList: ShoppingList? // Holds the decoded list

    // Called when UIDocument needs to load data from the file URL
    override func contents(forType typeName: String) throws -> Any {
        // This method is primarily for SAVING, return the data to be saved.
        // We handle loading in load(fromContents:ofType:)
        guard let list = shoppingList else { return Data() } // Return empty data if nothing to save

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            return try encoder.encode(list)
        } catch {
            print("❌ Error encoding ShoppingList in ListDocument: \(error)")
            throw error // Re-throw the error
        }
    }

    // Called when UIDocument needs to load data INTO the document object
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        print("ListDocument: Attempting to load contents...")
        guard let data = contents as? Data else {
            print("❌ ListDocument: Contents are not Data.")
            // Throw an error indicating wrong data type
            throw CocoaError(.fileReadCorruptFile)
        }

        guard !data.isEmpty else {
             print("⚠️ ListDocument: Contents data is empty.")
             // Treat as empty/new document or throw error? Let's allow empty for now.
             // You could create a default empty list here if desired.
             self.shoppingList = nil // Or ShoppingList(name: "Imported Empty List") etc.
             return
        }


        let decoder = JSONDecoder()
        do {
            let decodedList = try decoder.decode(ShoppingList.self, from: data)
            print("✅ ListDocument: Successfully decoded ShoppingList '\(decodedList.name)'")
            self.shoppingList = decodedList // Store the loaded list
        } catch {
            print("❌ ListDocument: Error decoding ShoppingList: \(error)")
            dump(error) // Log detailed decoding error
            throw error // Re-throw the error
        }
    }
}
