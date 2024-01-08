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
    
    @State private var users: [String: User] = [:]

    @State private var isFetching: Bool = true

    @State private var paginationDoc: QueryDocumentSnapshot?
    
    @AppStorage("user_name") private var userName: String = ""
    
    @State private var curUser: User?
    
    
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

                guard !basedOnUID else{return}
                isFetching = true
                invites = []
                paginationDoc = nil
                await fetchUserData()
                await fetchInvites()
                await fetchUsersForInvites()
                isFetching = false
            }
            .task {
                guard invites.isEmpty else{return}
                if curUser != nil{return} //task will be called any time we open tab, so we need to limit it to the first time (initial fetch)
                await fetchUserData()
                await fetchInvites()
                await fetchUsersForInvites()
                isFetching = false
                
            }
        
    }
    
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else{return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self)
        else{return}
        await MainActor.run(body: {
            curUser = user
        })
    }
    
    func fetchUsersForInvites() async {
        let userUIDs = Set(invites.map { $0.userUID }) // Get unique user UIDs from invites
        for uid in userUIDs {
            if let user = try? await Firestore.firestore().collection("Users").document(uid).getDocument(as: User.self) {
                DispatchQueue.main.async {
                    self.users[uid] = user
                }
            }
        }
    }
    
    @ViewBuilder
    func Invites()->some View{
        ForEach(invites){invite in
            if let user = users[invite.userUID]{
                InviteCardView(invite: invite, user: user) { updatedInvite in    //INVITE CARD VIEW -> updatedInvite passed to onUpdate callback
                    //updating post in the array
                    if let index = invites.firstIndex(where: { invite in
                        invite.id == updatedInvite.id
                    }){
                        invites[index].likedIDs = updatedInvite.likedIDs
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
    }
    
    
    func fetchInvites() async {
        
        if basedOnUID{
            do{
                var query: Query!
                
                
                if let paginationDoc{
                        query = Firestore.firestore().collection("Invites")
                            .order(by: "publishedDate", descending: true)
                            .start(afterDocument: paginationDoc)
                            .limit(to: 20)
                } else {
                 
                    query = Firestore.firestore().collection("Invites")
                        .order(by: "publishedDate", descending: true)
                        .limit(to: 20)
                }
              
                    query = query
                        .whereField("userUID" , isEqualTo: uid)
                
                
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
        } else {
            let db = Firestore.firestore()
            
            var ids = curUser?.friends ?? []
            if curUser != nil {
                ids.append(curUser!.userUID)
            }
            let chunkedArray = ids.chunked(into: 10)
            
            for idsChunk in chunkedArray {
                do {
                    var query = db.collection("Invites")
                        .order(by: "publishedDate", descending: true)
                        .whereField("userUID", in: idsChunk)
                        .limit(to: 20)
                    
                    if let paginationDoc = paginationDoc {
                        query = query.start(afterDocument: paginationDoc)
                    }
                    
                    let snapshot = try await query.getDocuments()
                    let newInvites = snapshot.documents.compactMap { doc in
                        try? doc.data(as: Invite.self)
                    }
                    if newInvites.isEmpty {
                        isFetching = false
                        break
                    }
                    
                    invites.append(contentsOf: newInvites)
                    if let lastDocument = snapshot.documents.last {
                        paginationDoc = lastDocument
                    } else {
                        isFetching = false
                    }
                } catch {
                    print("Error fetching documents: \(error.localizedDescription)")
                    break
                }
            }
        }
    }
    
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}


#Preview {
    ContentView()
}
