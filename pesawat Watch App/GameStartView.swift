//
//  GameStartView.swift
//  pesawat Watch App
//
//  Created by moreno on 27/05/24.
//

import SwiftUI

struct GameStartView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image("KroggStart")
                    .resizable()
                    .frame(width: 100, height: 100)
                Text("Get all Xaphis!")
                    .font(.headline)
                    .padding()
                NavigationLink(destination: ContentView()) {
                    Text("Play")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    GameStartView()
}
