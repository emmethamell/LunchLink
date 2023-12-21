//
//  Invite.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/13/23.
//

import SwiftUI
import FirebaseFirestoreSwift

//Invite model
struct Invite: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var selectedActivity: String
    var selectedGroup: String
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs:[String] = []
    //basic user info
    var userName: String
    var userUID: String
    var userProfileURL: URL
    var first: String
    var last: String
    
    enum CodingKeys: CodingKey{
        case id
        case selectedActivity
        case selectedGroup
        case publishedDate
        case likedIDs
        case dislikedIDs
        case userName
        case userUID
        case userProfileURL
        case first
        case last
    }
}

