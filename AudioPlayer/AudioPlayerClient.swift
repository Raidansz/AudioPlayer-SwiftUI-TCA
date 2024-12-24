//
//  AudioPlayerClient.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 12. 14..
//

import DependenciesMacros
import AVFoundation
import ComposableArchitecture

@DependencyClient
public struct AudioPlayerClient : Sendable{
    public struct ID: Hashable, @unchecked Sendable {
        public let rawValue: AnyHashable

        public init<RawValue: Hashable & Sendable>(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }

        public init() {
            struct RawValue: Hashable, Sendable {}
            self.rawValue = RawValue()
        }
    }

    public enum PlayerAction : Sendable{
        case didStart
        case didPause
        case didResume
        case didStop
        case errorOccurred(Error)
    }

    public var play: @Sendable (_ id: ID, Episode) async -> AsyncStream<PlayerAction> = { _, _ in .finished }
    public var pause: @Sendable () async -> Void
    public var seekFifteenBackward: @Sendable () async -> Void
    public var seekFifteenForward: @Sendable () async -> Void
    public var seekTo: @Sendable (TimeInterval) async -> Void
    public var elapsedTime: @Sendable (_ id: ID) async -> TimeInterval = { _ in 0 }
    public var totalTime: @Sendable () async -> TimeInterval = { 0 }
    public var elapsedTimeUpdates: @Sendable (CMTime) async -> AsyncStream<TimeInterval> = { _ in .finished }
}
