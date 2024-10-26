//
//  AudioPlayerApp.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import SwiftUI
import ComposableArchitecture


@main
struct AudioPlayerApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: AudioPlayerFeature.State()) {
                AudioPlayerFeature()
            })
        }
    }
}
