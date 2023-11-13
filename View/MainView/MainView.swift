//
//  MainView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 10/30/23.
//

import SwiftUI

struct MainView: View {

    var body: some View {
        
        TabView{
            Text("Friend activities")
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Friends")
                }
            
            InviteView()
                .tabItem {
                    Image(systemName: "hand.wave.fill")
                    Text("Invite")
                }

            
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
