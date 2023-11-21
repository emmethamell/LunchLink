//
//  FriendRequest.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/20/23.
//

import SwiftUI
import FirebaseFirestoreSwift

struct FriendRequest: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String? //for firestore, automatically gets created
    var senderID: String
    var receiverID: String
    var status: RequestStatus
    
    enum CodingKeys: CodingKey{
        case id
        case senderID
        case receiverID
        case status
    }
    
    enum RequestStatus: String, Codable {
        case pending
        case accepted
        case declined
    }
}
