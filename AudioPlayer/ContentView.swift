//
//  ContentView.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    @Bindable var store: StoreOf<AudioPlayerFeature>
    @State private var playerStatus: PlaybackState = .waitingForSelection

    private func sliderEditingChanged(editingStarted: Bool) {
        store.send(.sliderEditingChanged(isEditingStarted: editingStarted, currentTime: store.elapsedTime))
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
            Slider(value: $store.elapsedTime.sending(\.updateElapsedTime), in: 0...100, onEditingChanged: sliderEditingChanged)
                .padding()

            HStack {
                Text(formatTime(seconds: store.elapsedTime))
                Spacer()
                Text(formatTime(seconds: store.totalTime))
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
                .disabled(playerStatus != .playing)

                Spacer()

                Button {
                    switch playerStatus {
                    case .waitingForSelection, .stopped:
                        store.send(.play(episode))
                    case .playing, .buffering:
                        store.send(.pause)
                    case .paused:
                       ()
                    }
                } label: {
                    Image(systemName: playerStatus != .playing ? "play.circle.fill" : "pause.circle.fill")
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
                .disabled(playerStatus != .playing)
            }
        }
    }

    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
