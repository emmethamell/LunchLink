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

class LikedUsersViewModel: ObservableObject {
    
    @Published var users = [User]()

    func fetchUsersData(userUIDs: [String]) async {
        DispatchQueue.main.async {
            self.users.removeAll()
        }
        for userUID in userUIDs {
            do {
                let user = try await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self)
                DispatchQueue.main.async {
                    self.users.append(user)
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error fetching user data: \(error)")
                }
            }
        }
    }
}
