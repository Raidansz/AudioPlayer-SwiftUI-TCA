//
//  PlayerTimeObserver.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import AVFoundation
import Combine
@MainActor
class PlayerElapsedTimeObserver {
    let publisher = PassthroughSubject<TimeInterval, Never>()
    private weak var player: AVPlayer?
    private var timeObservation: Any?
    private var paused = false

    init(player: AVPlayer) {
        self.player = player
        timeObservation = player.addPeriodicTimeObserver(
            forInterval: CMTime(
                seconds: 0.5,
                preferredTimescale: 600
            ),
            queue: nil
        ) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                guard !self.paused else { return }
                self.publisher.send(time.seconds)
            }
        }
    }
    deinit {
        // Since the only class that uses the PlayerElapsedTimeObserver is AudioPlayer, that only runs in the main thread, and it is final. So the deinit will always be called in the main thread
        MainActor.assumeIsolated {
            unsubscribe()
        }
    }

    private func unsubscribe() {
        if let player = player,
           let observer = timeObservation {
            player.removeTimeObserver(observer)
        }
    }

    func pause(_ pause: Bool) {
        paused = pause
    }
}
