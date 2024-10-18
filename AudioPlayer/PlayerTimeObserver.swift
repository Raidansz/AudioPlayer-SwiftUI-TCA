//
//  PlayerTimeObserver.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import AVFoundation
import Combine

class PlayerElapsedTimeObserver: Equatable {
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
            guard let self = self else { return }
            guard !self.paused else { return }
            self.publisher.send(time.seconds)
        }
    }
    deinit {
        if let player = player,
           let observer = timeObservation {
            player.removeTimeObserver(observer)
        }
    }

    func pause(_ pause: Bool) {
        paused = pause
    }

    static func == (lhs: PlayerElapsedTimeObserver, rhs: PlayerElapsedTimeObserver) -> Bool {
        return lhs.player === rhs.player
    }
}
