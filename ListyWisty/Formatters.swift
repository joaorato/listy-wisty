//
//  Formatters.swift
//  ListyWisty
//
//  Created by João Rato on 31/03/2025.
//

import Foundation

struct Formatters {
    // Static instance for currency DISPLAY
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        // formatter.currencyCode = "EUR" // Set globally if desired, or configure per use case if needed
        formatter.generatesDecimalNumbers = true
        print("Shared Currency Formatter Initialized - Locale: \(formatter.locale.identifier), Decimal Separator: '\(formatter.decimalSeparator ?? "nil")'")
        return formatter
    }()

    // Static instance for decimal INPUT/EDITING
    static let decimalInputFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.generatesDecimalNumbers = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2 // Adjust as needed
        // formatter.usesGroupingSeparator = false // Optional: Simplify editing
        print("Shared Decimal Input Formatter Initialized - Locale: \(formatter.locale.identifier), Decimal Separator: '\(formatter.decimalSeparator ?? "nil")'")
        return formatter
    }()

    // Static helper function for display formatting (avoids repetition in views)
    static func formatPriceForDisplay(_ price: Decimal?) -> String {
        guard let price = price else { return "" } // Return empty for nil
        // Handle zero specifically for consistent display like "$0.00"
        if price == .zero {
             return currencyFormatter.string(from: 0) ?? ""
        }
        return currencyFormatter.string(from: price as NSDecimalNumber) ?? ""
    }

    // Optional: Static helper for parsing, though commitItemEdit has specific logic
    // static func parseDecimalInput(_ string: String) -> Decimal? {
    //    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    //    if trimmed.isEmpty { return nil } // Or handle as zero if desired
    //    return decimalInputFormatter.number(from: trimmed)?.decimalValue
    // }
}
