//
//  PasscodeController.swift
//  
//
//  Created by Grigory on 30.6.23..
//

import Foundation

public final class PasscodeController {
    private let passcodeVault: KeychainPasscodeVault
    
    init(passcodeVault: KeychainPasscodeVault) {
        self.passcodeVault = passcodeVault
    }
    
    public func setPasscode(_ passcode: Passcode) throws {
        try passcodeVault.save(passcode)
    }
    
    public func getPasscode() throws -> Passcode {
        return try passcodeVault.load()
    }
}
