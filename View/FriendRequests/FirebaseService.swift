//
//  FirebaseService.swift
//  LunchLink
//
//  Created by Emmet Hamell on 1/11/24.
//

import FirebaseFirestore
import SwiftUI
import Firebase
import FirebaseFirestoreSwift

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
    
    func acceptFriendRequest(userUID: String, otherUserUID: String) {
        Task{
            print(userUID)
            print(otherUserUID)
            let query = Firestore.firestore().collection("FriendRequests")
                .whereField("receiverID",  isEqualTo: userUID)
                .whereField("senderID", isEqualTo: otherUserUID)
            let querySnapshot = try await query.getDocuments()
            if let document = querySnapshot.documents.first {
                let documentID = document.documentID
                print(documentID)
                try await Firestore.firestore().collection("FriendRequests").document(documentID).updateData([
                    "status": "accepted"
                ])
                addToEachothersFriendLists(userUID: userUID, otherUserUID: otherUserUID)
            } else {
                print("No matching document found")
            }

        }
       // addToEachothersFriendLists(userUID: userUID, otherUserUID: otherUserUID)
    }
    
    func addToEachothersFriendLists(userUID: String, otherUserUID: String) {
        Task{
            try await Firestore.firestore().collection("Users").document(userUID).updateData([
                "friends": FieldValue.arrayUnion([otherUserUID])
            ])
            try await Firestore.firestore().collection("Users").document(otherUserUID).updateData([
                "friends": FieldValue.arrayUnion([userUID])
            ])
        }
    }
    

}

