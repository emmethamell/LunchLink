//
//  FirebaseService.swift
//  LunchLink
//
//  Created by Emmet Hamell on 1/11/24.
//

import FirebaseFirestore
import SwiftUI

class FriendRequestService {
    private let db = Firestore.firestore()
    
    func fetchPendingFriendRequests(userUID: String, completion: @escaping ([User]) -> Void) {
        db.collection("FriendRequests")
          .whereField("receiverID", isEqualTo: userUID)
          .whereField("status", isEqualTo: "pending")
          .getDocuments { snapshot, error in
              guard let documents = snapshot?.documents else {
                  print("No documents in 'FriendRequests'")
                  return
              }

              let senderIDs = documents.map { $0["senderID"] as? String ?? "" }
              self.fetchUsers(senderIDs: senderIDs, completion: completion)
          }
    }

    private func fetchUsers(senderIDs: [String], completion: @escaping ([User]) -> Void) {
        guard !senderIDs.isEmpty else {
            completion([])
            return
        }
        db.collection("Users")
          .whereField("userUID", in: senderIDs)
          .getDocuments { snapshot, error in
              guard let documents = snapshot?.documents else {
                  print("No users found")
                  return
              }

              let users = documents.compactMap { document -> User? in
                  try? document.data(as: User.self)
              }
              completion(users)
          }
    }
}

