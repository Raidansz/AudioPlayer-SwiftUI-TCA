//
//  LiveValue.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 12. 14..
//
import AVFoundation
import ComposableArchitecture
import Dependencies

extension AudioPlayerClient: DependencyKey {
    public static var liveValue: AudioPlayerClient {
        let playerActor = AudioActor()
        return Self(
            play: { await playerActor.play(episode: $1) },
            pause: { await playerActor.pause() },
            seekFifteenBackward: { await playerActor.seekFifteenBackward() },
            seekFifteenForward: { await playerActor.seekFifteenForward() },
            seekTo: { await playerActor.seek($0) },
            elapsedTime: { await playerActor.elapsedTime(for: $0) },
            totalTime: { await playerActor.totalTime(for: $0) },
            elapsedTimeUpdates: { await playerActor.elapsedTimeUpdates(interval: $0) }
        )
    }
    private actor AudioActor {
        private var currentTask: AVPlayerTask?

        final class AVPlayerTask: NSObject, @unchecked Sendable {
            public private(set) var player: AVPlayer
            private var continuation: AsyncStream<PlayerAction>.Continuation?
            
            init(url: URL) {
                self.player = AVPlayer(playerItem: AVPlayerItem(url: url))
                super.init()
                observePlayerItem()
            }
            
            private func observePlayerItem() {
                player.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
            }
            
            override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
                if keyPath == "status", let status = player.currentItem?.status {
                    switch status {
                    case .failed:
                        if let error = player.currentItem?.error {
                            continuation?.yield(.errorOccurred(error))
                        }
                    default:
                        break
                    }
                }
            }
            
            func playbackStream() -> AsyncStream<PlayerAction> {
                AsyncStream { [weak self] continuation in
                    self?.continuation = continuation
                    
                    continuation.onTermination = { [weak self] _ in
                        self?.player.pause()
                        self?.continuation?.finish()
                    }
                }
            }
            
            func play() {
                if continuation == nil {
                    _ = playbackStream()
                }
                player.play()
                continuation?.yield(.didStart)
            }
            
            func pause() {
                player.pause()
                continuation?.yield(.didPause)
            }
            
            func stop() {
                player.pause()
                continuation?.yield(.didStop)
                continuation?.finish()
            }
            
            func elapsedTime() -> TimeInterval {
                return player.currentTime().seconds
            }
            
            func startPeriodicTimeUpdates(interval: CMTime = CMTime(seconds: 1, preferredTimescale: 1)) -> AsyncStream<TimeInterval> {
                AsyncStream { [weak self] continuation in
                    guard let self = self else { return }
                    let observer = self.player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                        continuation.yield(time.seconds)
                    }
                    
                    continuation.onTermination = { [weak self] _ in
                        self?.player.removeTimeObserver(observer)
                    }
                }
            }

            func totalTime() -> TimeInterval {
                guard let duration = player.currentItem?.duration else { return 0 }
                return CMTimeGetSeconds(duration)
            }
        }

        func play(episode: Episode) -> AsyncStream<PlayerAction> {
            guard let url = episode.streamURL else {
                return .finished
            }

            currentTask?.stop()

            let avTask = AVPlayerTask(url: url)
            currentTask = avTask

            avTask.play()
            return avTask.playbackStream()
        }

        func pause() async {
            currentTask?.pause()
        }

        func stop() async {
            currentTask?.stop()
            currentTask = nil
        }

        func elapsedTime() -> TimeInterval {
            return currentTask?.elapsedTime() ?? 0
        }

        func totalTime() -> TimeInterval {
            return currentTask?.totalTime() ?? 0
        }

        func seekFifteenForward() async {
            guard let currentTask else { return }
            let currentTime = currentTask.player.currentTime()
            let newTime = currentTime.seconds + 15
            await currentTask.player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        }

        func seekFifteenBackward() async {
            guard let currentTask else { return }
            let currentTime = currentTask.player.currentTime()
            let newTime = currentTime.seconds - 15
            await currentTask.player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        }

        func seek(_ timeInterval: TimeInterval) async {
            guard let currentTask else { return }
            await currentTask.player.seek(to: CMTime(seconds: timeInterval, preferredTimescale: 1))
        }

        func elapsedTime(for id: ID) -> TimeInterval {
            return currentTask?.elapsedTime() ?? 0
        }
        
        func totalTime(for id: ID) -> TimeInterval {
            return currentTask?.totalTime() ?? 0
        }
        
        func elapsedTimeUpdates(interval: CMTime) -> AsyncStream<TimeInterval> {
            return currentTask?.startPeriodicTimeUpdates(interval: interval) ?? .finished
        }
    }
}

extension DependencyValues {
    public var audioPlayer: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
