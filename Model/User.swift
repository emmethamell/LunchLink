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
    var friends: [String] = [] //to keep track of friends list
    var first: String
    var last: String
    var token: String
    
    enum CodingKeys: CodingKey {
        case id
        case username
        case userUID
        case userEmail
        case userProfileURL
        case friends
        case first
        case last
        case token
    }
}
