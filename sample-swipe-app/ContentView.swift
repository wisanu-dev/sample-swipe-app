//
//  ContentView.swift
//  sample-swipe-app
//
//  Created by Wisanu Paunglumjeak on 19/9/2567 BE.
//

import SwiftUI

/*
 Ref: https://youtube.com/watch?v=K8VnH2eEnK4
*/

struct ContentView: View {
    
    @State private var colors: [Color] = [
        .black, .yellow, .purple, .brown, .accentColor,
        .pink, .red, .orange, .blue, .green, .gray
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    ForEach(colors, id: \.self) { color in
                        if #available(iOS 17.0, *) {
                            SwipeAction(cornerRadius: 8, direction: .leading) {
                                cardView(color)
                            } actions: {
                                
                                SwipeActionModel(tint: .blue, icon: "star.fill") {
                                    debugPrint("Bookmarked")
                                }
                                
                                SwipeActionModel(tint: .red, icon: "trash.fill") {
                                    withAnimation(.easeOut) {
                                        colors.removeAll(where: { $0 == color })
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Swipe Action")
        }
    }
    
    @ViewBuilder
    func cardView(_ Color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 80, height: 5)
                
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 60, height: 5)
            }
            
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.4))
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.gradient)
    }
}

#Preview {
    ContentView()
}
