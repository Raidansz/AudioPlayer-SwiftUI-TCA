//
//  ContentView.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import SwiftUI

struct ContentView: View {
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 100

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            AudioPlayer.shared.elapsedTimeObserver.pause(true)
        } else {
            AudioPlayer.shared.seek(to: currentTime)
        }
    }

    var body: some View {
        VStack {
            List(episodes) { episode in
                ListSongViewCell(episode: episode)
                    .onTapGesture {
                        AudioPlayer.shared.play(item: episode, action: .playNow)
                        isPlaying = true
                    }
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)

            Slider(value: $currentTime, in: 0...totalTime, onEditingChanged: sliderEditingChanged)
                .padding()
                .onReceive(AudioPlayer.shared.totalDurationObserver.publisher) { totalTime in
                    self.totalTime = totalTime
                }
                .onReceive(AudioPlayer.shared.elapsedTimeObserver.publisher) { currentTime in
                    self.currentTime = currentTime
                }
                .onReceive(AudioPlayer.shared.itemObserver.publisher) { hasAnItem in
                    if hasAnItem {
                        AudioPlayer.shared.playbackStatePublisher.send(.buffering)
                    } else {
                        AudioPlayer.shared.playbackStatePublisher.send(.waitingForSelection)
                        self.currentTime = 0
                        self.totalTime = 0
                    }
                }

            HStack {
                Text(formatTime(seconds: currentTime))
                Spacer()
                Text(formatTime(seconds: totalTime))
            }
            .padding(.horizontal)

            HStack {
                Button {
                    AudioPlayer.shared.seekBackward()
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 30))
                        .padding()
                }
                .disabled(!isPlaying)

                Spacer()

                Button {
                    switch AudioPlayer.shared.playbackStatePublisher.value {
                    case .waitingForSelection:
                        isPlaying = true
                        AudioPlayer.shared.play(item: episode, action: .playNow)
                    case .playing:
                        isPlaying = false
                        AudioPlayer.shared.pause()
                    case .paused:
                        AudioPlayer.shared.resume()
                        isPlaying = true
                    default:
                        break
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .padding()
                }
                Spacer()

                Button {
                    AudioPlayer.shared.seekForward()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 30))
                        .padding()
                }
                .disabled(!isPlaying)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
