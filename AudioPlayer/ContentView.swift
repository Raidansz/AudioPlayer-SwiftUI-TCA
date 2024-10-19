//
//  ContentView.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 100

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            AudioPlayer.shared.elapsedTimeObserver.pause(true)
        } else {
            AudioPlayer.shared.seek(to: currentTime, playerStatus: isPlaying)
        }
    }

    var body: some View {
        List(episodes) { episode in
            ListSongViewCell(episode: episode)
                .onTapGesture {
                    AudioPlayer.shared.play(item: episode, action: .playNow)
                    isPlaying = true
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
                        AudioPlayer.shared.totalDurationObserver.publisher,
                        AudioPlayer.shared.elapsedTimeObserver.publisher)) { totalTime, currentTime in
                            self.totalTime = totalTime
                            self.currentTime = currentTime
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
                    print(AudioPlayer.shared.playbackStatePublisher.value)
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
        }
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
