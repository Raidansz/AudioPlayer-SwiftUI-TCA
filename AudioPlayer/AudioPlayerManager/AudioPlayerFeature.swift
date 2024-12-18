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
        var totalTime: Double = 0
    }

    @Dependency(\.audioPlayer) var audioPlayer

    enum Action {
        case updateNowPlayingInfo
        case configureAudioSession
        case configureRemoteCommandCenter

        case parsePlayableItem( Episode)
        case play(Episode?)
        case stop
        case seekForward
        case seekBackward
        case seekTo(time: Double)
        case updateStatus(PlaybackState)
        case pause
        case resume
        case enqueue(item: Episode)
        case dequeue
        case replaceRunningItem(with: Episode)
        case updateElapsedTime(Double)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .updateNowPlayingInfo:
                return .none
            case .configureAudioSession:
                return .none
            case .configureRemoteCommandCenter:
                return .none
            case .parsePlayableItem(let item):
                return .none
            case .play(let item):
                guard let item else { return .none }
                return .run { send in
                    let id = AudioPlayerClient.ID("hehe")

                    // Start playback and get the PlayerAction stream
                    let actions = await audioPlayer.play(id, item)

                    // Fetch the total time of the item
//                    let totalTime = await audioPlayer.totalTime(id)
//                    await MainActor.run { state.totalTime = totalTime }

                    // Observe elapsed time
                    let timeUpdates = await audioPlayer.elapsedTimeUpdates(CMTime(seconds: 1, preferredTimescale: 1))
//                    
                    Task {
                        for await currentTime in timeUpdates {
                            await send(.updateElapsedTime(currentTime))
                        }
                    }
                
                    // Handle PlayerAction events
                    for await action in actions {
                        switch action {
                        case .didStart:
                            print("Playback started")
                          
                        case .didPause:
                            print("Playback paused")
                          
                        case .didResume:
                            print("Playback resumed")
                           
                        case .didStop:
                            print("Playback stopped")
                           
                        case .errorOccurred(let error):
                            print("Playback error: \(error.localizedDescription)")
                            // Optionally handle errors
                        }
                    }
                }
            case .stop:
              //  stop(for: &state)
                return .none
            case .seekForward:
                return .run { send in
                    await audioPlayer.seekFifteenForward()
                }
              //  seekForward(for: &state)
                return .none
            case .seekBackward:
             //   seekBackward(for: &state)
                return .none
            case .seekTo(time: let time):
              //  seek(for: &state, to: time)
                return .none
            case .enqueue(item: let item):
              //  state.queue.enqueue(item)
                return .none
            case .dequeue:

                return .none
            case .replaceRunningItem(with: let withItem):

                return .none
            case .pause:
                return .run { @MainActor _ in
                    await audioPlayer.pause()
                }
            case .resume:
                return .none
            case .updateStatus(let status):

                return .none
            case .updateElapsedTime(let value):
                state.elapsedTime = value
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
    case waitingForConnection
}
