//
//  ActivityViewRepresentable.swift
//  ListyWisty
//
//  Created by João Rato on 14/04/2025.
//

import SwiftUI
import UIKit

struct ActivityViewRepresentable: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    @Environment(\.dismiss) var dismiss // To potentially dismiss if needed

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        
        // Optional: Completion handler to know when sharing is done
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
             print("Share sheet completed. Activity: \(String(describing: activityType)), Completed: \(completed), Error: \(String(describing: error))")
             // You could dismiss the sheet programmatically here if needed,
             // but SwiftUI's sheet presentation usually handles dismissal automatically.
             // self.dismiss()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed usually
    }
}

struct ShareableURL: Identifiable {
    let id = UUID() // Provides the Identifiable conformance
    let url: URL
}
