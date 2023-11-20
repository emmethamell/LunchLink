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

struct InviteCardView: View {
    var invite: Invite
    
    var onUpdate: (Invite)->()
    var onDelete: ()->()
    
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListner: ListenerRegistration?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            WebImage(url: invite.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 6){
                Text(invite.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(invite.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("\(invite.userName) wants to \(invite.selectedActivity) with \(invite.selectedGroup)")
                    .textSelection(.enabled)
                    .padding(.vertical, 8)
                InviteInteraction()
            }
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


        .onAppear{
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
    //MARK: Accept or deny
    @ViewBuilder
    func InviteInteraction()->some View{
        HStack(spacing: 6){
            Button(action: acceptInvite){
                if invite.likedIDs.contains(userUID){
                    Text("accept")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.green)
                        .cornerRadius(8)
                } else {
                    Text("accept")
                }
            }
            Text("\(invite.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            Button(action: denyInvite) {
                if invite.dislikedIDs.contains(userUID){
                    Text("deny")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.red)
                        .cornerRadius(8)
                } else {
                    Text("deny")
                }
            }
            .padding(.leading, 25)
            Text("\(invite.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
    }
    //accepting invite
    func acceptInvite(){
        Task{
            guard let inviteID = invite.id else{return}
            if invite.likedIDs.contains(userUID){
                //remove the user id from the array
                try await Firestore.firestore().collection("Invites").document(inviteID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            }else{
                //add user id to liked array and remove from disliked if there
                try await Firestore.firestore().collection("Invites").document(inviteID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
                
            }
        }
    }
    //deny invite
    func denyInvite(){
        Task{
            guard let inviteID = invite.id else{return}
            if invite.dislikedIDs.contains(userUID){
                //remove the user id from the array
                try await Firestore.firestore().collection("Invites").document(inviteID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }else{
                //add user id to liked array and remove from disliked if there
                try await Firestore.firestore().collection("Invites").document(inviteID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([userUID])
                ])
                
            }
        }
    }
    //delete invite
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
}
