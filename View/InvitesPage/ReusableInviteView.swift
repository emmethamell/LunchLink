//
//  ReusableInviteView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/15/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct ReusableInviteView: View {
    var basedOnUID: Bool = false
    var uid: String = ""
    @Binding var invites: [Invite]
    //View Properties
    @State private var isFetching: Bool = true
    //implement pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    
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
                //disable refresh for uid based posts
                guard !basedOnUID else{return}
                
                isFetching = true
                invites = []
                //resetting pagination doc
                paginationDoc = nil
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
            .onAppear{
                //when last post appears, fetch new post
                if invite.id == invites.last?.id && paginationDoc != nil{
                    Task{
                        await fetchInvites()
                    }
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
            //implement pagination
            if let paginationDoc{
                query = Firestore.firestore().collection("Invites")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            }else {
             
                query = Firestore.firestore().collection("Invites")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            //new query for UID based fetch
            if basedOnUID{
                query = query
                    .whereField("userUID" , isEqualTo: uid)
            }
            
            let docs = try await query.getDocuments()
            print("fetched \(docs.documents.count)")
            let fetchedInvites = docs.documents.compactMap{ doc -> Invite? in
                try? doc.data(as: Invite.self)
            }
            await MainActor.run(body: {
                invites.append(contentsOf: fetchedInvites)
                paginationDoc = docs.documents.last
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
