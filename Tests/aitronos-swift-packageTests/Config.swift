//
//  Config.swift
//  Freddy
//
//  Created by Phillip Loacker on 06.01.24.
//

import Foundation

public struct Config {
    private static func getFile() -> NSDictionary {
        guard let fileUrl = Bundle.module.url(forResource: "Config", withExtension: "plist") else {
            fatalError("Couldn't find file 'Config.plist' in the package bundle.")
        }
        
        guard let plist = NSDictionary(contentsOf: fileUrl) else {
            fatalError("Couldn't load contents of 'Config.plist'.")
        }
        
        return plist
    }
    
    public static var testKey: String {
        get {
            let plist = getFile()
            
            guard let value = plist.object(forKey: "Test_Key") as? String else {
                fatalError("Couldn't find key 'Test_Key' in 'Config.plist'.")
            }

            return value
        }
    }
    public static var testEmail: String {
        get {
            let plist = getFile()
            
            guard let value = plist.object(forKey: "Test_Email") as? String else {
                fatalError("Couldn't find key 'Test_Email' in 'Config.plist'.")
            }
            
            return value
        }
    }
    public static var testPassword: String {
        get {
            let plist = getFile()
            
            guard let value = plist.object(forKey: "Test_Password") as? String else {
                fatalError("Couldn't find key 'Test_Password' in 'Config.plist'.")
            }
            
            return value
        }
    }
}
