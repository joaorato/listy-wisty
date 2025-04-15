//
//  ListyWistyApp.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI

@main
struct ListyWistyApp: App {
    
    @StateObject var viewModel = ShoppingListViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel) // Pass the ViewModel down
                .onOpenURL { url in
                    print("--- .onOpenURL TRIGGERED with URL: \(url.path) ---")
                    // Call the static handler function from ShareExportManager
                    ShareExportManager.handleIncomingURL(url, viewModel: viewModel)
                }
        }
    }
}
