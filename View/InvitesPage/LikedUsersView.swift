//
//  LikedUsersView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 12/22/23.
//
import SwiftUI

struct LikedUsersView: View {
    
    @ObservedObject var viewModel = LikedUsersViewModel()
    var userUIDs: [String]
    @AppStorage("user_UID") private var currentUserUID: String = ""
    
    var body: some View {
        NavigationView {
            List(viewModel.users) { user in
                NavigationLink(destination: ReusableProfileContent(user: user, userUID: currentUserUID)) {
                    HStack {
                        AsyncImage(url: user.userProfileURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        
                        
                        // Display username
                        Text(user.username)
                            .font(.body)
                            .padding(.leading, 10)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchUsersData(userUIDs: userUIDs)
                }
            }
        }
    }
}




