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
            // Use list type's icon and color
            Image(systemName: list.listType.systemImageName)
                .foregroundColor(list.listType.iconColor) // Use type's color
            
            VStack(alignment: .leading) { // Use VStack to stack name and progress/price
                Text(list.name)
                    .font(.headline)
                    .lineLimit(1)

                // --- Conditional Progress/Price ---
                if list.listType == .task {
                    // Show Progress for Task lists
                    if !list.items.isEmpty { // Only show if items exist
                        ProgressView(value: list.completionPercentage)
                            .progressViewStyle(.linear)
                            .tint(list.listType.iconColor) // Use list color
                            // Optional: Constrain height for aesthetics
                            .frame(height: 5)
                    } else {
                        // Optional: Text for empty task list
                        Text("No tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                // Optionally, add spacing if needed
                // Spacer().frame(height: 2)
            }
            .layoutPriority(1)

            Spacer() // Pushes the total price to the right
            
            // --- Conditional Total/Percentage Text ---
            if list.listType == .shopping {
                Text(Formatters.formatPriceForDisplay(list.totalPrice))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else if list.listType == .task {
                // Show Percentage Text for Task lists
                Text("\(Int(list.completionPercentage * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    // Optional: Add minimum width to prevent jumping
                    .frame(minWidth: 40, alignment: .trailing)
            }
        }
        .padding(.vertical, 5)
        // The .id is important if you rely on list identity for animations or transitions
        // within the ForEach. Often needed when list order can change.
        .id(list.id)
    }
}
