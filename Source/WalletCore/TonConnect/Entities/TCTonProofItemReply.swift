//
//  TCTonProofItemReply.swift
//  
//
//  Created by Grigory Serebryanyy on 19.10.2023.
//

import Foundation
import TonSwift
import TweetNacl

struct TCTonProofItemReply {
    struct Proof {
        let timestamp: UInt64
        let domain: Domain
        let signature: Signature
        let payload: String
        let privateKey: PrivateKey
    }
    
    struct Signature {
        let address: TonSwift.Address
        let domain: Domain
        let timestamp: UInt64
        let payload: String
    }
    
    struct Domain {
        let lengthBytes: UInt32
        let value: String
    }
    
    let name = "ton_proof"
    let proof: Proof
}

extension TCTonProofItemReply {
    init(address: TonSwift.Address,
         domain: String,
         payload: String,
         privateKey: PrivateKey) {
        let timestamp = UInt64(Date().timeIntervalSince1970)
        let domain = Domain(domain: domain)
        let signature = Signature(
            address: address,
            domain: domain,
            timestamp: timestamp,
            payload: payload)
        let proof = Proof(
            timestamp: timestamp,
            domain: domain,
            signature: signature,
            payload: payload,
            privateKey: privateKey)
        
        self.init(proof: proof)
    }
}

extension TCTonProofItemReply.Domain {
    init(domain: String) {
        let domainLength = UInt32(domain.utf8.count)
        self.value = domain
        self.lengthBytes = domainLength
    }
}

extension TCTonProofItemReply: TonConnectItemReply, Encodable {
    enum CodingKeys: String, CodingKey {
        case name
        case proof
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(proof, forKey: .proof)
    }
}

extension TCTonProofItemReply.Proof: Encodable {
    enum CodingKeys: String, CodingKey {
        case timestamp
        case domain
        case signature
        case payload
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(domain, forKey: .domain)
    
        let signatureMessageData = signature.data()
        let signatureMessage = signatureMessageData.sha256()
        guard let prefixData = Data(hex: "ffff"),
              let tonConnectData = "ton-connect".data(using: .utf8) else {
            return
        }
        let signatureData = (prefixData + tonConnectData + signatureMessage).sha256()
        let signature = try TweetNacl.NaclSign.signDetached(
            message: signatureData,
            secretKey: privateKey.data
        )
        try container.encode(signature, forKey: .signature)
        try container.encode(payload, forKey: .payload)
    }
}

extension TCTonProofItemReply.Domain: Encodable {
    enum CodingKeys: String, CodingKey {
        case lengthBytes
        case value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lengthBytes, forKey: .lengthBytes)
        try container.encode(value, forKey: .value)
    }
}

extension TCTonProofItemReply.Signature {
    func data() -> Data {
        let string = "ton-proof-item-v2/".data(using: .utf8)!
        let addressWorkchain = UInt32(bigEndian: UInt32(address.workchain))
        
        let addressWorkchainData = withUnsafeBytes(of: addressWorkchain) { a in
            Data(a)
        }
        let addressHash = address.hash
        let domainLength = withUnsafeBytes(of: UInt32(littleEndian: domain.lengthBytes)) { a in
            Data(a)
        }
        let domainValue = domain.value.data(using: .utf8)!
        let timestamp = withUnsafeBytes(of: UInt64(littleEndian: timestamp)) { a in
            Data(a)
        }
        let payload = payload.data(using: .utf8)!
        
        return string + addressWorkchainData + addressHash + domainLength + domainValue + timestamp + payload
    }
}
