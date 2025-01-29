//
//  UserBlockService.swift
//  LunchLink
//
//  Created by Emmet Hamell on 1/28/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class UserBlockService {
    static let shared = UserBlockService()
    private init() {}
    
    func blockUser(currentUserID: String, blockedUserID: String) async throws {
        let userRef = Firestore.firestore().collection("Users").document(currentUserID)
        try await userRef.updateData([
            "blockedUsers": FieldValue.arrayUnion([blockedUserID])
        ])
        
    }
    
    func unblockUser(currentUserID: String, blockedUserID: String) async throws {
        let userRef = Firestore.firestore().collection("Users").document(currentUserID)
        try await userRef.updateData([
            "blockedUsers": FieldValue.arrayRemove([blockedUserID])
        ])
    }
    
    private func removeFromFriendLists(currentUserID: String, otherUserID: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("Users").document(currentUserID).updateData([
            "friends": FieldValue.arrayRemove([otherUserID])
        ])
        try await db.collection("Users").document(otherUserID).updateData([
            "friends": FieldValue.arrayRemove([currentUserID])
        ])
    }
}

