//
//  Invite.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/13/23.
//

import SwiftUI
import FirebaseFirestoreSwift

//Invite model
struct Invite: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var imageURL: URL?
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs:[String] = []
    //basic user info
    var userName: String
    var userUID: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey{
        case id
        case text
        case imageURL
        case imageReferenceID
        case publishedDate
        case likedIDs
        case dislikedIDs
        case userName
        case userUID
        case userProfileURL
    }
}

