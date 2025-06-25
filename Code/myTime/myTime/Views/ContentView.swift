import SwiftUI

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                CustomSlider(selectedTab: $selectedTab)
                    .padding(.top, 20)
                TabView(selection: $selectedTab) {
                    MyTimeView()
                        .tag(0)
                        .environmentObject(taskManager)
                    AddTaskView()
                        .tag(1)
                        .environmentObject(taskManager)
                    ProfileView()
                        .tag(2)
                        .environmentObject(taskManager)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
    }
}