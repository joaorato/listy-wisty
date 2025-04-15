//
//  ShareExportManager.swift
//  ListyWisty
//
//  Created by João Rato on 14/04/2025.
//

import Foundation
import SwiftUI // Needed for ShoppingListViewModel dependency potentially

// Using a struct with static methods as it doesn't need state itself
struct ShareExportManager {

    // MARK: - Export

    static func exportListToFile(_ list: ShoppingList) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Makes it human-readable

        do {
            let data = try encoder.encode(list)

            // Create a filename (sanitize list name for file system)
            let sanitizedName = list.name.replacingOccurrences(of: "[^a-zA-Z0-9_.]", with: "_", options: .regularExpression)
            let filename = "\(sanitizedName).listywisty" // Use a custom extension
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            // Write the data to the temporary file
            try data.write(to: tempURL, options: .atomic)
            print("✅ Successfully exported list '\(list.name)' to temporary file: \(tempURL.path)")
            return tempURL

        } catch {
            print("❌ Error exporting list '\(list.name)': \(error)")
            return nil
        }
    }

    // MARK: - Import

    static func handleIncomingURL(_ url: URL, viewModel: ShoppingListViewModel) {
        print("App attempting to handle URL using UIDocument: \(url.absoluteString)")

        let expectedExtension = "listywisty"
        guard url.isFileURL, url.pathExtension.lowercased() == expectedExtension else {
            print("⚠️ Incoming URL is not a recognized '\(expectedExtension)' file.")
            return
        }

        // --- Use UIDocument ---
        let document = ListDocument(fileURL: url)

        // Open the document. UIDocument handles coordination and security scoping internally.
        document.open { success in
            // This completion handler is called AFTER the document tries to open and load.
            // It's crucial to perform UI updates (like adding to ViewModel) on the main thread.
            DispatchQueue.main.async {
                guard success else {
                    print("❌ Failed to open ListDocument at URL: \(url.absoluteString)")
                    // TODO: Show user alert about failure to open file
                    document.presentedItemDidChange() // Might help release resources
                    return
                }

                print("✅ Successfully opened ListDocument.")

                // Access the loaded data (if any)
                guard let loadedList = document.shoppingList else {
                    print("⚠️ ListDocument opened successfully, but contained no ShoppingList data (or failed decoding earlier).")
                    // Handle appropriately - maybe show an alert?
                    document.close() // Close the successfully opened but empty/invalid document
                    return
                }

                let originalID = loadedList.id
                print("   Loaded list name: '\(loadedList.name)', ID: \(originalID)")

                // --- Create a NEW List with a NEW ID ---
                let importedList = ShoppingList(
                    id: UUID(), // Generate new ID
                    name: loadedList.name + " (Imported)",
                    items: loadedList.items,
                    listType: loadedList.listType
                )

                print("   Created new imported list '\(importedList.name)' with new ID \(importedList.id)")

                // --- Add to ViewModel and Save ---
                print("   Adding imported list to ViewModel...")
                viewModel.lists.append(importedList)
                viewModel.saveLists()
                print("   List appended and ViewModel saved.")
                // TODO: Show user alert confirming success

                // --- Attempt to delete the Inbox file AFTER successful import and save ---
                do {
                    print("   Attempting to remove original file from Inbox: \(url.path)")
                    try FileManager.default.removeItem(at: url)
                    print("   Successfully removed file from Inbox.")
                } catch {
                    // Log the error, but don't necessarily treat it as a critical failure
                    // of the import itself, as the data is already saved.
                    print("⚠️ Could not remove file from Inbox: \(error.localizedDescription). This is non-critical as data was imported.")
                }
                
                // Close the document once we're done with its data
                document.close { closeSuccess in
                    if !closeSuccess {
                        print("⚠️ Failed to close ListDocument cleanly, but import was likely successful.")
                    } else {
                        print("   ListDocument closed successfully.")
                    }
                }
            } // End DispatchQueue.main.async
        } // End document.open completion handler
    }
}
