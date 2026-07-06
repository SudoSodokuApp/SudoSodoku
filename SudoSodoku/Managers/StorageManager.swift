import Foundation
import Combine

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    @Published var records: [GameRecord] = []
    @Published var userRating: Int = 1200

    private let currentFileName = "save_data_v4.json"
    private let legacyFileNames = ["save_data_v3.json", "save_data_v2.json", "save_data.json"]

    init() { loadData() }

    private func getFileURL(name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    struct StorageContainer: Codable {
        let rating: Int
        let records: [GameRecord]
    }

    func saveGame(_ record: GameRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.insert(record, at: 0)
        }
        persist()
    }

    func toggleFavorite(for id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].isFavorite.toggle()
        if records[index].isFavorite { records[index].isArchived = true }
        persist()
    }

    func setArchived(for id: UUID, isArchived: Bool) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].isArchived = isArchived
        if !isArchived { records[index].isFavorite = false }
        persist()
    }

    func batchDelete(ids: Set<UUID>) {
        records.removeAll { ids.contains($0.id) }
        persist()
    }

    func batchFavorite(ids: Set<UUID>) {
        for index in records.indices where ids.contains(records[index].id) {
            records[index].isFavorite = true
            records[index].isArchived = true
        }
        persist()
    }

    func deleteRecord(id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records.remove(at: index)
        persist()
    }

    func updateUserRating(add points: Int) {
        userRating += points
        persist()
    }

    func loadData() {
        let currentURL = getFileURL(name: currentFileName)

        if FileManager.default.fileExists(atPath: currentURL.path),
           let data = try? Data(contentsOf: currentURL),
           let decoded = try? JSONDecoder().decode(StorageContainer.self, from: data) {
            applyLoadedData(records: decoded.records, rating: decoded.rating)
            return
        }

        for legacyName in legacyFileNames {
            let legacyURL = getFileURL(name: legacyName)
            guard FileManager.default.fileExists(atPath: legacyURL.path),
                  let data = try? Data(contentsOf: legacyURL),
                  let decoded = try? JSONDecoder().decode(StorageContainer.self, from: data) else { continue }

            var migratedRecords = decoded.records
            for index in migratedRecords.indices {
                migratedRecords[index].isArchived = true
            }
            applyLoadedData(records: migratedRecords, rating: decoded.rating)
            persist()
            return
        }
    }

    private func applyLoadedData(records: [GameRecord], rating: Int) {
        DispatchQueue.main.async {
            self.records = records.sorted { $0.lastPlayedTime > $1.lastPlayedTime }
            self.userRating = rating
        }
    }

    private func persist() {
        let container = StorageContainer(rating: userRating, records: records)
        guard let data = try? JSONEncoder().encode(container) else { return }
        try? data.write(to: getFileURL(name: currentFileName), options: .atomic)
    }
}
