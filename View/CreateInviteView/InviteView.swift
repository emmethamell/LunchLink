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
    @State private var selectedGroup: String = "Choose"
        
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    
    @FocusState private var showKeyboard: Bool
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    

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
            
            //Contents in this stack
            VStack {
                    VStack(alignment: .center, spacing: 20) {
                        
                        Text("What do you want to do?")
                            .font(.title)
                        
                        NavigationLink(destination: ActivitySelectionView(selectedActivity: $selectedActivity).toolbar(.hidden)) {
                            Text(selectedActivity)
                                .font(.title)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                            Text("With who?")
                            .font(.title)

                        NavigationLink(destination: GroupSelectionView(selectedGroup: $selectedGroup).toolbar(.hidden)) {
                                Text(selectedGroup)
                                    .font(.title)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        
                       
                    }
                    .padding()
                
                Button(action: createInvite) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.black,in: Capsule())
                }
                .disableWithOpacity(selectedActivity == "Choose" || selectedGroup == "Choose")
                
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
                
                let invite = Invite(selectedActivity: selectedActivity, selectedGroup: selectedGroup, userName: userName, userUID: userUID, userProfileURL: profileURL)
                try await createDocumentAtFirebase(invite)
            }catch{
                await setError(error)
            }
        }
    }
    
    func createDocumentAtFirebase(_ invite: Invite)async throws{
        let _ = try Firestore.firestore().collection("Invites").addDocument(from: invite, completion: { error in
            if error == nil{
                //post succesfully stored
                isLoading = false
                showCheckmarkNotification()
                onInvite(invite)
                //TODO: Here, once posted, clear the values and navigate to different page or something
                selectedActivity = "Choose"
                selectedGroup = "Choose"
                
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
        
        // Config setup
        var config = SwiftMessages.Config()
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: .normal)
        
        // Show the message
        SwiftMessages.show(config: config, view: view)
    }
    
    
}


struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView{_ in
            
        }
    }
}
