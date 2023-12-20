//
//  Friendship Button.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/20/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct Friendship_Button: View {
    
    enum FriendshipStatus {
        case notFriends, pending, friends
    }

    var user: User
    var currentUserUID: String
    @Binding var friendRequestStatus: FriendRequest.RequestStatus?
    var onAddFriend: () -> Void
    var onAcceptFriendRequest: () -> Void
    var onDeclineFriendRequest: () -> Void
    @Binding var buttonMessage: String
    
    
    var body: some View {
        //split up button, it should be split for when someone requested someone else
        if buttonMessage != "This person wants to be your friend!" {
            Button(action: {
                if buttonMessage == "pending" {
                    print("pending")
                } else if buttonMessage == "friends!" {
                    print("already friends")
                } else if buttonMessage == "add friend" {
                    onAddFriend()
                } else {
                    print("SOMETHING WENT WRONG")
                }
                
            }) {
                Text(buttonMessage)
            }
            .buttonStyle(CustomButtonStyle())
        } else {
            Text("This person wants to be your friend!")
            HStack {
                
                Button(action: {
                    onAcceptFriendRequest()
                }) {
                    Text("Accept")
                }
                .buttonStyle(CustomButtonStyle())
                
                Button(action: {
                    onDeclineFriendRequest()
                }) {
                    Text("Decline")
                }
                .buttonStyle(CustomButtonStyle())
            }
            
        }
    }
    
    struct CustomButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8) // Adjust the vertical padding to make it thinner
                .padding(.horizontal, 16) // Adjust the horizontal padding as needed
                .foregroundColor(.white)
                .background(configuration.isPressed ? Color.black.opacity(0.8) : Color.black)
                .cornerRadius(8)
                .font(.headline) //Adjust the font size and style as needed
        }

    }
}

