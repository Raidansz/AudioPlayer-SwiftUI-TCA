//
//  PlayerItemObserver.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import AVFoundation
import Combine

class PlayerItemObserver: Equatable {
    let publisher = PassthroughSubject<Bool, Never>()
    private var itemObservation: NSKeyValueObservation?
    
    init(player: AVPlayer) {
        itemObservation = player.observe(\.currentItem) { [weak self] player, change in
            guard let self = self else { return }
            self.publisher.send(player.currentItem != nil)
        }
    }
    deinit {
        if let observer = itemObservation {
            observer.invalidate()
        }
    }
    static func == (lhs: PlayerItemObserver, rhs: PlayerItemObserver) -> Bool {
        return lhs.itemObservation === rhs.itemObservation
    }
}
