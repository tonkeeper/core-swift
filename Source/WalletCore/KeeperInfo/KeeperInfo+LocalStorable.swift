//
//  KeeperInfo+LocalStorable.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

extension KeeperInfo: LocalStorable {
    static var fileName: String {
        String(describing: self)
    }
}
