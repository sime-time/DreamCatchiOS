//
//  ViewModel.swift
//  DreamCatch
//
//  Created by Simeon on 1/30/24.
//

import Foundation
import Observation
import SwiftWhisper
import SwiftData

@Observable
class ViewModel: NSObject {

    var modelContext: ModelContext
    
    init(mc: ModelContext) {
        self.modelContext = mc
        super.init()
    }


    // properties
    var audioRecorder = AudioRecorder()
    var processingSpeechTask: Task<Void, Never>?
    var audioURL: URL?
    
    // computed props
    var modelURL: URL? {
        return FileSystemManager.getModelURL()
    }
    var state: AudioRecordState = .idle {
        didSet { print(state) }
    }
    var isIdle: Bool {
        if case .idle = state {
            return true
        } else {
            return false
        }
    }
    var siriWaveFormOpacity: CGFloat {
        switch state {
        case .recordingSpeech, .processingSpeech:
            return 1
        default:
            return 0
        }
    }
    
    // functions
    func startCaptureAudio() {
        self.audioRecorder.setup()
        self.audioRecorder.record()
    }

    func finishCaptureAudio() {
        self.audioRecorder.stopRecording(completion: captureAudioURL)
        if let url = self.audioURL {
            FileSystemManager.convertAudioFileToPCMArray(fileURL: url) { result in
                switch result {
                case .success(let pcmArray):
                    print("Successfully converted audio to PCM: \(pcmArray)")
                    self.processingSpeechTask = self.processSpeechTask(audioData: pcmArray)
                case .failure(let error):
                    self.state = .error(error)
                }
            }
        }
        self.state = .idle
    }
    
    func captureAudioURL(_ fileName: String?) -> Void {
        if let fileName {
            self.audioURL = FileSystemManager.getRecordingURL(fileName)
            print(audioURL!)
        }
    }
    
    func processSpeechTask(audioData: [Float]) -> Task<Void, Never> {
        Task { @MainActor [unowned self] in
            do {
                self.state = .processingSpeech
                try Task.checkCancellation()
                
                // transcribe with whisper
                if let modelURL {
                    let whisper = Whisper(fromFileURL: modelURL)
                    try Task.checkCancellation()
                    
                    let segments = try await whisper.transcribe(audioFrames: audioData)
                    let transcript = segments.map(\.text).joined()
                    print(transcript) // temp
                    
                    // create a dream object in swift data model
                    let dream = Dream(content: transcript)
                    modelContext.insert(dream)
                    try modelContext.save()
                }
                
            } catch {
                if Task.isCancelled { return }
                self.state = .error(error)
            }
            self.cancelProcessingTask()
        }
    }
    
    func cancelAudioRecording() {
        self.audioRecorder.cancelRecording()
        self.state = .idle 
    }
    
    func cancelProcessingTask() {
        processingSpeechTask?.cancel()
        processingSpeechTask = nil
        self.state = .idle
    }
    
}
