//
//  PasscodeController.swift
//
//
//  Created by Grigory Serebryanyy on 20.11.2023.
//

import Foundation

public final class PasscodeController {
    private let passcodeVault: PasscodeVault
    
    init(passcodeVault: PasscodeVault) {
        self.passcodeVault = passcodeVault
    }
    
    public func setPasscode(_ passcode: Passcode) throws {
        try passcodeVault.save(passcode)
    }
    
    public func getPasscode() throws -> Passcode {
        return try passcodeVault.load()
    }
}
