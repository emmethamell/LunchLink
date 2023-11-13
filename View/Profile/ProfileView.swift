//
//  ProfileView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/12/23.
//

import SwiftUI

struct ProfileView: View {
    //My Profile Data
    @State private var myProfile : User?
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        //logout
                        //delete account
                        Button("Logout") {
                            
                        }
                        
                        Button("Delete Account", role: .destructive) {
                            
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
        }

    }
}

struct ProfileView_Previews: PreviewProvider {

    static var previews: some View {
        ProfileView()
    }
}
