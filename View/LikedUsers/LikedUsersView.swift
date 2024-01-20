//
//  LikedUsersView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 12/22/23.
//
import SwiftUI
import SDWebImageSwiftUI

struct LikedUsersView: View {
    
    @ObservedObject var viewModel = LikedUsersViewModel()
    var userUIDs: [String]
    @AppStorage("user_UID") private var currentUserUID: String = ""
    
    @AppStorage("first_name") private var firstName = ""
    @AppStorage("last_name") private var lastName = ""
    @State private var isImageLoaded = false
    var body: some View {
        NavigationStack {
            List(viewModel.users) { user in
                NavigationLink(destination: ReusableProfileContent(user: user, userUID: currentUserUID, firstName: firstName, lastName: lastName)) {
                    HStack {
                        WebImage(url: user.userProfileURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .onAppear(){
                                self.isImageLoaded = true
                            }
                        
                        
                        Text(user.username)
                            .font(.body)
                            .padding(.leading, 10)
                    }
                }
                .disabled(!isImageLoaded)
                
            }
            .onAppear {
                Task {
                    await viewModel.fetchUsersData(userUIDs: userUIDs)
                }
            }
        }
    }
}




