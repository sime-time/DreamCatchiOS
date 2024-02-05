//
//  RecordView.swift
//  DreamCatch
//
//  Created by Simeon on 1/30/24.
//

import SwiftUI
import SiriWaveView

struct RecordView: View {
    @State var vm = ViewModel()
    @State var isRecording: Bool = false 
    @State var isSymbolAnimating: Bool = false
 
    var body: some View {
        VStack {
            switch vm.state {
            case .recordingSpeech:
                Text("Recording Dream")
                    .font(.title2)
                
                SiriWaveView()
                    .power(power: vm.audioPower)
                    .opacity(vm.siriWaveFormOpacity)
                    .frame(height: 256)
                
                Spacer()
                
            case .processingSpeech:
                Spacer()
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    .symbolEffect(.bounce.up.byLayer,
                                  options: .repeating,
                                  value: isSymbolAnimating)
                    .font(.system(size: 128))
                    .onAppear { isSymbolAnimating = true }
                    .onDisappear { isSymbolAnimating = false }
                
                Spacer()
                Text("Adding Dream...")
                    .font(.title2)
                Spacer()
    
            default:
                Spacer()
            }
            ZStack {
                
                RecordButton(isRecording: $isRecording) {
                    vm.state = .recordingSpeech
                    vm.startCaptureAudio()
                } stopAction: {
                    vm.state = .processingSpeech
                    vm.finishCaptureAudio()
                }
                .frame(width: 70, height: 70, alignment: .center)
    
                
                switch vm.state {
                case .recordingSpeech:
                    cancelRecordingButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                case .processingSpeech:
                    cancelProcessingButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                default:
                    EmptyView()
                }
            }
        }
    }
    
    var cancelRecordingButton: some View {
        Button(role: .destructive) {
            isRecording = false
            vm.cancelRecording()
        } label: {
            Text("cancel")
                .foregroundStyle(.accent)
        }
    }
    
    var cancelProcessingButton: some View {
        Button(role: .destructive) {
            vm.cancelProcessingTask()
        } label: {
            Text("cancel")
                .foregroundStyle(.accent)
        }
    }
    
}

#Preview {
    RecordView()
}
/*
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
*/
