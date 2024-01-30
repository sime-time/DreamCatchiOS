//
//  EditDreamView.swift
//  DreamCatch
//
//  Created by Simeon on 1/28/24.
//

import SwiftUI
import SwiftData

struct EditDreamView: View {
    @Bindable var dream: Dream
    @State private var newSignName = ""
    
    var body: some View {
        Form {
            TextField("Title", text: $dream.title)
            TextField("Content", text: $dream.content, axis: .vertical)
            DatePicker("Date", selection: $dream.date)
            
            Section("Lucidity") {
                Slider(value: $dream.lucidity, in: 0...1.0, step: 0.1)
            }
            
            Toggle("Nightmare", isOn: $dream.isNightmare)
            
            Section("Dream Signs") {
                ForEach(dream.signs) { sign in
                    Text(sign.name)
                }
                .onDelete(perform: deleteSigns)
                
                HStack {
                    TextField("Add a new dream sign...", text: $newSignName)
                    Button("Add", action: addSign)
                }
            }
        }
        .navigationTitle("Edit Dream")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func addSign() {
        guard newSignName.isEmpty == false else { return }
        
        withAnimation {
            let sign = DreamSign(name: newSignName)
            dream.signs.append(sign)
            newSignName = ""
        }
    }
    
    func deleteSigns(_ indexSet: IndexSet) {
        for index in indexSet {
            dream.signs.remove(at: index)
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try ModelContainer(for: Dream.self, configurations: config)
        
        let example = Dream(title: "Ghost Ship", content: "I had a big sword and I fought tentacle seamonsters controlling a sunken pirate ship.", date: .now, lucidity: 0.6, isNightmare: true)
        
        return EditDreamView(dream: example).modelContainer(container)
        
    } catch {
        fatalError("Failed to create model container.")
    }
}
