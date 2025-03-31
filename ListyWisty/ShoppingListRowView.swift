//
//  ShoppingListRowView.swift
//  ListyWisty
//
//  Created by João Rato on 31/03/2025.
//

import SwiftUI

struct ShoppingListRowView: View {
    @ObservedObject var list: ShoppingList // Observe the individual list

    var body: some View {
        HStack {
            // Left side: Icon and Name
            Image(systemName: "cart")
                .foregroundColor(.blue)
            Text(list.name)
                .font(.headline)
                // Allow name to shrink if needed, but give priority
                .layoutPriority(1)
                .lineLimit(1) // Prevent name wrapping interfering too

            Spacer() // Pushes the total price to the right

            // Right side: Formatted Total Price
            // Use the totalPrice computed property - this will now update
            // when the observed 'list' object changes.
            Text(Formatters.formatPriceForDisplay(list.totalPrice))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1) // Ensure total doesn't wrap oddly
        }
        .padding(.vertical, 5)
        // The .id is important if you rely on list identity for animations or transitions
        // within the ForEach. Often needed when list order can change.
        .id(list.id)
    }
}
