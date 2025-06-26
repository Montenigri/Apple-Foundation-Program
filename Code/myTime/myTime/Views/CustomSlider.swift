import SwiftUI
struct CustomSlider: View {
    @Binding var selectedTab: Int
    let tabs = ["MyTime", "Add Task", "Progress"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    Text(tabs[index])
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == index ? .appBeige : .appBeige.opacity(0.4))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == index ? Color.appDarkBlue : Color.clear)
                        )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.appDarkBlue.opacity(0.3))
        )
        .padding(.horizontal, 20)
    }
}


