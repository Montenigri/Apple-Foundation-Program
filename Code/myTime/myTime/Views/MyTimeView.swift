import SwiftUI

struct MyTimeView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedTask: Task?
    
    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Fixed Header
                VStack(alignment: .leading, spacing: 5) {
                    Text(currentMonth())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appBeige)
                    
                    HStack {
                        Text(currentWeekday())
                            .font(.headline)
                            .foregroundColor(.appBeige)
                        
                        Text(currentDay())
                            .font(.headline)
                            .foregroundColor(.appBeige)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Tasks ScrollView
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedTasks()) { task in
                            TaskRowView(task: task) {
                                selectedTask = task
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task){
                selectedTask = nil
            }
            .environmentObject(taskManager)
        }
    }
    
    private func sortedTasks() -> [Task] {
        return taskManager.tasks.sorted { $0.startTime < $1.startTime }
    }
    
    private func currentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: Date())
    }
    
    private func currentWeekday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: Date())
    }
    
    private func currentDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }
}