//
//  ContentView.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import SwiftUI
import Combine
import ComposableArchitecture

struct ContentView: View {
    @Bindable var store: StoreOf<AudioPlayerFeature>
    @State private var playerStatus: PlaybackState = .paused
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 100

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            store.isPlaying.send(.paused)
        } else {
            store.send(.seekTo(time: currentTime))
        }
    }

    var body: some View {
        List(episodes) { episode in
            ListSongViewCell(episode: episode)
                .onTapGesture {
                    store.send(.play(episode))
                    playerStatus = .playing
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)

        VStack {
            Slider(value: $currentTime, in: 0...totalTime, onEditingChanged: sliderEditingChanged)
                .padding()
                .onReceive(
                    Publishers.CombineLatest(
                        store.totalTimeObserver,
                        store.elapsedTimeObserver)) { totalTime, currentTime in
                            self.totalTime = totalTime
                            self.currentTime = currentTime
                        }
                        .onReceive(store.isPlaying) { status in
                            playerStatus = status
                        }

            HStack {
                Text(formatTime(seconds: currentTime))
                Spacer()
                Text(formatTime(seconds: totalTime))
            }
            .padding(.horizontal)

            HStack {
                Button {
                    store.send(.seekBackward)
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 30))
                        .padding()
                }
                .disabled(playerStatus == .paused)

                Spacer()

                Button {
                    switch playerStatus {
                    case .waitingForSelection:
                        store.send(.play(episode))
                    case .playing:
                        store.send(.pause)
                    case .paused:
                        store.send(.resume)
                    default:
                        break
                    }
                } label: {
                    Image(systemName: playerStatus == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .padding()
                }
                Spacer()

                Button {
                    store.send(.seekForward)
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 30))
                        .padding()
                }
                .disabled(playerStatus == .paused)
            }
        }
    }

    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
