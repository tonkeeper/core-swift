//
//  ViewModelLoadableItem.swift
//  
//
//  Created by Grigory on 3.9.23..
//

import Foundation

public enum ViewModelLoadableItem<T> {
    case loading
    case value(T)
}
