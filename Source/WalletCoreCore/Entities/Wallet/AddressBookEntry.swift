//
//  AddressBookEntry.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

struct AddressBookEntry: Codable {
    let address: ResolvableAddress
    let label: String
}
