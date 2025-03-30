//
//  ContentView.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ShoppingListViewModel()
    @State private var newListName = ""
    @State private var showingAlert = false
    @State private var selectedList: ShoppingList? // ✅ Track newly created list

    // --- Formatter for displaying currency in this view ---
    private var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Use current locale
        // formatter.currencyCode = "EUR" // Optional: Force a specific currency
        formatter.generatesDecimalNumbers = true
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            VStack  {
                
                // if there are no lists show ContentUnavailableView instead
                if viewModel.lists.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Lists Yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Tap the button below to create your first list.")
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .listRowBackground(Color.clear)
                    
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.lists) { list in
                            NavigationLink {
                                ShoppingListDetailView(viewModel: viewModel, list: list)
                            } label: {
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
                                    // Use the totalPrice computed property
                                    Text(formatPrice(list.totalPrice))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1) // Ensure total doesn't wrap oddly
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                
                Button(action: {
                    showingAlert = true // ✅ Show the alert for naming
                }) {
                    Label("Create List", systemImage: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Your ListyWisties")
            .alert("Name your list", isPresented: $showingAlert) {
                TextField("Enter list Name", text: $newListName)
                Button("Create", action: createList) // ✅ Calls `createList()`
                Button("Cancel", role: .cancel) { newListName = "" }
            }
            .navigationDestination(item: $selectedList) { list in
                ShoppingListDetailView(viewModel: viewModel, list: list) // ✅ Auto-navigate after creation
            }
        }
    }
    
    private func formatPrice(_ price: Decimal?) -> String {
        guard let price = price, price != .zero else {
            // Optionally return empty string or "-" if total is zero
            // return ""
             return currencyFormatter.string(from: 0) ?? "" // Display "€0.00" etc.
        }
        // Convert Decimal to NSDecimalNumber for NumberFormatter
        return currencyFormatter.string(from: price as NSDecimalNumber) ?? ""
    }
    
    private func createList() {
        guard !newListName.isEmpty else { return }
        let newList = viewModel.addList(name: newListName)
        selectedList = newList // ✅ Triggers navigation
        newListName = ""
    }
}

#Preview {
    ContentView()
}
