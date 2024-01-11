//
//  FriendsView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/15/23.
//

import SwiftUI
import UserNotifications

struct FriendsView: View {
    
    @State private var recentInvites: [Invite] = []
    
    @AppStorage("user_UID") private var userUID: String = ""
    
    var body: some View {
        
        VStack(alignment: .leading){
            HStack{
                Text("Your Invites")
                    .font(.title)
                    .padding()
                    .bold()
                Spacer()
                NavigationLink {
                    PendingRequestsView(curUserUID: userUID)
                }label:{
                    Image(systemName: "bell")
                        .tint(.black)
                        .scaleEffect(1.3)
                }
                
                NavigationLink {
                    SearchUserView()
                }label:{
                    Image(systemName: "person.badge.plus")
                        .tint(.black)
                        .scaleEffect(1.3)
                }
                .padding()
                
            }
            
            ReusableInviteView(invites: $recentInvites)
                .hAlign(.center)
                .vAlign(.center)
        }
    }
    

    
    
}

#Preview {
    FriendsView()
}
