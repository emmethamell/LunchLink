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
    
    var body: some View {
        
        VStack(alignment: .leading){
            HStack{
                Text("Your Invites")
                    .font(.title)
                    .padding()
                    .bold()
                Spacer()
                NavigationLink {
                    SearchUserView()
                }label:{
                    Image(systemName: "magnifyingglass")
                        .tint(.black)
                        .scaleEffect(0.9)
                }
                .padding()
                
            }
            
            ReusableInviteView(invites: $recentInvites)
                .hAlign(.center)
                .vAlign(.center)
        }
        .onAppear(perform: requestNotificationPermission)
    }
    
    private func requestNotificationPermission() {
        let userDefaults = UserDefaults.standard

        // Check if we've already asked for notification permission
        if !userDefaults.bool(forKey: "hasRequestedNotificationPermission") {
            // Request permission
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                // Handle the response - granted is true if permission was given
            }

            // Set the flag to true so we don't ask again
            userDefaults.set(true, forKey: "hasRequestedNotificationPermission")
        }
    }
    
    
}

#Preview {
    FriendsView()
}
