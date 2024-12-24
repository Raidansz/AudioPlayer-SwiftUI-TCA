//
//  AudioPlayerFeature.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 26..
//

import ComposableArchitecture
import AVFoundation
import MediaPlayer
@preconcurrency import Combine

@Reducer
struct AudioPlayerFeature: Sendable {
    @ObservableState
    struct State: Sendable {
        var queue: Queue<Episode> = .init()
        var playableItem: Episode?
        var elapsedTime: Double = 0
        var totalTime: Double = 100
    }
    
    @Dependency(\.audioPlayer) var audioPlayer
    
    enum Action {
        case parsePlayableItem( Episode)
        case play(Episode?)
        case stop
        case seekForward
        case seekBackward
        case seekTo(time: Double)
        case updateStatus(PlaybackState)
        case pause
        case sliderEditingChanged(isEditingStarted: Bool, currentTime: Double)
        case replaceRunningItem(with: Episode)
        case updateElapsedTime(Double)
        case updateTotalTime(Double)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .parsePlayableItem(let item):
                return .none
            case .play(let item):
                guard let item else { return .none }
                return .run { send in
                    
                    let actions = await audioPlayer.play(AudioPlayerClient.ID("player"), item)
                    for await action in actions {
                        switch action {
                        
                        case .didStart:
                            print("")
                        case .didPause:
                            print("")
                        case .didResume:
                            print("")
                        case .didStop:
                            print("")
                        case .errorOccurred(_):
                            print("")
                        }
                    }
                }
            case .stop:
                //  stop(for: &state)
                return .none
            case .seekForward:
                //  seekForward(for: &state)
                return .none
            case .seekBackward:
                //   seekBackward(for: &state)
                return .none
            case .seekTo(time: let time):
                //  seek(for: &state, to: time)
                return .none
            case .replaceRunningItem(with: let withItem):
                
                return .none
            case .pause:
                return .run { @MainActor _ in
                    await audioPlayer.pause()
                }
            case .updateStatus(let status):
                
                return .none
            case .updateElapsedTime(let value):
                state.elapsedTime = value
                return .none
            case .sliderEditingChanged(let editingStarted, let currentTime):
                if editingStarted {
                    //                    state.playbackState = .buffering
                    return .none
                } else {
                    return .run { @MainActor send in
                        await audioPlayer.seekTo(currentTime)
                    }
                }
            case .updateTotalTime(let value):
                print(value)
                state.totalTime = value
                return .none
            }
        }
    }
}

protocol PlayableItemProtocol: Identifiable, Equatable, Sendable {
    var title: String { get }
    var author: String { get }
    var imageUrl: URL? { get }
    var streamURL: URL? { get }
    var id: String { get }
}

enum PlaybackState: Int, Equatable {
    case waitingForSelection
    case buffering
    case playing
    case paused
    case stopped
}
