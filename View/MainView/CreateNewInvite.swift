//
//  CreateNewInvite.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/13/23.
//

import SwiftUI

struct CreateNewInvite: View {
    // Callbacks
    var onInvite: (Invite)->()
    //invite properties
    @State private var postText: String = ""
    @State private var postImageData: Data?
    //stored user data from defaults
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    // view properties
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    var body: some View {
        VStack{
            HStack{
                Menu {
                    Button("Cancel", role: .destructive){
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                    
                }
                .hAlign(.leading)
                
                Button(action: {}) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.black,in: Capsule())
                }
                .disableWithOpacity(postText == "")
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15){
                    TextField("Whats Happening?", text: $postText, axis: .vertical)
                }
                .padding(15)
            }
        }
        .vAlign(.top)
    }
}

struct CreateNewInvite_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewInvite{_ in
            
        }
    }
}
