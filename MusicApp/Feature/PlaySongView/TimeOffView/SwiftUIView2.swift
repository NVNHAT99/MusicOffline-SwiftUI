import SwiftUI

struct PlaceholderView: View {
    @State private var isAnimating = false
        
        var body: some View {
            HStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(self.isAnimating ?
                          LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3), Color.gray.opacity(0.5)]), startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5), Color.gray.opacity(0.3)]), startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 100, height: 100)
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true))
                    .onAppear {
                        self.isAnimating = true
                    }
                    .onDisappear {
                        self.isAnimating = false
                    }
                
                VStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 20)
                        .padding(.bottom, 5)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 20)
                        .padding(.bottom, 5)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 20)
                }
                .padding()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
            )
            .padding(.horizontal)
        }
}

struct ContentView2: View {
    var body: some View {
        List {
            ForEach(0..<10) { _ in
                PlaceholderView()
            }
        }
    }
}

struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView2()
    }
}
