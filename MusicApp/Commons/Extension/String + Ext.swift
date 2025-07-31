//
//  String + Ext.swift
//  MusicApp
//
//  Created by Nhat on 6/9/23.
//

import Foundation
import CryptoKit

extension String {
    
    public static var empty: String {
        ""
    }
    
    public static var Unkown: String {
        "Unknow"
    }
    
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
