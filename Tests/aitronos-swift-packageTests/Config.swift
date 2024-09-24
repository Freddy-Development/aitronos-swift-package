//
//  Config.swift
//  Freddy
//
//  Created by Phillip Loacker on 06.01.24.
//

import Foundation

public struct Config {
    public static var testKey: String {
        get {
            // Use Bundle.module to locate the Config.plist file in the package's resource bundle
            guard let fileUrl = Bundle.module.url(forResource: "Config", withExtension: "plist") else {
                fatalError("Couldn't find file 'Config.plist' in the package bundle.")
            }

            // Load the contents of the plist
            guard let plist = NSDictionary(contentsOf: fileUrl) else {
                fatalError("Couldn't load contents of 'Config.plist'.")
            }

            // Access the correct key
            guard let value = plist.object(forKey: "Test_Key") as? String else {
                fatalError("Couldn't find key 'Test_Key' in 'Config.plist'.")
            }

            return value
        }
    }
}
