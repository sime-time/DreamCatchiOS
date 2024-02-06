//
//  FileSystemManager.swift
//  DreamCatch
//
//  Created by Simeon on 2/5/24.
//
//  Purpose:
//  1. Creates the directory to save the recordings audio files if it doesnt exist yet
//  2. Moves the audio file from the temp location to the permanent location

import Foundation
import AudioKit

class FileSystemManager {
    enum FSError: Error {
        case failedToGetDocumentDir
        case failedToGetRecordingsDir
        case failedToCreateRecordingsDir
        case failedToSaveRecording
    }
    
    static var documentDirectory: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    static func getRecordingTempURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filepath = "tempRecording.caf"
        return tempDir.appendingPathComponent(filepath)
    }
    
    static func getRecordingsDirectoryURL() -> URL? {
        guard let dir = documentDirectory else { return nil }
        print("\(dir)")
        return dir.appending(path: "recordings")
    }
    
    static func makeRecordingsDirectory() throws {
        guard let dir = documentDirectory else { throw FSError.failedToGetDocumentDir }
        
        do {
            try FileManager.default.createDirectory(at: dir.appending(path: "recordings"),
                                                    withIntermediateDirectories: true)
        } catch {
            throw FSError.failedToCreateRecordingsDir
        }
    }
    
    static func isRecordingDirectoryPresent() -> Bool {
        guard let recordingsDirectoryURL = self.getRecordingsDirectoryURL() else { return false }
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: recordingsDirectoryURL.relativePath, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }
    
    static func saveRecordingFile() -> String? {
        let recordingTempURL = getRecordingTempURL()
        let fileName = UUID().uuidString + "." + recordingTempURL.pathExtension
        
        if (!self.isRecordingDirectoryPresent()) {
            do {
                try self.makeRecordingsDirectory()
            } catch {
                return nil
            }
        }
        
        guard let recordingsDir = self.getRecordingsDirectoryURL() else { return nil }
        let target = recordingsDir.appending(path: fileName)
        
        do {
            try FileManager.default.moveItem(at: recordingTempURL, to: target)
        } catch {
            return nil
        }
        
        return fileName
    }
    
    static func getRecordingURL(_ fileName: String) -> URL? {
        guard let dir = getRecordingsDirectoryURL() else { return nil }
        return dir.appendingPathComponent(fileName)
    }
    
    static func getModelURL() -> URL? {
        if let filePath = Bundle.main.path(forResource: "ggml-tiny", ofType: "bin") {
            let fileURL = URL(string: filePath)
            return fileURL
        } else {
            return nil
        }
    }
    
    static func convertAudioFileToPCMArray(fileURL: URL, completionHandler: @escaping (Result<[Float], Error>) -> Void) {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)
        converter.start { error in
            if let error {
                completionHandler(.failure(error))
                return
            }

            let data = try! Data(contentsOf: tempURL) // Handle error here

            let floats = stride(from: 44, to: data.count, by: 2).map {
                return data[$0..<$0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }

            try? FileManager.default.removeItem(at: tempURL)

            completionHandler(.success(floats))
        }
    }
}
