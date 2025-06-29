import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingInterests = false
    @Environment(\.dismiss) private var dismiss
    
    // Stato per forzare l'aggiornamento del grafico
    @State private var chartRefreshTrigger = UUID()
    
    // Modalità visualizzazione grafico
    @State private var isWeeklyView = true

    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header con pulsante chiudi
                    headerSection
                    
                    // Titolo
                    titleSection
                    
                    // Sezione grafico progressi
                    progressChartSection
                    
                    // Sezione progressi originale
                    dailyProgressSection
                    
                    // Sezione sonno
                    sleepSection
                    
                    // Sezione lavoro
                    workSection
                    
                    // Pulsante interessi
                    interestsButton
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingInterests) {
            InterestsView()
                .environmentObject(taskManager)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.appBeige)
                }
            }
        }
        // Osserva i cambiamenti nei task completati per aggiornare il grafico
        .onChange(of: taskManager.profile.completedTasks) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                chartRefreshTrigger = UUID()
            }
        }
        .onChange(of: isWeeklyView) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                chartRefreshTrigger = UUID()
            }
        }
    }
    
    // MARK: - Computed Properties per Target Dinamico
    
    private func dailyProgressStat(value: String, label: String) -> some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appLightBlue)
            Text(label)
                .font(.caption)
                .foregroundColor(.appBeige)
                .multilineTextAlignment(.center)
        }
    }
    
    
    
    // Calcola i task completati nella giornata corrente
    private var todayCompletedTasks: Int {
        let today = Date()
        let tasksForToday = taskManager.getTasksForDate(today)
        return tasksForToday.filter { $0.isCompleted }.count
    }

    /// Calcola le ore totali impiegate nei task completati nella giornata corrente
    private var todayTotalHours: Double {
        let today = Date()
        let tasksForToday = taskManager.getTasksForDate(today)
        let completedTasksToday = tasksForToday.filter { $0.isCompleted }
        return completedTasksToday.reduce(0) { $0 + $1.estimatedTime }
    }
    
    
    
    /// Calcola i task completati per il periodo corrente (settimana o mese)
    private var currentPeriodCompletedTasks: Int {
        if isWeeklyView {
            return getCompletedTasksForCurrentWeek()
        } else {
            return getCompletedTasksForCurrentMonth()
        }
    }
    
    /// Target per il periodo corrente
    private var currentPeriodTarget: Int {
        return isWeeklyView ? 35 : 100 // 35 per settimana, 100 per mese
    }
    
    /// Percentuale di completamento per il periodo corrente
    private var currentPeriodPercentage: Double {
        return Double(currentPeriodCompletedTasks) / Double(currentPeriodTarget) * 100
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.appBeige)
                    .padding(.top, 8)
                    .padding(.trailing, 8)
            }
        }
        .zIndex(1)
    }
    
    private var titleSection: some View {
        VStack(spacing: 15) {
            Text("Progressi")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.appBeige)
        }
    }
    
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            progressHeader
            
            // Toggle per modalità visualizzazione
            viewModeToggle
            
            // Progress Chart con trigger per l'aggiornamento
            ProgressChart(
                progressData: isWeeklyView ? generateWeeklyProgressData() : generateMonthlyProgressData(),
                refreshTrigger: chartRefreshTrigger,
                isWeeklyView: isWeeklyView
            )
            .frame(height: 120)
            .padding(.top, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkBlue.opacity(0.2))
        )
    }
    
    private var viewModeToggle: some View {
        HStack {
            Text(isWeeklyView ? "Visualizzazione Settimanale" : "Visualizzazione Mensile")
                .font(.caption)
                .foregroundColor(.appBeige.opacity(0.8))
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isWeeklyView.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isWeeklyView ? "calendar.badge.clock" : "calendar")
                        .font(.caption)
                    Text(isWeeklyView ? "Mensile" : "Settimanale")
                        .font(.caption)
                }
                .foregroundColor(.appBeige)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.appBeige.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    private var progressHeader: some View {
        HStack {
            progressStats
            Spacer()
            updateButton
        }
    }
    
    private var progressStats: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Target \(isWeeklyView ? "Settimanale" : "Mensile")")
                .font(.subheadline)
                .foregroundColor(.appBeige.opacity(0.7))
            
            progressNumbers
            progressPercentage
        }
    }
    
    private var progressNumbers: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text("\(currentPeriodCompletedTasks)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.appBeige)
            
            Text("/ \(currentPeriodTarget)")
                .font(.title3)
                .foregroundColor(.appBeige.opacity(0.6))
                .padding(.bottom, 4)
        }
    }
    
    private var progressPercentage: some View {
        HStack(spacing: 4) {
            Text(String(format: "%.0f%%", currentPeriodPercentage))
                .font(.caption)
                .foregroundColor(.appBeige.opacity(0.8))
            
            let hours = calculateHoursForPeriod()
            Text("\(hours)h")
                .font(.caption)
                .foregroundColor(.appBeige.opacity(0.6))
        }
    }
    
    private var updateButton: some View {
        Button("Aggiorna") {
            // Forza l'aggiornamento del grafico
            withAnimation(.easeInOut(duration: 0.5)) {
                chartRefreshTrigger = UUID()
            }
        }
        .font(.caption)
        .foregroundColor(.appBeige)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appBeige.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var dailyProgressSection: some View {
        VStack(spacing: 15) {
            Text("Progressi di oggi")
                .font(.headline)
                .foregroundColor(.appBeige)
            
            HStack {
                dailyProgressStat(
                    value: "\(todayCompletedTasks)",
                    label: "Task completati oggi"
                )
                
                Spacer()
                
                dailyProgressStat(
                    value: String(format: "%.1f", todayTotalHours),
                    label: "Ore impiegate oggi"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appDarkBlue.opacity(0.3))
            )
        }
    }
    
    private func progressStat(value: String, label: String) -> some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appLightBlue)
            Text(label)
                .font(.caption)
                .foregroundColor(.appBeige)
        }
    }
    
    private var sleepSection: some View {
        timeSection(
            title: "Sezione Sonno",
            startTime: $taskManager.profile.sleepStart,
            endTime: $taskManager.profile.sleepEnd
        )
    }
    
    private var workSection: some View {
        timeSection(
            title: "Sezione Lavoro",
            startTime: $taskManager.profile.workStart,
            endTime: $taskManager.profile.workEnd
        )
    }
    
    private func timeSection(title: String, startTime: Binding<Date>, endTime: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.appBeige)
            
            HStack {
                timePicker(label: "Inizio", selection: startTime)
                Spacer()
                timePicker(label: "Fine", selection: endTime)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkBlue.opacity(0.3))
        )
    }
    
    private func timePicker(label: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.appBeige)
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
        }
    }
    
    private var interestsButton: some View {
        Button(action: {
            showingInterests = true
        }) {
            Text("Seleziona Interessi")
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue))
                .foregroundColor(.appBeige)
        }
        .padding() // Padding esterno, come nel bottone "Aggiungi interessi"
    }


    
    // MARK: - Helper Functions per Calcoli Periodo
    
    /// Calcola i task completati nella settimana corrente
    private func getCompletedTasksForCurrentWeek() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // Trova l'inizio della settimana corrente (lunedì)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return 0
        }
        
        var completedCount = 0
        
        // Conta i task completati per ogni giorno della settimana corrente
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            
            // Non contare i giorni futuri
            if date > today { break }
            
            let tasksForDay = taskManager.getTasksForDate(date)
            completedCount += tasksForDay.filter { $0.isCompleted }.count
        }
        
        return completedCount
    }
    
    /// Calcola i task completati nel mese corrente
    private func getCompletedTasksForCurrentMonth() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else {
            return 0
        }
        
        let monthStart = monthInterval.start
        let monthEnd = min(monthInterval.end, today) // Non contare i giorni futuri
        
        var completedCount = 0
        var currentDate = monthStart
        
        while currentDate <= monthEnd {
            let tasksForDay = taskManager.getTasksForDate(currentDate)
            completedCount += tasksForDay.filter { $0.isCompleted }.count
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return completedCount
    }
    
    /// Calcola le ore per il periodo corrente
    private func calculateHoursForPeriod() -> Int {
        if isWeeklyView {
            return calculateHoursForCurrentWeek()
        } else {
            return calculateHoursForCurrentMonth()
        }
    }
    
    private func calculateHoursForCurrentWeek() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return 0
        }
        
        var totalHours = 0.0
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            if date > today { break }
            
            let tasksForDay = taskManager.getTasksForDate(date)
            let completedTasks = tasksForDay.filter { $0.isCompleted }
            totalHours += completedTasks.reduce(0) { $0 + $1.estimatedTime }
        }
        
        return Int(totalHours)
    }
    
    private func calculateHoursForCurrentMonth() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else {
            return 0
        }
        
        let monthStart = monthInterval.start
        let monthEnd = min(monthInterval.end, today)
        
        var totalHours = 0.0
        var currentDate = monthStart
        
        while currentDate <= monthEnd {
            let tasksForDay = taskManager.getTasksForDate(currentDate)
            let completedTasks = tasksForDay.filter { $0.isCompleted }
            totalHours += completedTasks.reduce(0) { $0 + $1.estimatedTime }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return Int(totalHours)
    }
    
    // MARK: - Data Generation
    
    private func generateWeeklyProgressData() -> [ProgressDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var dataPoints: [ProgressDataPoint] = []
        
        // Trova l'inizio della settimana corrente (lunedì)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        
        // Genera dati per 7 giorni della settimana
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? today
            let dayName = getDayAbbreviation(from: date)
            
            // Calcola i task completati per questo giorno
            let tasksForDay = taskManager.getTasksForDate(date)
            let completedTasksForDay = tasksForDay.filter { $0.isCompleted }.count
            
            dataPoints.append(ProgressDataPoint(
                period: dayName,
                value: Double(completedTasksForDay),
                date: date
            ))
        }
        
        return dataPoints
    }
    
    
    
    
    
  
    // MARK: - Data Generation - VERSIONI CORRETTE

    private func generateMonthlyProgressData() -> [ProgressDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [ProgressDataPoint] = []
        
        // Genera dati per gli ultimi 12 mesi
        for i in 0..<12 {
            let rawDate = calendar.date(byAdding: .month, value: -i, to: now) ?? now
            let date = calendar.date(from: calendar.dateComponents([.year, .month], from: rawDate)) ?? rawDate
            
            let monthName = getMonthAbbreviation(from: date)
            
            // Calcola i task completati reali per ogni mese
            let completedTasksForMonth = getCompletedTasksForMonth(date)
            
            dataPoints.append(ProgressDataPoint(
                period: monthName,
                value: Double(completedTasksForMonth),
                date: date
            ))
        }
        
        return dataPoints.reversed()
    }
    
    
    
    // ALTERNATIVA: Se vuoi contare solo i giorni fino a oggi per il mese corrente
    private func getCompletedTasksForMonthUpToToday(_ date: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return 0
        }
        
        let monthStart = monthInterval.start
        // Per il mese corrente, limita alla data odierna
        let monthEnd = calendar.isDate(date, equalTo: now, toGranularity: .month) ?
            min(monthInterval.end, now) : monthInterval.end
        
        let tasksForMonth = taskManager.tasks.filter { task in
            let isInMonth = task.startTime >= monthStart && task.startTime < monthEnd
            return isInMonth && task.isCompleted
        }
        
        return tasksForMonth.count
    }
    
    
    private func getDayAbbreviation(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
    
    private func getMonthAbbreviation(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
    
    // VERSIONE CORRETTA della funzione getCompletedTasksForMonth
    
    
    
    
    private func getCompletedTasksForMonth(_ date: Date) -> Int {
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return 0
        }
        
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        let today = Date()
        
        // Per il mese corrente, non contare oltre oggi
        let effectiveMonthEnd = calendar.isDate(date, equalTo: today, toGranularity: .month) ?
            min(monthEnd, today) : monthEnd
        
        var completedCount = 0
        var currentDate = monthStart
        
        // Scorri giorno per giorno come nella funzione che funziona
        while currentDate < effectiveMonthEnd {
            let tasksForDay = taskManager.getTasksForDate(currentDate)
            completedCount += tasksForDay.filter { $0.isCompleted }.count
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return completedCount
    }
    


}

// MARK: - Supporting Types

struct ProgressDataPoint: Identifiable, Equatable {
    let id = UUID()
    let period: String // Giorno della settimana o mese
    let value: Double
    let date: Date
    
    static func == (lhs: ProgressDataPoint, rhs: ProgressDataPoint) -> Bool {
        return lhs.period == rhs.period && lhs.value == rhs.value
    }
}

struct ProgressChart: View {
    let progressData: [ProgressDataPoint]
    let refreshTrigger: UUID
    let isWeeklyView: Bool
    
    var body: some View {
        CustomLineChart(data: progressData, isWeeklyView: isWeeklyView)
            .id(refreshTrigger) // Forza la ricreazione del grafico quando cambia il trigger
    }
}

struct CustomLineChart: View {
    let data: [ProgressDataPoint]
    let isWeeklyView: Bool
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Griglia di sfondo
                chartGrid(in: geometry)
                chartLine(in: geometry)
                chartPoints(in: geometry)
                chartLabels(in: geometry)
            }
        }
        .padding(.bottom, 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Chart Components
    
    private func chartGrid(in geometry: GeometryProxy) -> some View {
        let maxValue = max(data.map(\.value).max() ?? 1, 1)
        let stepY = (geometry.size.height - 20) / CGFloat(maxValue)
        
        return Path { path in
            // Linee orizzontali per i valori
            for i in 0...Int(maxValue) {
                let y = geometry.size.height - 20 - (CGFloat(i) * stepY)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: geometry.size.width, y: y))
            }
        }
        .stroke(Color.appBeige.opacity(0.1), lineWidth: 0.5)
    }
    
    private func chartLine(in geometry: GeometryProxy) -> some View {
        let maxValue = max(data.map(\.value).max() ?? 1, 1)
        let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
        let stepY = (geometry.size.height - 20) / CGFloat(maxValue)
        
        return Path { path in
            for (index, point) in data.enumerated() {
                let x = CGFloat(index) * stepX
                let y = geometry.size.height - 20 - (CGFloat(point.value) * stepY)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .trim(from: 0, to: animationProgress)
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [.appLightBlue, .appBeige]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func chartPoints(in geometry: GeometryProxy) -> some View {
        let maxValue = max(data.map(\.value).max() ?? 1, 1)
        let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
        let stepY = (geometry.size.height - 20) / CGFloat(maxValue)
        
        return ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
            let x = CGFloat(index) * stepX
            let y = geometry.size.height - 20 - (CGFloat(point.value) * stepY)
            
            ZStack {
                Circle()
                    .fill(Color.appBeige)
                    .frame(width: 8, height: 8)
                
                Circle()
                    .fill(Color.appLightBlue)
                    .frame(width: 4, height: 4)
            }
            .position(x: x, y: y)
            .scaleEffect(animationProgress)
            .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: animationProgress)
        }
    }
    
    private func chartLabels(in geometry: GeometryProxy) -> some View {
        let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
        
        return ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
            let shouldShowLabel = isWeeklyView || index % 2 == 0 || data.count <= 6
            
            if shouldShowLabel {
                let x = CGFloat(index) * stepX
                
                VStack(spacing: 2) {
                    Text(point.period)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.appBeige.opacity(0.9))
                    
                    Text("\(Int(point.value))")
                        .font(.caption2)
                        .foregroundColor(Color.appLightBlue.opacity(0.8))
                }
                .position(x: x, y: geometry.size.height + 10)
                .opacity(animationProgress)
            }
        }
    }
}
