//
//  DreamListView.swift
//  DreamCatch
//
//  Created by Simeon on 1/28/24.
//

import SwiftUI
import SwiftData

struct DreamListView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Dream.date, order: .reverse) var dreams: [Dream]

    var body: some View {
        List {
            ForEach(dreams) { dream in
                NavigationLink(value: dream) {
                    VStack(alignment: .leading) {
                        Text(dream.title)
                            .font(.headline)
                        
                        Text(dream.date.formatted(date: .long, time: .shortened))
                    }
                }
            }
            .onDelete(perform: deleteDreams)
        }
    }
    
    init(sort: SortDescriptor<Dream>, searchString: String) {
        _dreams = Query(filter: #Predicate {
            if searchString.isEmpty {
                return true
            } else {
                // search the title or content of the dream
                return $0.title.localizedStandardContains(searchString) || $0.content.localizedStandardContains(searchString)
            }
        }, sort: [sort])
    }
    
    func deleteDreams(_ indexSet: IndexSet) {
        for index in indexSet {
            let dream = dreams[index]
            modelContext.delete(dream)
        }
    }
}

#Preview {
    DreamListView(sort: SortDescriptor(\Dream.title), searchString: "")
}
