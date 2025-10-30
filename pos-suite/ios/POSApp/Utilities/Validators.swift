//
//  Validators.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation


struct Validators {
    static func email(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func phone(_ phone: String) -> Bool {
        // Simple validation - adjust based on your needs
        let phoneRegex = "^[+]?[0-9\\s-]{8,}$"
        let phonePredicate = NSPredicate(format:"SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}
