import SwiftUI

struct PersonalBestRow: View {
    let difficulty: Difficulty
    let record: GameRecord?

    var body: some View {
        HStack {
            VStack(spacing: 2) {
                Text(difficulty.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(difficulty.color)
                Text("LEVEL")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .frame(width: 60)

            Divider().background(Color.gray.opacity(0.3))

            if let record {
                // No undo/efficiency judgment here: undos are a free tool,
                // not a quality metric (#62). The honest per-record details
                // are when the best was set and what it earned.
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("SET: \(DateFormatting.archiveDate.string(from: record.lastPlayedTime))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    if let gain = record.ratingChange, gain > 0 {
                        HStack {
                            Image(systemName: "bolt")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("+\(gain) RP")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer()

                // A personal best is the fastest solve; time is the headline.
                VStack(spacing: 2) {
                    Text(record.playDuration > 0 ? DateFormatting.playClock(record.playDuration) : "--")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Text("BEST_TIME")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NO_RECORD")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("START_PLAYING_TO_SET_RECORD")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.7))
                }

                Spacer()

                Text("--")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
        .cornerRadius(8)
    }
}
