//
//  SwipeAction.swift
//  sample-swipe-app
//
//  Created by Wisanu Paunglumjeak on 19/9/2567 BE.
//

import SwiftUI


@available(iOS 17.0, *)
struct SwipeAction<Content: View>: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var itemIndex: Int = 0
    var cornerRadius: CGFloat = 0
    var direction: SwipeDirection = .trailing
    @Binding var activeIndex: Int?
    
    @ViewBuilder var content: Content
    
    @SwipeActionBuilder var actions: [SwipeActionModel]
    
    let viewID = UUID()
    @State private var isEnabled: Bool = true
    @State private var scrollOffset: CGFloat = .zero
    @State private var swipeActionState: SwipeActionState = .inactivating
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    content
                        .rotationEffect(.init(degrees: direction == .leading ? 180 : 0))
                        .containerRelativeFrame(.horizontal)
                        .background(colorScheme == .dark ? .black : .white)
                        .background {
                            if let firstAction = actions.first {
                                Rectangle()
                                    .fill(firstAction.tint)
                                    .opacity(scrollOffset == .zero ? 0 : 1)
                            }
                        }
                        .id(viewID)
                        .transition(.identity)
                        .overlay{
                            GeometryReader {
                                let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX
                                
                                Color.clear
                                    .preference(key: SwipeActionOffsetKey.self, value: minX)
                                    .onPreferenceChange(SwipeActionOffsetKey.self) {
                                        scrollOffset = $0
                                    }
                            }
                        }
                    actionButton {
                        withAnimation(.snappy) {
                            proxy.scrollTo(
                                viewID,
                                anchor: direction == .trailing ? .topLeading : .topTrailing
                            )
                        }
                    }
                    .opacity(scrollOffset == .zero ? 0 : 1)
                }
                .onChange(of: activeIndex) { _, newValue in
                    if activeIndex != itemIndex {
                        Task {
                            withAnimation(.snappy) {
                                proxy.scrollTo(
                                    viewID,
                                    anchor: direction == .trailing ? .topLeading : .topTrailing
                                )
                            }
                        }
                    }
                }
                .scrollTargetLayout()
                .visualEffect { content, geometry in
                    content.offset(x: scrollOffSet(geometry))
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .background{
                if let lastAction = actions.last {
                    Rectangle()
                        .fill(lastAction.tint)
                        .opacity(scrollOffset == .zero ? 0 : 1)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .rotationEffect(.init(degrees: direction == .leading ? 180 : 0))
        }
        .allowsHitTesting(isEnabled)
        .transition(SwipeActionCustomTransition())
        .onChange(of: scrollOffset) { oldValue, newValue in
            swipeActionState = SwipeActionState.initialState(
                oldScrollOffset: oldValue,
                newScrollOffset: newValue,
                limit: -(CGFloat(actions.count) * 100)
            )
        }
        .onChange(of: swipeActionState) { oldValue, newValue in
            debugPrint("index \(itemIndex), old: \(oldValue), new: \(newValue)")
            if newValue == .activating {
                activeIndex = itemIndex
            }
        }
    }
    
    @ViewBuilder
    func actionButton(resetPosition: @escaping () -> ()) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(width: CGFloat(actions.count) * 100)
            .overlay(alignment: direction.alignment) {
                HStack(spacing: 0) {
                    ForEach(actions) { button in
                        Button {
                            Task {
                                isEnabled = false
                                resetPosition()
                                try? await Task.sleep(for: .seconds(0.25))
                                button.action()
                                try? await Task.sleep(for: .seconds(0.1))
                                isEnabled = true
                            }
                        } label: {
                            Image(systemName: button.icon)
                                .font(button.iconFont)
                                .foregroundStyle(button.iconTint)
                                .frame(width: 100)
                                .frame(maxHeight: .infinity)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .background(button.tint)
                        .rotationEffect(.init(degrees: direction == .leading ? 180 : 0))
                    }
                }
            }
    }
    
    nonisolated func scrollOffSet(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        
        return minX > 0 ? -minX : 0
    }
    
}

struct SwipeActionOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SwipeActionCustomTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask {
                GeometryReader {
                    let size = $0.size
                    
                    Rectangle()
                        .offset(y: phase == .identity ? 0 : -size.height)
                }
                .containerRelativeFrame(.horizontal)
            }
    }
}

enum SwipeActionState {
    case activating
    case inactivating
    
    static func initialState(oldScrollOffset: CGFloat, newScrollOffset: CGFloat, limit: CGFloat) -> Self {
        if newScrollOffset <= limit || oldScrollOffset > newScrollOffset {
            return .activating
        } else {
            return .inactivating
        }
    }
}

enum SwipeDirection {
    case leading
    case trailing
    
    var alignment: Alignment {
        switch self {
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}

struct SwipeActionModel: Identifiable {
    private(set) var id: UUID = .init()
    var tint: Color
    var icon: String
    var iconFont: Font = .title
    var iconTint: Color = .white
    var isEnabled: Bool = true
    var action: () -> ()
}

@resultBuilder
struct SwipeActionBuilder {
    static func buildBlock(_ components: SwipeActionModel...) -> [SwipeActionModel] {
        return components
    }
}

#Preview {
    ContentView(direction: .trailing)
}

