//
//  ListType.swift
//  ListyWisty
//
//  Created by João Rato on 13/04/2025.
//


// ListType.swift (New File)
import Foundation
import SwiftUI // For Color, Image names

enum ListType: String, CaseIterable, Identifiable, Codable {
    case shopping = "Shopping"
    case task = "Tasks"
    // Add more cases here later if needed, e.g., .wishlist, .checklist

    var id: String { self.rawValue }

    // User-facing display name
    var displayName: String {
        switch self {
        case .shopping: return "Shopping List"
        case .task: return "To-Do List"
        }
    }

    // Icon for the list row and potentially detail view
    var systemImageName: String {
        switch self {
        case .shopping: return "cart"
        case .task: return "checklist" // Or "list.bullet"
        }
    }

    // Icon color (optional, for visual distinction)
    var iconColor: Color {
        switch self {
        case .shopping: return .blue
        case .task: return .orange
        }
    }

    // --- Properties Relevant to this List Type ---
    // These flags help the UI decide what to show/enable

    var supportsPrice: Bool {
        return self == .shopping
    }

    var supportsQuantity: Bool {
        return self == .shopping
    }

    var supportsDeadline: Bool { // Example for future use
        return self == .task
    }
}