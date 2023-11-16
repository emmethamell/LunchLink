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
        NavigationStack{
            ReusableInviteView(invites: $recentInvites)
                .hAlign(.center).vAlign(.center)
        }
        .navigationTitle("Invites")
    }
}

#Preview {
    FriendsView()
}
