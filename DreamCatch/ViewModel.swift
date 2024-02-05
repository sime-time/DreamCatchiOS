//
//  ViewModel.swift
//  DreamCatch
//
//  Created by Simeon on 1/30/24.
//

import Foundation
import AVFoundation
import Observation
import XCAOpenAIClient

@Observable
class ViewModel: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    // properties
    let client = OpenAIClient(apiKey: "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")
    var audioRecorder: AVAudioRecorder!
    #if !os(macOS)
    var recordingSession = AVAudioSession.sharedInstance()
    #endif
    
    var animationTimer: Timer?
    var recordingTimer: Timer?
    
    var audioPower = 0.0
    var prevAudioPower: Double?
    var processingSpeechTask: Task<Void, Never>?
    
    // computed props
    var captureURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("recording.m4a")
    }
    var state = DreamRecordState.idle {
        didSet { print(state) }
    }
    var isIdle: Bool {
        if case .idle = state {
            return true
        }
        return false
    }
    var siriWaveFormOpacity: CGFloat {
        switch state {
        case .recordingSpeech, .processingSpeech:
            return 1
        default:
            return 0
        }
    }
    
    
    // override functions
    override init() {
        super.init()
        #if !os(macOS)
        do {
            #if os(iOS)
            try recordingSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            #else
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            #endif
            try recordingSession.setActive(true)
            
            AVAudioApplication.requestRecordPermission {  [unowned self] allowed in
                if !allowed {
                    self.state = .error("Recording not allowed by the user")
                }
            }
            
        } catch {
            state = .error(error)
        }
        #endif
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            resetValues()
            state = .idle
        }
    }
    

    // functions
    func startCaptureAudio() {
        resetValues()
        state = .recordingSpeech
        do {
            audioRecorder = try AVAudioRecorder(url: captureURL,
                                                settings: [
                                                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                                                    AVSampleRateKey: 12000,
                                                    AVNumberOfChannelsKey: 1,
                                                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                                                ])
            audioRecorder.isMeteringEnabled = true
            audioRecorder.delegate = self
            audioRecorder.record()
            
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [unowned self]_ in
                guard self.audioRecorder != nil else { return }
                self.audioRecorder.updateMeters()
                
                // as the recording gets louder, the minus value will get larger.
                // formula to normalize the value between 0 and 1
                let power = min(1, max(0, 1 - abs(Double(self.audioRecorder.averagePower(forChannel: 0)) / 50) ))
                self.audioPower = power
            })
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true, block: { [unowned self]_ in
                guard self.audioRecorder != nil else { return }
                self.audioRecorder.updateMeters()
                
                let power = min(1, max(0, 1 - abs(Double(self.audioRecorder.averagePower(forChannel: 0)) / 50) ))
                if self.prevAudioPower == nil {
                    self.prevAudioPower = power
                    return
                }
                if let prevAudioPower = self.prevAudioPower, prevAudioPower < 0.25 && power < 0.175 {
                    self.finishCaptureAudio()
                    return
                }
                self.prevAudioPower = power
            })
            
        } catch {
            resetValues()
            state = .error(error)
        }
    }
    
    func finishCaptureAudio() {
        resetValues()
        do {
            let data = try Data(contentsOf: captureURL)
            processingSpeechTask = processSpeechTask(audioData: data)
        } catch {
            state = .error(error)
            resetValues()
        }
    }
    
    func processSpeechTask(audioData: Data) -> Task<Void, Never> {
        Task { @MainActor [unowned self] in
            do {
                // use whisper ai to get transcription
                self.state = .processingSpeech
                let prompt = try await client.generateAudioTransciptions(audioData: audioData)
                
                // prompt gpt with transcription
                //try Task.checkCancellation()
                //let responseText = try await client.promptChatGPT(prompt: prompt)
                
                // TODO: create a dream object in swift data model
                try Task.checkCancellation()
                print(prompt) // temp
                
            } catch {
                if Task.isCancelled { return }
                state = .error(error)
                resetValues()
            }
        }
    }
    
    func cancelRecording() {
        resetValues()
        state = .idle
    }
    
    func cancelProcessingTask() {
        processingSpeechTask?.cancel()
        processingSpeechTask = nil
        resetValues()
        state = .idle
    }
    
    func resetValues() {
        audioPower = 0
        prevAudioPower = nil
        audioRecorder?.stop()
        audioRecorder = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        animationTimer?.invalidate()
        animationTimer = nil
    }
}
