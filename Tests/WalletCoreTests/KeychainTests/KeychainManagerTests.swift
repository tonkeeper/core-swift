//
//  KeychainManagerTests.swift
//  
//
//  Created by Grigory on 22.6.23..
//

import XCTest
@testable import WalletCore

final class KeychainManagerTests: XCTestCase {
    
    let mockKeychain = MockKeychain()
    lazy var keychainManager = KeychainManager(keychain: mockKeychain)
    
    override func setUp() {
        mockKeychain.reset()
    }
    
    func testGet() throws {
        // GIVEN
        let data = "TestData".data(using: .utf8)!
        mockKeychain.data = data
        mockKeychain.getResult = .success(data)
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        let keychainData = try keychainManager.get(query: query)
        
        // THEN
        XCTAssertEqual(keychainData, data)
    }
    
    func testGetThrowErrorIfNotFound() throws {
        // GIVEN
        mockKeychain.getResult = .failed(.errSecItemNotFound)
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        XCTAssertThrowsError(try keychainManager.get(query: query), "") { error in
            XCTAssertEqual(error as! KeychainManager.Error, KeychainManager.Error.noItemFound)
        }
    }
    
    func testGetThrowErrorIfNilData() throws {
        // GIVEN
        mockKeychain.getResult = .success(nil)
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        XCTAssertThrowsError(try keychainManager.get(query: query), "") { error in
            XCTAssertEqual(error as! KeychainManager.Error, KeychainManager.Error.invalidData)
        }
    }
    
    func testGetThrowErrorCustomError() throws {
        // GIVEN
        mockKeychain.getResult = .failed(.errSecParam)
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        XCTAssertThrowsError(try keychainManager.get(query: query), "") { error in
            XCTAssertEqual(error as! KeychainManager.Error, KeychainManager.Error.error(.errSecParam))
        }
    }
    
    func testSaveItemExistsUpdateCalled() throws {
        // GIVEN
        let resultCode = KeychainResultCode.success
        let data = "TestData".data(using: .utf8)!
        mockKeychain.resultCode = resultCode
        mockKeychain.getResult = .success(data)
        mockKeychain.data = data
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        try keychainManager.save(data: data, query: query)
        
        // THEN
        XCTAssertEqual(mockKeychain.updateAttributes[KeychainKeys.valueData] as! Data, data)
    }
    
    func testSaveItemNotExist() throws {
        // GIVEN
        let resultCode = KeychainResultCode.success
        let data = "TestData".data(using: .utf8)!
        mockKeychain.resultCode = resultCode
        mockKeychain.getResult = .failed(.errSecItemNotFound)
        mockKeychain.data = data
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        try keychainManager.save(data: data, query: query)
        
        // THEN
        XCTAssertTrue(mockKeychain.updateAttributes.isEmpty)
    }
    
    func testDeleteSucessIfNotSaved() throws {
        let resultCode = KeychainResultCode.errSecItemNotFound
        mockKeychain.resultCode = resultCode
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        // THEN
        XCTAssertNoThrow(try keychainManager.delete(query: query))
    }
    
    func testDeleteSuccessIfSaved() throws {
        let resultCode = KeychainResultCode.success
        mockKeychain.resultCode = resultCode
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        // THEN
        XCTAssertNoThrow(try keychainManager.delete(query: query))
    }
    
    func testDeleteFailed() throws {
        let resultCode = KeychainResultCode.errSecParam
        mockKeychain.resultCode = resultCode
        
        let query = KeychainQuery(class: .genericPassword(service: "service", account: "account"), accessible: .whenUnlocked)
        
        // WHEN
        // THEN
        XCTAssertThrowsError(try keychainManager.delete(query: query), "") { error in
            XCTAssertEqual(error as! KeychainManager.Error, KeychainManager.Error.error(.errSecParam))
        }
    }
}


