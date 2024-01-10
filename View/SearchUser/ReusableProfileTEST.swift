//
//  ReusableProfileTEST.swift
//  LunchLink
//
//  Created by Emmet Hamell on 1/9/24.
//

import SwiftUI

struct ReusableProfileTEST: View {
    var user: User
    var userUID: String
    

    
    // @AppStorage("user_UID") private var userUID: String = ""
     @State private var friendRequestStatus: FriendRequest.RequestStatus?
     @State private var buttonMessage: String = ""
     
     @State private var showError: Bool = false
     @State private var errorMessage: String = ""
     
     @State private var fetchedInvites: [Invite] = []
     
     //keep track of the curRequest. The one between you and the user you are looking at, if any
     @State var curRequest: FriendRequest = FriendRequest(senderID: "", receiverID: "", status: .pending) //CHANGED
     
    
    // BOTH OF THESE ARE THE ISSUE private or not they mess up everything
     @AppStorage("first_name") private var firstName = ""
     @AppStorage("last_name") private var lastName = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                HStack(spacing: 12){
                    Text("username \(user.username)")
                    Text("userUID \(userUID)")
                }
            }
        }
    }
}

