//
//  InviteCardView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/16/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import Foundation

struct InviteCardView: View {
    var invite: Invite
    var user: User
    var onUpdate: (Invite)->()
    var onDelete: ()->()
    
    @AppStorage("user_UID") private var userUID: String = ""
    
    @AppStorage("first_name") private var firstName = ""
    @AppStorage("last_name") private var lastName = ""
    
    @State private var docListner: ListenerRegistration?
    
    @State private var showingLikedUsers = false
    
    @State private var showProfile = false
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            Button(action: {
                self.showProfile = true
            }) {
                WebImage(url: invite.userProfileURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 6){
                Text(invite.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Text(formatDateString(invite.publishedDate))
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                //Text(invite.publishedDate.formatted(date: .numeric, time: .shortened))

                Text("\(invite.first) \(invite.last) wants to ")
                    +
                Text(invite.selectedActivity)
                    .bold()
                   // .textSelection(.enabled)
                    //.padding(.vertical, 8)
                InviteInteraction()
            }
        }
        .sheet(isPresented: $showProfile) {
            // only present this sheet if otherProfile is not nil
            ReusableProfileContent(user: user, userUID: userUID, firstName: firstName, lastName: lastName)
           
        }

        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            if invite.userUID == userUID{
                Menu {
                    Button("Delete Invite", role: .destructive, action: deleteInvite)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
            }
        })

        .task{
            //add only once
            if docListner == nil{
                guard let inviteID = invite.id else {return}
                docListner = Firestore.firestore().collection("Invites").document(inviteID).addSnapshotListener({
                    snapshot, error in
                    if let snapshot{
                        if snapshot.exists{
                            if let updatedInvite = try? snapshot.data(as: Invite.self){
                                onUpdate(updatedInvite)
                            }
                        }else{
                            onDelete()
                        }
                    }
                })
            }
        }

        .onDisappear{
            if let docListner{
                docListner.remove()
                self.docListner = nil
            }
        }
    }
    
    
    @ViewBuilder
    func InviteInteraction() -> some View {
        HStack(spacing: 6) {
            Button(action: acceptInvite) {
                if invite.likedIDs.contains(userUID) {
                    Text("I'm in!")
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.mint)
                        .cornerRadius(8)
                } else {
                    Text("I'm in!")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mint, lineWidth: 1)
                        )
                        
                }
            }
            Spacer()
           
                Button(action: { showingLikedUsers = true }) {
                    HStack(spacing: 1){
                        
                        Text("\(invite.likedIDs.count) down")
                            .font(.headline)
                            .foregroundColor(.black)
                            
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.black)
                            .imageScale(.small)
                            .scaleEffect(0.5)
                            .font(Font.title.weight(.bold))
                    }
                    .padding(.trailing, 40)
                    
          
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingLikedUsers) {
                LikedUsersView(userUIDs: invite.likedIDs)
            }


        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
    }    
    
    
    func acceptInvite(){
        Task{
            guard let inviteID = invite.id else{return}
            if invite.likedIDs.contains(userUID){
                try await Firestore.firestore().collection("Invites").document(inviteID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            }else{
                try await Firestore.firestore().collection("Invites").document(inviteID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID])
                ])
                
            }
        }
    }

    func deleteInvite(){
        Task{
            do{
                //delete firebase storage document
                guard let inviteID = invite.id else{return}
                try await Firestore.firestore().collection("Invites").document(inviteID).delete()
            }catch{
                
            }
        }
    }
    
    func formatDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date.now)
    }

}
