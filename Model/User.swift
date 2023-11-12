//
//  User.swift
//  LunchLink
//
//  Created by Emmet Hamell on 10/23/23.
//

import SwiftUI
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey {
        case id
        case username
        case userUID
        case userEmail
        case userProfileURL
    }
}
