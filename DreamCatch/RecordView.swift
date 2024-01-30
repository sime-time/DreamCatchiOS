//
//  RecordView.swift
//  DreamCatch
//
//  Created by Simeon on 1/30/24.
//

import SwiftUI

struct RecordView: View {
    @State var vm = ViewModel()

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}


#Preview("Idle") {
    RecordView()
}

#Preview("Recording Speech") {
    let vm = ViewModel() 
    vm.state = DreamRecordState.recordingSpeech
    return RecordView(vm: vm)
}

#Preview("Processing Speech") {
    let vm = ViewModel()
    vm.state = DreamRecordState.processingSpeech
    return RecordView(vm: vm)
}

#Preview("Error") {
    let vm = ViewModel()
    vm.state = DreamRecordState.error("An error has occurred")
    return RecordView(vm: vm)
}

