//
//  ContentView.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ShoppingListViewModel()
    @State private var newListName = ""
    @State private var showingAlert = false
    @State private var selectedList: ShoppingList? // ✅ Track newly created list

    
    var body: some View {
        NavigationStack {
            VStack  {
                List {
                    ForEach(viewModel.lists) { list in
                        NavigationLink(destination: ShoppingListDetailView(list: list)) {
                            HStack {
                                Image(systemName: "cart")
                                    .foregroundColor(.blue)
                                Text(list.name)
                                    .font(.headline)
                            }
                            .padding(5)
                        }
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
            .navigationTitle("ListyWisty")
            .alert("Name your list", isPresented: $showingAlert) {
                TextField("Enter list Name", text: $newListName)
                Button("Create", action: createList) // ✅ Calls `createList()`
                Button("Cancel", role: .cancel) { newListName = "" }
            }
            .navigationDestination(item: $selectedList) { list in
                ShoppingListDetailView(list: list) // ✅ Auto-navigate after creation
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
