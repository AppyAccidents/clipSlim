import Foundation

struct IgnoreCacheEntry: Codable, Hashable {
    let hash: String
    let expiresAt: Date
}

@Observable
final class IgnoreCache {
    private let cacheKey = "ignoreCacheEntries"
    private(set) var entries: [String: Date] = [:]

    init() {
        load()
    }

    func contains(_ hash: String, now: Date = Date()) -> Bool {
        cleanupExpired(now: now)
        guard let expiry = entries[hash] else { return false }
        return expiry > now
    }

    func add(_ hash: String, ttl: TimeInterval = 24 * 3600, now: Date = Date()) {
        entries[hash] = now.addingTimeInterval(ttl)
        persist()
    }

    func cleanupExpired(now: Date = Date()) {
        let before = entries.count
        entries = entries.filter { $0.value > now }
        if entries.count != before {
            persist()
        }
    }

    private func persist() {
        let payload = entries.map { IgnoreCacheEntry(hash: $0.key, expiresAt: $0.value) }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([IgnoreCacheEntry].self, from: data) else {
            entries = [:]
            return
        }

        var rebuilt: [String: Date] = [:]
        for entry in decoded {
            rebuilt[entry.hash] = entry.expiresAt
        }
        entries = rebuilt
        cleanupExpired()
    }
}
