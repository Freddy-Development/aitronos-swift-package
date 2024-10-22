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
        
        print("Successfully found Config.plist at URL: \(fileUrl)")
        
        guard let plist = NSDictionary(contentsOf: fileUrl) else {
            fatalError("Couldn't load contents of 'Config.plist'. Please check the file structure.")
        }
        
        print("Successfully loaded Config.plist contents.")
        
        return plist
    }
    
    public static var testKey: String {
        get {
            let plist = getFile()
            
            guard let value = plist.object(forKey: "Test_Key") as? String else {
                fatalError("Couldn't find key 'Test_Key' in 'Config.plist'. Please check the spelling of the key.")
            }

            return value
        }
    }
    public static var testEmail: String {
        get {
            let plist = getFile()
            
            guard let value = plist.object(forKey: "Test_Email") as? String else {
                fatalError("Couldn't find key 'Test_Email' in 'Config.plist'. Please check the spelling of the key.")
            }
            
            return value
        }
    }
    public static var testPassword: String {
        get {
            let plist = getFile()
            
            guard let value = plist.object(forKey: "Test_Password") as? String else {
                fatalError("Couldn't find key 'Test_Password' in 'Config.plist'. Please check the spelling of the key.")
            }
            
            return value
        }
    }
}
