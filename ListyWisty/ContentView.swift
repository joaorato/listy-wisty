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

    
    var body: some View {
        NavigationStack {
            VStack  {
                List {
                    // --- Check if lists are empty ---
                    if viewModel.lists.isEmpty {
                        ContentUnavailableView(
                            "No Lists Yet",
                            systemImage: "list.bullet.clipboard",
                            description: Text("Tap the button below to create your first list.")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.lists) { list in
                            NavigationLink(destination: ShoppingListDetailView(viewModel: viewModel, list: list)) {
                                HStack {
                                    Image(systemName: "cart")
                                        .foregroundColor(.blue)
                                    Text(list.name)
                                        .font(.headline)
                                }
                                .padding(5)
                            }
                        }
                        // list row separator styling (iOS 15+)
                        //.listRowSeparator(.hidden)
                    }
                }
                .listStyle(.insetGrouped)
                
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
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Your Lists")
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
