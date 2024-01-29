//
//  ContentView.swift
//  DreamCatch
//
//  Created by Simeon on 1/28/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @State private var path = [Dream]()
    @State private var sortOrder = SortDescriptor(\Dream.title)
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack(path: $path) {
            DreamListView(sort: sortOrder, searchString: searchText)
                .navigationTitle("DreamCatch")
                .navigationDestination(for: Dream.self, destination: EditDreamView.init)
                .searchable(text: $searchText) 
                .toolbar {
                    Button("Add Dream", systemImage: "plus", action: addDream)
                    
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        Picker("Sort", selection: $sortOrder) {
                            Text("Title")
                                .tag(SortDescriptor(\Dream.title))
                            
                            Text("Lucidity")
                                .tag(SortDescriptor(\Dream.lucidity, order: .reverse))
                            
                            Text("Date")
                                .tag(SortDescriptor(\Dream.date, order: .reverse))
                        }
                        .pickerStyle(.inline) 
                    }
                }
        }
    }
    
    func addDream() {
        let dream = Dream()
        modelContext.insert(dream)
        path = [dream] // go to EditDreamView on current dream
    }
}

#Preview {
    ContentView()
}
