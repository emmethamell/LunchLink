//
//  InviteView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/12/23.
//

import SwiftUI

struct InviteView: View {

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
                Text("Select Actiity")
                Text("Select Friends")
                Text("Select Location")
                Text("GO")
            }

        }
        .vAlign(.top)
    }
}

struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView()
    }
}
