import Foundation

enum Network: Int {
    case mainnet = -239
    case testnet = -3
    
    public static var `default`: Network = .mainnet
    
    public static func switchNetwork(current: Network) -> Network {
        return current == .mainnet ? .testnet : .mainnet
    }
    
    public static func getTonClient(config: TonEndpointConfig, current: Network?) {
        
    }
}

struct TonEndpointConfig {
    
}
