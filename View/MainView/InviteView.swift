//
//  InviteView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/12/23.
//

import SwiftUI

struct InviteView: View {

    var body: some View {
        NavigationView {
            VStack {
                //content of
                Text("HELLO")
            }
            
            .navigationBarItems(
                trailing: NavigationLink(destination: ProfileView()) {
                    Image(systemName: "gear")
                }
            )
        }
    }
}

struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView()
    }
}
