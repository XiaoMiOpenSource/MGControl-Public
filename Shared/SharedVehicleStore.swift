import Foundation

struct SharedVehicleStore {
    static var groupIdentifier: String {
        let configured = Bundle.main.object(forInfoDictionaryKey:"MGControlAppGroupIdentifier") as? String
        return configured?.isEmpty == false ? configured! : "group.example.MGControl"
    }
    static var live: Self {
        Self(directory:FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:groupIdentifier))
    }
    let directory: URL?
    private struct Envelope: Codable {
        let version: Int
        let snapshot: CarSnapshot
    }
    enum StoreFailure: Error { case unavailable, invalid }
    private func file() throws -> URL {
        guard let directory else { throw StoreFailure.unavailable }
        return directory.appendingPathComponent("vehicle-summary-v1.json")
    }
    func write(_ snapshot: CarSnapshot) throws {
        guard !snapshot.demo else { throw StoreFailure.invalid }
        let bytes = try JSONEncoder().encode(Envelope(version:1,snapshot:snapshot))
        guard bytes.count <= 65536 else { throw StoreFailure.invalid }
        try bytes.write(to:file(),options:[.atomic,.completeFileProtectionUntilFirstUserAuthentication])
    }
    func read() throws -> CarSnapshot? {
        let url = try file()
        guard FileManager.default.fileExists(atPath:url.path) else { return nil }
        let handle = try FileHandle(forReadingFrom:url)
        defer { try? handle.close() }
        let bytes = try handle.read(upToCount:65537) ?? Data()
        guard bytes.count <= 65536 else { throw StoreFailure.invalid }
        let value = try JSONDecoder().decode(Envelope.self,from:bytes)
        guard value.version == 1, !value.snapshot.demo else { throw StoreFailure.invalid }
        return value.snapshot
    }
    func clear() throws {
        let url = try file()
        if FileManager.default.fileExists(atPath:url.path) { try FileManager.default.removeItem(at:url) }
    }
}
