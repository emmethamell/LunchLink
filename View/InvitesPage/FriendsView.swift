//
//  FriendsView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/15/23.
//

import SwiftUI

struct FriendsView: View {
    
    @State private var recentInvites: [Invite] = []
    
    var body: some View {
        VStack(alignment: .leading){
            
            Text("Your Invites")
                .font(.title)
                .padding()
                .bold()

            ReusableInviteView(invites: $recentInvites)
                .hAlign(.center)
                .vAlign(.center)
        }
        

    }
}

#Preview {
    FriendsView()
}
