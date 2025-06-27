import SwiftUI

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showAddTask = false
    @State private var showProgress = false
    
    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header a bandiera
                HStack {
                    VStack(alignment: .leading) {
                        Text("MyTime") 
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Button(action: { showAddTask = true }) {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.appBeige)
                        }
                        Button(action: { showProgress = true }) {
                            Image(systemName: "chart.bar")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.appBeige)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Schermata principale: MyTimeView
                MyTimeView()
                    .environmentObject(taskManager)
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
                .environmentObject(taskManager)
        }
        .sheet(isPresented: $showProgress) {
            ProfileView() // O la tua view dei progressi
                .environmentObject(taskManager)
        }
    }
}
