//
//  AudioRecordState.swift
//  DreamCatch
//
//  Created by Simeon on 1/30/24.
//

import Foundation

enum AudioRecordState {
    case idle
    case recordingSpeech
    case processingSpeech
    case error(Error)
}
