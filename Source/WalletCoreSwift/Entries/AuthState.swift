import Foundation

public enum WebAuthnType {
    case largeBlob, credBlob, userHandle
}

public enum AuthState {
    case none
    case password
    case webauthn(type: WebAuthnType, credentialId: String)
    
    public static let `default`: AuthState = .none
}
