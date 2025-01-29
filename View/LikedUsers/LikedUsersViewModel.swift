//
//  LikedUsersViewModel.swift
//  LunchLink
//
//  Created by Emmet Hamell on 12/23/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import SwiftUI

@MainActor
class LikedUsersViewModel: ObservableObject {
    
    @Published var users: [User] = []
    private var currentUser: User?

    func fetchCurrentUser() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            let fetchedUser = try await Firestore.firestore()
                .collection("Users")
                .document(userUID)
                .getDocument(as: User.self)
            self.currentUser = fetchedUser
        } catch {
            print("Error fetching current user: \(error.localizedDescription)")
        }
    }
    
    func fetchUsersData(userUIDs: [String]) async {
        if currentUser == nil {
            await fetchCurrentUser()
        }
        
        var fetchedUsers: [User] = []
        
        for userUID in userUIDs {
            do {
                let user = try await Firestore.firestore()
                    .collection("Users")
                    .document(userUID)
                    .getDocument(as: User.self)
                
                fetchedUsers.append(user)
                
            } catch {
                print("Error fetching user data for \(userUID): \(error)")
            }
        }
        
        if let curUser = currentUser {
            fetchedUsers = fetchedUsers.filter { likedUser in
                // You block them?
                if curUser.blockedUsers.contains(likedUser.userUID) {
                    return false
                }
                // They block you?
                if likedUser.blockedUsers.contains(curUser.userUID) {
                    return false
                }
                return true
            }
        }
        
        self.users = fetchedUsers
    }
}
