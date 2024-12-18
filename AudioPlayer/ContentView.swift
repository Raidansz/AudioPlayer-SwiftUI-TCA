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
    @State private var playerStatus: PlaybackState = .waitingForSelection
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 100

    private func sliderEditingChanged(editingStarted: Bool) {
//        if editingStarted {
//            store.isPlaying.send(.buffering)
//        } else {
//            store.send(.seekTo(time: currentTime))
//        }
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
//                .onReceive(
//                    Publishers.CombineLatest(
//                        store.totalTimeObserver,
//                        store.elapsedTimeObserver)) { totalTime, currentTime in
//                            self.totalTime = totalTime
//                            self.currentTime = currentTime
//                        }
//                        .onReceive(store.isPlaying) { status in
//                            playerStatus = status
//                            print(status)
//                            print("HHHeeere is the original \(store.isPlaying.value)")
//                            print("HHHeeere is the fake \(self.playerStatus)")
//                        }

            HStack {
                Text(formatTime(seconds: store.elapsedTime))
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
                .disabled(playerStatus != .playing)

                Spacer()

                Button {
                 //   print("HHHeeere is the buttonnn \(store.isPlaying.value)")
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
