//
//  AddListView.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//
import SwiftUI

struct AddShoppingListView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    @State private var listName = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                TextField("List Name", text: $listName)
            }
            .navigationTitle("New List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addList(name: listName)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
