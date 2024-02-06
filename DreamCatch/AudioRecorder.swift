//
//  AudioRecorder.swift
//  DreamCatch
//
//  Created by Simeon on 2/5/24.
//
//  Purposes:
//  1. Start and stop recording using AVAudioRecorder
//  2. Keep track of the UI states related to audio recording
//  3. Collect and store audio level data which will be used to display the audio waveform

import Foundation
import AVFoundation

@Observable
class AudioRecorder: NSObject {
    var isRecording: Bool = false
    var hasMicAccess: Bool = false
    var showMicAccessAlert: Bool = false
    var audioPowerData: [Float] = []
    var audioPower: Double = 0.0
    
    var audioRecorder: AVAudioRecorder?
    var timer: Timer?
    
    private func requestMicrophoneAccess() {
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                self.hasMicAccess = true
            } else {
                self.showMicAccessAlert = true
            }
        }
    }
    
    private func normalizeAudioPower(power: Float) -> Float {
        // normalize the audio power value between 0.0 and 1.0
        let minDb: Float = -80.0
        if power < minDb { return 0.0 }
        if power > 1.0 { return 1.0 }
        return Float((abs(minDb) - abs(power)) / abs(minDb))
    }
    
    private func updateWaveform() {
        guard let recorder = self.audioRecorder else { return }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedPower = normalizeAudioPower(power: averagePower)
        self.audioPower = Double(normalizedPower) 
        self.audioPowerData.append(normalizedPower)
        
        // since we only have 6 paths in waveform view
        // we only need to save the latest 6 items in the array
        if self.audioPowerData.count > 6 {
            self.audioPowerData.removeFirst()
        }
    }
    
    func setup() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // sample audio levels and request microphone access
            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM), // kAudioFormatMPEG4AAC
                AVSampleRateKey: 44100.0, // 12000
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            self.audioRecorder = try AVAudioRecorder(url: FileSystemManager.getRecordingTempURL(), settings: audioSettings)
            self.audioRecorder?.isMeteringEnabled = true
            self.audioRecorder?.delegate = self
            self.requestMicrophoneAccess()
            print("audio recorder has been set up")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func record() {
        if hasMicAccess {
            self.audioPowerData.removeAll()
            self.audioRecorder?.record()
            self.isRecording = true 
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.updateWaveform()
            }
            print("audio recording...")
        } else {
            self.requestMicrophoneAccess()
        }
    }
    
    func stopRecording(completion: (String?) -> Void) {
        self.audioRecorder?.stop()
        
        let fileName = FileSystemManager.saveRecordingFile()
        completion(fileName)
        
        self.isRecording = false
    }
    
    func cancelRecording() {
        self.audioRecorder?.stop()
        self.isRecording = false
    }
    
    
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.isRecording = false
        if let timer = timer, timer.isValid {
            timer.invalidate()
        }
        
        self.audioPowerData.removeAll()
    }
}
