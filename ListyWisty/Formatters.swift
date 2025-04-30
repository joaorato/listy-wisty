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
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Use "d" for day without leading zero, "dd" for day with leading zero
        // Use "M" for month without leading zero, "MM" for month with leading zero
        // Use "yy" for 2-digit year, "yyyy" for 4-digit year
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Set locale for consistency if needed
        print("Shared Short Date Formatter Initialized - Format: \(formatter.dateFormat ?? "nil")")
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
    
    static func formatShortDate(_ date: Date?) -> String {
        guard let date = date else { return "" } // Return empty string for nil date
        return shortDateFormatter.string(from: date)
    }
    
    /// Formats the price per unit, like "€1.99 / kg" or "€5.00 / item".
    static func formatUnitPrice(price: Decimal?, unit: String?) -> String {
        guard let price = price, price != .zero else { return "" } // Don't show for zero or nil price
        
        // Format the currency part
        guard let formattedPrice = currencyFormatter.string(from: price as NSDecimalNumber) else {
            return "" // Handle formatting error
        }
        
        // Determine the unit part
        let unitString = unit?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let validUnit = unitString, !validUnit.isEmpty {
            return "\(formattedPrice) / \(validUnit)"
        } else {
            // Decide what to show if no unit: "/ item", just price, or "/ ea."?
            // Let's use "/ item" for clarity, matching the Add/Edit view placeholder.
            return "\(formattedPrice) / item"
        }
    }
    
    /// Calculates and formats the total price for an item row (price * quantity).
    static func formatTotalRowPrice(price: Decimal?, quantity: Decimal) -> String {
        guard let price = price, price != .zero else { return "" } // No total if no unit price

        let totalPrice = price * quantity
        // Use the existing currency formatter for the total
        return currencyFormatter.string(from: totalPrice as NSDecimalNumber) ?? ""
    }
}
