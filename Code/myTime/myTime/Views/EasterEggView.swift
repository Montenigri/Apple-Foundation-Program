import SwiftUI
import WebKit

struct EasterEggView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            WebView(url: URL(string: "https://www.youtube.com/embed/ceOwlHnVCqo")!)
                .navigationTitle("🎉 Easter Egg 🎉")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
