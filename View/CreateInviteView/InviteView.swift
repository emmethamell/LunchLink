//
//  InviteView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/12/23.
//

import SwiftUI
import Firebase
import SwiftMessages
import FirebaseFirestore


struct InviteView: View {
    var onInvite: (Invite)->()
    
    @State private var recentInvites: [Invite] = []
    
    @State private var selectedActivity: String = "Choose"
    
    @State private var details: String = ""
        
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    @AppStorage("first_name") var firstName = ""
    @AppStorage("last_name") var lastName = ""
    
    @AppStorage("user_token") var userToken: String = ""
    
    @FocusState private var showKeyboard: Bool
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @FocusState private var isFocused: Bool
    

    var body: some View {
        VStack {
            VStack {
                NavigationLink(destination: ProfileView()){
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width:30, height:30)
                }
            }
            .padding(20)
            .hAlign(.trailing)
            
            VStack {
                    VStack(alignment: .center, spacing: 20) {
                        
                        Text("What do you want to do?")
                            .font(.title)
                        
                        ActivitySelectionView(selectedActivity: $selectedActivity)
                            //.padding()
                    
                    }
                    .padding()
                
                
                // Let the user add details here so they can choose a time, a place, etc.
                // Removing user-generated content for now
                /*
                Text("Details:")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                
                    
                
                TextField("When? Where?", text: $details, axis: .vertical)
                    .focused($isFocused)
                    .onChange(of: details) { newValue in
                        guard let newValueLastChar = newValue.last else { return }
                        if newValueLastChar == "\n" {
                            details.removeLast()
                            isFocused = false
                        }
                    }
                    .lineLimit(2, reservesSpace: true)
                    .font(.callout)
                    .textFieldStyle(.roundedBorder)
                    .padding(.leading)
                    .padding(.trailing)

                */
                
                Button(action: createInvite) {
                    Text("Post")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(.black,in: Capsule())
                }
                .disableWithOpacity(selectedActivity == "Choose")
                .padding(.bottom, 40)
             
            }
            // end of stack
            

        }
        .vAlign(.top)
        .alert(errorMessage, isPresented: $showError, actions: {})
        .overlay{
            LoadingView(show: $isLoading)
        }
    }
    
    //MARK: Post content to firebase
    func createInvite(){
        isLoading = true
        Task{
            do{
                guard let profileURL = profileURL else{return}
                
                //use to delete invite if needed
                let imageReferenceID = "\(userUID)\(Date())"
                
                if details != "" {
                    let invite = Invite(selectedActivity: selectedActivity, userName: userName, userUID: userUID, userProfileURL: profileURL, first: firstName, last: lastName, details: details)
                    try await createDocumentAtFirebase(invite)

                } else {
                    let invite = Invite(selectedActivity: selectedActivity, userName: userName, userUID: userUID, userProfileURL: profileURL, first: firstName, last: lastName)
                    try await createDocumentAtFirebase(invite)
                }
                
                
            }catch{
                await setError(error)
            }
        }
        fetchTokensAndSendNotification(forUserUID: userUID, selectedActivity: selectedActivity)
    }
    
    func createDocumentAtFirebase(_ invite: Invite)async throws{
        let _ = try Firestore.firestore().collection("Invites").addDocument(from: invite, completion: { error in
            if error == nil{
                //post succesfully stored
                isLoading = false
                showCheckmarkNotification()
                onInvite(invite)
                selectedActivity = "Choose"
                details = ""
                
            }
        })
    }
    
    //MARK: Displaying errors as alerts
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
    
    func showCheckmarkNotification() {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.success)
        view.configureContent(title: "Success", body: "Invite Sent!")
        view.button?.isHidden = true
        
        var config = SwiftMessages.Config()
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: .normal)
        
        SwiftMessages.show(config: config, view: view)
    }
    

    func fetchTokensAndSendNotification(forUserUID userUID: String, selectedActivity: String) {
        let db = Firestore.firestore()
        db.collection("Users").document(userUID).getDocument { (document, error) in
            if let document = document, document.exists {

                guard let friendsUIDs = document.data()?["friends"] as? [String] else { return }
                print("now here")
                var tokens: [String] = []
                let group = DispatchGroup()

                for friendUID in friendsUIDs {
                    group.enter()
                    db.collection("Users").document(friendUID).getDocument { (friendDocument, error) in
                        if let friendDocument = friendDocument, friendDocument.exists {
                            if let token = friendDocument.data()?["token"] as? String {
                                tokens.append(token)
                            }
                        }
                        group.leave()
                    }
                }
                //send after fetching all notifications
                group.notify(queue: .main) {
                    NotificationHandler.shared.sendNotificationRequest(
                        header: "LunchLink",
                        body: firstName + " " + lastName + " wants to " + selectedActivity + "!",
                        fcmTokens: tokens)
                }

            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    
}

/*
struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView{_ in
            
        }
    }
}
*/
