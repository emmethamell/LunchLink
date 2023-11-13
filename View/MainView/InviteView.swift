//
//  InviteView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/12/23.
//

import SwiftUI

struct InviteView: View {

    var body: some View {
        VStack(spacing: 20) {
            NavigationLink(destination: ProfileView()){
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width:30, height:30)
            }
        }
        .hAlign(.trailing)
        .vAlign(.top)
        .padding(20)
    }
}

struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView()
    }
}
