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
    var firstName: String
    var lastName: String
    
    @AppStorage("user_UID") private var userUID: String = ""
    
    @State private var showNoPendingRequestsMessage = false
    @State private var pendingUsers: [User] = []
    
    @State private var showProfile = false
    
    @State private var selectedUser: User?
    @State private var acceptedUserIDs: Set<String> = []
    @State private var declinedUserIDs: Set<String> = []
    
    
    
    var body: some View {
        NavigationStack {
            if showNoPendingRequestsMessage {
                Text("No friend requests")
                    .foregroundColor(.gray)
                    .font(.title2)
                    .padding()
            } else {
                List{
                    ForEach(pendingUsers, id: \.userUID) { user in
                        HStack{
                            Button(action: {
                                self.selectedUser = user
                            }) {
                                Text(user.username)
                            }
                            
                            Spacer()
                            if acceptedUserIDs.contains(user.userUID) {
                                Text("Friends!")
                            } else if declinedUserIDs.contains(user.userUID){
                                Text("Declined")
                            } else {
                                Button("Accept") {
                                    print("Accepted \(user.username)")
                                    //accept this user as a friend
                                    acceptedUserIDs.insert(user.userUID)
                                    let userService = FriendRequestService()
                                    userService.acceptFriendRequest(userUID: userUID, otherUserUID: user.userUID)
                                }
                                .padding(.trailing)
                                .foregroundColor(.green)
                                
                                Button("Decline") {
                                    print("Declined \(user.username)")
                                    declinedUserIDs.insert(user.userUID)
                                    let userService = FriendRequestService()
                                    userService.deleteFriendRequest(receiverID: userUID, senderID: user.userUID)
                                    
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                    }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .navigationTitle("Friend Requests")
        .onAppear {
            fetchPendingRequests()
        }
        .sheet(item: $selectedUser) { user in
            // only present this sheet if otherProfile is not nil
            ReusableProfileContent(user: user, userUID: userUID, firstName: firstName, lastName: lastName)
           
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


