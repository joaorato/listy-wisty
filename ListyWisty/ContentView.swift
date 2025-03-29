//
//  ContentView.swift
//  ListyWisty
//
//  Created by João Rato on 29/03/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ShoppingListViewModel()
    @State private var showingAddList = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.lists) { list in
                    NavigationLink(destination: ShoppingListDetailView(list: list)) {
                        Text(list.name)
                    }
                }
            }
            .navigationTitle("Your Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddList = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddList) {
                AddShoppingListView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
