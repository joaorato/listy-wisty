//
//  ContentView.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ShoppingListViewModel()
    @State private var selectedList: ShoppingList? // ✅ Track newly created list
    @State private var showingCreateSheet = false // State to control the sheet
    
    @Environment(\.editMode) var editMode
    
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
                                    .opacity(editMode?.wrappedValue.isEditing ?? false ? 0.7 : 1.0)
                            }
                        }
                        .onMove(perform: moveList)
                        .onDelete(perform: deleteList)
                    }
                    .listStyle(.insetGrouped)
                }
                
                Button(action: {
                    showingCreateSheet = true // ✅ Show the alert for naming
                }) {
                    Label("Create", systemImage: "plus.circle.fill")
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
            .navigationTitle("Your Listies")
//            .alert("Name your list", isPresented: $showingAlert) {
//                TextField("Enter list Name", text: $newListName)
//                Button("Create", action: createList) // ✅ Calls `createList()`
//                Button("Cancel", role: .cancel) { newListName = "" }
//            }
            // --- Sheet for Creating List ---
            .sheet(isPresented: $showingCreateSheet) {
                // Pass the viewModel or a closure to handle list creation
                CreateListView(viewModel: viewModel) { newList in
                    // Optional: Navigate immediately after creation from sheet
                    // This logic might need refinement depending on sheet dismissal timing
                    // selectedList = newList
                }
            }
            .navigationDestination(item: $selectedList) { list in
                ShoppingListDetailView(viewModel: viewModel, list: list) // ✅ Auto-navigate after creation
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { // Place on left
                    EditButton()
                }
                // You might want other toolbar items on the trailing side if needed
            }
        }
    }
    
    private func moveList(from source: IndexSet, to destination: Int) {
        // Use animation for the data change, complementing List's visual move
        withAnimation {
            viewModel.moveList(from: source, to: destination)
        }
    }
    
    // Optional: Swipe-to-delete on ContentView
    private func deleteList(at offsets: IndexSet) {
        offsets.forEach { index in
            guard index < viewModel.lists.count else { return }
            let listToDelete = viewModel.lists[index]
            viewModel.deleteList(id: listToDelete.id)
        }
    }
    
//    private func createList() {
//        guard !newListName.isEmpty else { return }
//        let newList = viewModel.addList(name: newListName)
//        selectedList = newList // ✅ Triggers navigation
//        newListName = ""
//    }
}

// --- New View for the Creation Sheet ---
struct CreateListView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    var onListCreated: ((ShoppingList) -> Void)? // Optional callback

    @State private var newListName: String = ""
    @State private var selectedListType: ListType = .shopping // Default selection

    @Environment(\.dismiss) var dismiss
    
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationView { // Embed in NavigationView for title/toolbar
            Form {
                TextField("Title", text: $newListName)
                    .focused($isNameFieldFocused)

                Picker("Type", selection: $selectedListType) {
                    ForEach(ListType.allCases) { type in
                        // Display type's name and icon in the picker row
                        HStack {
                             Image(systemName: type.systemImageName)
                                 .foregroundColor(type.iconColor)
                             Text(type.displayName)
                        }
                        .tag(type)
                    }
                }
                // Optional: Add more configuration based on type here later
            }
            .navigationTitle("New Listy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createAndDismiss()
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) // Disable if name is empty
                }
            }
            .onAppear {
                // Delay slightly to ensure view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.isNameFieldFocused = true
                }
            }
        }
    }

    private func createAndDismiss() {
        let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newList = viewModel.addList(name: trimmedName, listType: selectedListType)
        onListCreated?(newList) // Call callback if provided
        dismiss()
    }
}

#Preview {
    ContentView()
}

// Optional Preview for the CreateListView
#Preview("Create List Sheet") {
    CreateListView(viewModel: ShoppingListViewModel()) // Provide a dummy ViewModel
}
