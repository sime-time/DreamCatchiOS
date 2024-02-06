//
//  RecordView.swift
//  DreamCatch
//
//  Created by Simeon on 1/30/24.
//

import SwiftUI
import SiriWaveView
import SwiftData

struct RecordView: View {
    @Binding var modelContext: ModelContext
    @State var vm: ViewModel
    @State var isRecording: Bool = false
    @State var isSymbolAnimating: Bool = false
    
    init(mc: ModelContext) {
        self.vm = ViewModel(mc: mc)
        self._modelContext = Binding.constant(mc)
    }
 
    var body: some View {
        VStack {
            switch vm.state {
            case .recordingSpeech:
                Text("Recording Dream")
                    .font(.title2)
                
                SiriWaveView()
                    .power(power: vm.audioRecorder.audioPower)
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
                EmptyView()
            }
            ZStack {
                
                RecordButton(isRecording: $vm.audioRecorder.isRecording) {
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
            vm.cancelAudioRecording()
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
    @Environment(\.modelContext) var modelContext
    return RecordView(mc: modelContext)
}

