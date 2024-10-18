//
//  PlayerDurationObserver.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import AVFoundation
import Combine

class PlayerTotalDurationObserver: Equatable {
    let publisher = PassthroughSubject<TimeInterval, Never>()
    private var cancellable: AnyCancellable?
    init(player: AVPlayer) {
        let durationKeyPath: KeyPath<AVPlayer, CMTime?> = \.currentItem?.duration
        cancellable = player.publisher(for: durationKeyPath).sink { duration in
            guard let duration = duration else { return }
            guard duration.isNumeric else { return }
            self.publisher.send(duration.seconds)
        }
    }
    deinit {
        cancellable?.cancel()
    }
    static func == (lhs: PlayerTotalDurationObserver, rhs: PlayerTotalDurationObserver) -> Bool {
        return lhs.cancellable === rhs.cancellable
    }
}
