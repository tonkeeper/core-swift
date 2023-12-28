import Foundation
import TonSwift

public struct KnownAccount: Codable {
    public let address: Address
    public let name: String
    public let requireMemo: Bool
    public let imageUrl: URL?
    
    enum CodingKeys: String, CodingKey {
        case address
        case name
        case requireMemo = "require_memo"
        case imageUrl = "image"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let addressString = try container.decode(String.self, forKey: .address)
        self.address = try Address.parse(addressString)
        self.name = try container.decode(String.self, forKey: .name)
        self.requireMemo = try container.decodeIfPresent(Bool.self, forKey: .requireMemo) ?? false
        self.imageUrl = try container.decodeIfPresent(URL.self, forKey: .imageUrl)
    }
}

struct KnownAccountsCache {
    private let cacheUrl: URL
    private let fileManager: FileManager
    private let bundle: Bundle
    
    init(cacheUrl: URL,
         fileManager: FileManager,
         bundle: Bundle) {
        self.cacheUrl = cacheUrl
        self.fileManager = fileManager
        self.bundle = bundle
    }
    
    func save(data: Data) throws {
        let path = cacheUrl.appendingPathComponent(.knownAccountsFileName)
        if fileManager.fileExists(atPath: path.path) {
            try fileManager.removeItem(at: path)
        }
        try data.write(to: path, options: .atomic)
    }
    
    func load() throws -> [KnownAccount] {
        let path = cacheUrl.appendingPathComponent(.knownAccountsFileName)
        do {
            let data = try Data(contentsOf: path)
            let accounts = try JSONDecoder().decode([KnownAccount].self, from: data)
            return accounts
        } catch {
            throw error
        }
    }
    
    func bundled() throws -> [KnownAccount] {
        guard let url = bundle.url(
            forResource: .knownAccountsFileName,
            withExtension: nil,
            subdirectory: "PackageResources"
        ) else {
            return []
        }
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            let accounts = try decoder.decode(
                [KnownAccount].self,
                from: data
            )
            return accounts
        } catch {
            throw error
        }
    }
}

public actor KnownAccounts {
    private enum State {
        case none
        case loading(Task<Void, Swift.Error>)
    }
    
    private var state: State = .none
    private var attemptNumber = 0
    
    private let session: URLSession
    private let knownAccountsCache: KnownAccountsCache
    
    init(session: URLSession,
         knownAccountsCache: KnownAccountsCache) {
        self.session = session
        self.knownAccountsCache = knownAccountsCache
    }
    
    public func loadAccounts() async throws {
        switch state {
        case .none:
            let task = Task {
                do {
                    let response = try await session.data(from: .knownAccountsUrl)
                    try? knownAccountsCache.save(data: response.0)
                } catch {
                    attemptNumber += 1
                    guard attemptNumber < .maxLoadAttempts else { return }
                    return try await loadAccounts()
                }
            }
            state = .loading(task)
            do {
                try await task.value
                state = .none
            } catch {
                state = .none
            }
        case .loading(let task):
            try await task.value
        }
    }
    
    public var knownAccounts: [KnownAccount] {
        get async {
            func cachedOrBundled() -> [KnownAccount] {
                if let cached = try? knownAccountsCache.load() {
                    return cached
                }
                if let bundled = try? knownAccountsCache.bundled() {
                    return bundled
                }
                return []
            }
            
            switch state {
            case .none:
                return cachedOrBundled()
            case .loading(let task):
                do {
                    try await task.value
                    return cachedOrBundled()
                } catch {
                    return cachedOrBundled()
                }
            }
        }
    }
}

private extension String {
    static let knownAccountsFileName = "known_accounts.json"
}

private extension URL {
    static var knownAccountsUrl: URL {
        URL(string: "https://raw.githubusercontent.com/tonkeeper/ton-assets/main/accounts.json")!
    }
}
private extension Int {
    static let maxLoadAttempts = 3
}
