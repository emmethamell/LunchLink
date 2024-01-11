//
//  PendingRequestsView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 1/11/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage


struct PendingRequestsView: View {
    var curUserUID: String
    @AppStorage("user_UID") private var userUID: String = ""
    
    @State private var showNoPendingRequestsMessage = false
    @State private var pendingUsers: [User] = []
    
    var body: some View {
        VStack {
            if showNoPendingRequestsMessage {
                Text("No pending friend requests")
                    .foregroundColor(.gray)
                    .font(.title2)
                    .padding()
            } else {
                List(pendingUsers, id: \.userUID) { user in
                    Text(user.username) // display the user info here
                }
            }
        }
        .onAppear {
            fetchPendingRequests()
        }
    }
        
    
    private func fetchPendingRequests() {
        let userService = FriendRequestService()
        userService.fetchPendingFriendRequests(userUID: curUserUID) { users in
            DispatchQueue.main.async {
                if users.isEmpty {
                    self.showNoPendingRequestsMessage = true
                } else {
                    self.pendingUsers = users
                }
            }
        }
    }
    

    
    
}


/*
#Preview {
    PendingRequestsView()
}
*/
