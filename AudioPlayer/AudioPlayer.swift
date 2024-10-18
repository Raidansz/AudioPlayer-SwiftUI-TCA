//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//
import AVFoundation
import UIKit
import MediaPlayer
import Combine

class AudioPlayer: AudioPlayerProtocol {

    // MARK: - Properties
    let playbackStatePublisher = CurrentValueSubject<PlaybackState, Never>(.waitingForSelection)
    let player = AVPlayer()
    var timeObserver: PlayerTimeObserver
    var durationObserver: PlayerDurationObserver
    var itemObserver: PlayerItemObserver
    var playableItem: (any PlayableItemProtocol)?
    internal var queue: Queue<any PlayableItemProtocol>

    // MARK: - Initializer
    init(playableItem: (any PlayableItemProtocol)? = nil, queue: Queue<any PlayableItemProtocol>) {
        self.playableItem = playableItem
        self.queue = queue
        self.timeObserver = PlayerTimeObserver(player: player)
        self.durationObserver = PlayerDurationObserver(player: player)
        self.itemObserver = PlayerItemObserver(player: player)
        observeAudioInterruptions()
        observePlaybackProgression()
    }

    // MARK: - Now Playing Info
    func updateNowPlayingInfo() {
        guard let playableItem else { return }
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = playableItem.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = playableItem.artist
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds

        if let imageURL = playableItem.image {
            URLSession.shared.dataTask(with: imageURL) { (data, _, error) in
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    return
                }

                guard let data = data, let artworkImage = UIImage(data: data) else {
                    print("Failed to convert data to UIImage")
                    return
                }

                let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }

                DispatchQueue.main.async {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }.resume()
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    // MARK: - Audio Session
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

    // MARK: - Playback Controls
    func play() {
        player.play()
        configureAudioSession()
        updateNowPlayingInfo()
        playbackStatePublisher.send(.playing)
    }

    func stop() {
        player.pause()
        replace(nil)
        player.seek(to: .zero)
        playbackStatePublisher.send(.stopped)
    }

    func pause() {
        player.pause()
    }

    func seekBackward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        player.seek(to: newTime)
    }

    func seekForward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        player.seek(to: newTime)
    }

    // MARK: - Queue Management
    func replace(_ withItem: (any PlayableItemProtocol)?) {
        if let withItem {
            player.replaceCurrentItem(with: makePlayableItem(withItem))
        } else {
            player.replaceCurrentItem(with: nil)
        }
    }

    func enqueue(_ item: any PlayableItemProtocol) {
        queue.enqueue(item)
    }

    func dequeue() -> (Bool, (any PlayableItemProtocol)?) {
        if queue.isEmpty {
            return (false, nil)
        } else {
            return (true, queue.dequeue())
        }
    }

    // MARK: - Playback Progression
    func observePlaybackProgression() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playNextItem),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    @objc private func playNextItem() {
        let (hasNext, nextItem) = dequeue()
        if hasNext, let nextItem = nextItem {
            replace(nextItem)
            play()
        } else {
            stop()
        }
    }

    // MARK: - Audio Interruptions
    func observeAudioInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue) else { return }

        switch interruptionType {
        case .began:
            pause()
            print("Audio interrupted. Pausing playback.")
        case .ended:
            handleInterruptionEnded(with: userInfo)
        @unknown default:
            break
        }
    }

    private func handleInterruptionEnded(with userInfo: [AnyHashable: Any]) {
        guard let interruptionOptionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
        let interruptionOptions = AVAudioSession.InterruptionOptions(rawValue: interruptionOptionsValue)
        if interruptionOptions.contains(.shouldResume), playbackStatePublisher.value == .paused {
            play()
            playbackStatePublisher.send(.playing)
        }
    }

    // MARK: - Playable Item Creation
    func makePlayableItem(_ playableItem: any PlayableItemProtocol) -> AVPlayerItem {
        AVPlayerItem(url: playableItem.streamURL)
    }

    // MARK: - PlayAction Enum
    enum PlayAction {
        case playNow
        case playLater
        case playAfter(items: Int)
        case playUntil(time: TimeInterval)
        case replacePlayableItem(with: any PlayableItemProtocol)
    }
}

// MARK: - PlaybackState Enum
enum PlaybackState: Int, Equatable {
    case waitingForSelection
    case buffering
    case playing
    case paused
    case stopped
    case waitingForConnection
}

// MARK: - AudioPlayerProtocol
protocol AudioPlayerProtocol {
    func updateNowPlayingInfo()
    func makePlayableItem(_: any PlayableItemProtocol) -> AVPlayerItem
    func play()
    func configureAudioSession()
    func pause()
    func stop()
    func seekBackward()
    func seekForward()
    func replace(_ withItem: (any PlayableItemProtocol)?)
    func enqueue(_ item: any PlayableItemProtocol)
    func dequeue() -> (Bool, (any PlayableItemProtocol)?)
    var queue: Queue<any PlayableItemProtocol> { get }
    var playableItem: (any PlayableItemProtocol)? { get }
    var playbackStatePublisher: CurrentValueSubject<PlaybackState, Never> { get }
}

// MARK: - PlayableItemProtocol
protocol PlayableItemProtocol: Identifiable, Equatable {
    var title: String { get }
    var artist: String { get }
    var image: URL? { get }
    var streamURL: URL { get }
    var id: UUID { get }
}
