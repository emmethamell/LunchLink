//
//  Invite.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/13/23.
//

import SwiftUI
import FirebaseFirestoreSwift


struct Invite: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var selectedActivity: String
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    //basic user info
    var userName: String
    var userUID: String
    var userProfileURL: URL
    var first: String
    var last: String
    
    enum CodingKeys: CodingKey{
        case id
        case selectedActivity
        case publishedDate
        case likedIDs
        case userName
        case userUID
        case userProfileURL
        case first
        case last
    }
}

