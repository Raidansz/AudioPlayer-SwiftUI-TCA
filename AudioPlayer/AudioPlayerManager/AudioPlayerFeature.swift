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
        var player: AVPlayer?
        var queue: Queue<any PlayableItemProtocol> = .init()
        var playableItem: (any PlayableItemProtocol)?
        @ObservationStateIgnored var isPlaying = CurrentValueSubject<PlaybackState, Never>(.waitingForSelection)
        @ObservationStateIgnored var elapsedTimeObserver = PassthroughSubject<Double, Never>()
        var elapsedTimeObservation: Any?
        @ObservationStateIgnored var totalTimeObserver = PassthroughSubject<TimeInterval, Never>()
        private var timeObservation: Any?
        private var cancellable: AnyCancellable?

        init() {
            /// initilazing player
            self.player = AVPlayer()
            guard let player else { return }

            /// Subscribing to elapsedTimeObservation
            elapsedTimeObservation = player.addPeriodicTimeObserver(
                forInterval: CMTime(
                    seconds: 0.5,
                    preferredTimescale: 600
                ),
                queue: nil
            ) { [self] time in
                if isPlaying.value == .playing {
                    self.elapsedTimeObserver.send(time.seconds)
                }
            }

            /// Subscribing to elapsedTimeObservation
            let durationKeyPath: KeyPath<AVPlayer, CMTime?> = \.currentItem?.duration
            cancellable = player.publisher(for: durationKeyPath).sink { [self] duration in
                guard let duration = duration else { return }
                guard duration.isNumeric else { return }
                self.totalTimeObserver.send(duration.seconds)
            }
        }
    }

    enum Action {
        case updateNowPlayingInfo
        case configureAudioSession
        case configureRemoteCommandCenter

        case parsePlayableItem((any PlayableItemProtocol)?)
        case play((any PlayableItemProtocol)?)
        case stop
        case seekForward
        case seekBackward
        case seekTo(time: Double)
        case updateStatus(PlaybackState)
        case pause
        case resume
        case enqueue(item: any PlayableItemProtocol)
        case dequeue
        case replaceRunningItem(with: (any PlayableItemProtocol)?)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .updateNowPlayingInfo:
                updateNowPlayingInfo(for: &state)
                return .none
            case .configureAudioSession:
                configureAudioSession()
                return .none
            case .configureRemoteCommandCenter:
                configureRemoteCommandCenter(for: &state)
                return .none
            case .parsePlayableItem(let item):
                guard let item else { return .none }
                parsePlayableItem(for: &state, item: item)
                return .none
            case .play(let item):
                guard let item else { return .none }
                play(for: &state, item: item)
                return .none
            case .stop:
                stop(for: &state)
                return .none
            case .seekForward:
                seekForward(for: &state)
                return .none
            case .seekBackward:
                seekBackward(for: &state)
                return .none
            case .seekTo(time: let time):
                seek(for: &state, to: time)
                return .none
            case .enqueue(item: let item):
                state.queue.enqueue(item)
                return .none
            case .dequeue:
                if state.queue.isEmpty {
                    return .none
                } else {
                    state.playableItem = state.queue.dequeue()
                    return .none
                }
            case .replaceRunningItem(with: let withItem):
                guard let withItem else { return .none }
                stop(for: &state)
                parsePlayableItem(for: &state, item: withItem)
                return .none
            case .pause:
                state.player?.pause()
                state.isPlaying.send(.paused)
                return .none
            case .resume:
                state.player?.play()
                state.isPlaying.send(.playing)
                return .none
            case .updateStatus(let status):
                state.isPlaying.send(status)
                return .none
            }
        }
    }
}

extension AudioPlayerFeature {
    func updateNowPlayingInfo(for state: inout State) {
        guard let playableItem = state.playableItem, let player = state.player else { return }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = playableItem.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = playableItem.author
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.duration.seconds

        if let imageURL = playableItem.imageUrl {
            Task {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                guard let artworkImage = UIImage(data: data) else {
                    print("Failed to convert data to UIImage")
                    return
                }
                let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Audio session configured successfully for background playback.")
        } catch {
            print("Failed to configure the audio session: \(error.localizedDescription)")
            handleAudioSessionError(error)
        }
    }

    func handleAudioSessionError(_ error: Error) {
        print("Handling audio session error: \(error)")
    }

    func configureRemoteCommandCenter(for state: inout State) {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [state] _ in
            state.player?.play() // TODO: To be optimized
            return .success
        }

        commandCenter.pauseCommand.addTarget { _ in
           // pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { _ in
           /* seekForward(for: &state)*/ // TODO: To be replaced with next track
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { _ in
           /* seekBackward(for: &state)*/ // TODO: To be replaced with previous track
            return .success
        }
    }

    func parsePlayableItem(for state: inout State, item: any PlayableItemProtocol) {
        guard let player = state.player, let url = item.streamURL else { return }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }

    func play(for state: inout State, item: any PlayableItemProtocol) {
        parsePlayableItem(for: &state, item: item)
        state.player?.play()
        state.isPlaying.send(.playing)
    }

    func stop(for state: inout State) {
        state.player?.pause()
        state.player?.replaceCurrentItem(with: nil)
        state.playableItem = nil
        state.player?.seek(to: .zero)
        state.isPlaying.send(.stopped)
    }

    func seekForward(for state: inout State) {
        let currentTime = state.player?.currentTime()
        guard let currentTime else { return }
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        state.player?.seek(to: newTime)
    }

    func seekBackward(for state: inout State) {
        let currentTime = state.player?.currentTime()
        guard let currentTime else { return }
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        state.player?.seek(to: newTime)
    }

    func seek(for state: inout State, to time: Double) {
        let targetTime = CMTime(seconds: time, preferredTimescale: 600)
        if state.isPlaying.value == .paused {
            state.player?.seek(to: targetTime)
        } else {
            state.isPlaying.send(.buffering)
            state.player?.seek(to: targetTime)
            state.isPlaying.send(.playing)
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
