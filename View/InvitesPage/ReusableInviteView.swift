//
//  ReusableInviteView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/15/23.
//

import SwiftUI
import Firebase

struct ReusableInviteView: View {
    @Binding var invites: [Invite]
    //View Properties
    @State var isFetching: Bool = true
    
    @AppStorage("user_name") private var userName: String = ""
    var body: some View {
        
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top, 30)
                }else{
                    if invites.isEmpty{
                        //user has no invites
                        Text("You have no invites")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                        
                    }else{
                        Invites()
                    }
                }
            }
            .padding(15)
        }
        .refreshable{
            isFetching = true
            invites = []
            await fetchInvites()
        }
        .task {
        
            guard invites.isEmpty else{return}
            await fetchInvites()
        }
    }
    
    //Displaying fetched invites
    @ViewBuilder
    func Invites()->some View{
        ForEach(invites){invite in
            InviteCardView(invite: invite) {updatedInvite in
                //updating post in the array
                if let index = invites.firstIndex(where: { invite in
                    invite.id == updatedInvite.id
                }){
                    invites[index].likedIDs = updatedInvite.likedIDs
                    invites[index].dislikedIDs = updatedInvite.dislikedIDs
                }
            } onDelete: {
                //removing post from array
                withAnimation(.easeInOut(duration: 0.25)){
                    invites.removeAll{invite.id == $0.id}
                }
            }
            
            Divider()
                .padding(.horizontal, -15)
        }
    }
    
    //fetching invites
    func fetchInvites()async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Invites")
                .order(by: "publishedDate", descending: true)
                .limit(to: 20)
            let docs = try await query.getDocuments()
            let fetchedInvites = docs.documents.compactMap{ doc -> Invite? in
                try? doc.data(as: Invite.self)
            }
            await MainActor.run(body: {
                invites = fetchedInvites
                isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}
