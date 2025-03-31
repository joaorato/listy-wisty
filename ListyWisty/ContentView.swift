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
                                ShoppingListRowView(list: list)
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
