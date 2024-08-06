//
//  DataTypes.swift
//  SplitTheBill
//
//  Created by Manya Gupta on 6/18/24.
//

import Foundation

struct ContactInfo: Identifiable, Codable {
    let id = UUID()
    let firstName: String
    let phoneNumber: String
    var total: Double = 0.0
    
    static func ==(lhs: ContactInfo, rhs: ContactInfo) -> Bool {
        lhs.id == rhs.id
    }
}

struct Bill: Identifiable, Codable {
    let id: UUID
    var tip: String
    var tax: String
    var pickedContacts: [ContactInfo]
    var inputInfos: [FoodItem]
    var isPersonSelected: [Bool]
    var title: String
    
    
    
    init(id: UUID = UUID(), tip: String, tax: String, pickedContacts: [ContactInfo], inputInfos: [FoodItem], isPersonSelected: [Bool], title: String) {
        self.id = id
        self.tip = tip
        self.tax = tax
        self.pickedContacts = pickedContacts
        self.inputInfos = inputInfos
        self.isPersonSelected = isPersonSelected
        self.title = title
    }
     
     
}

struct FoodItem: Identifiable, Codable {
    let id = UUID()
    var text1: String
    var text2: String
    var selectedNumber: Int
    var addedPersons: [ContactInfo]
}

enum Tab: String, CaseIterable {
    case house
    case plus
    case info
}
