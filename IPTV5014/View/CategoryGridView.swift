import SwiftUI

struct CategoryGridView: View {
    @ObservedObject var viewModel: XtreamViewModel
    @ObservedObject var lang = LanguageManager.shared // <--- OSSERVA LA LINGUA
    
    @State private var searchText = ""
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 25)]

    var filteredCategories: [IPTVCategory] {
        if searchText.isEmpty { return viewModel.categories }
        else { return viewModel.categories.filter { $0.categoryName.localizedCaseInsensitiveContains(searchText) } }
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return lang.string(.goodMorning)
        case 12..<18: return lang.string(.goodAfternoon)
        default: return lang.string(.goodEvening)
        }
    }

    var body: some View {
        ZStack {
            LiquidBackground()
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(greeting).font(.caption).foregroundColor(.white.opacity(0.7)).textCase(.uppercase)
                        Text(lang.string(.welcome)).font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                    }
                    Spacer()
                    // Logout o Cambio Lingua (Opzionale qui, ma mettiamo logout)
                    Button(action: { withAnimation { viewModel.logout() } }) {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.8)).shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                    }
                }
                .padding(.horizontal).padding(.top, 10)
                
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.5))
                    TextField("", text: $searchText).placeholder(when: searchText.isEmpty) { Text(lang.string(.searchCat)).foregroundColor(.white.opacity(0.5)) }
                        .foregroundColor(.white).accentColor(.orange)
                    if !searchText.isEmpty { Button(action: { searchText = "" }) { Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.5)) } }
                }
                .padding().background(Color.black.opacity(0.3)).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2), lineWidth: 1)).padding(.horizontal)
                
                ScrollView(showsIndicators: false) {
                    if viewModel.categories.isEmpty && viewModel.isLoading {
                        ProgressView(lang.string(.loading)).tint(.white).padding(.top, 50)
                    } else if filteredCategories.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "magnifyingglass").font(.system(size: 60)).foregroundColor(.white.opacity(0.2))
                            Text(lang.string(.noCat)).font(.headline).foregroundColor(.white.opacity(0.5))
                        }.padding(.top, 100)
                    } else {
                        LazyVGrid(columns: columns, spacing: 25) {
                            ForEach(filteredCategories) { category in
                                NavigationLink(destination: ChannelListView(viewModel: viewModel, categoryId: category.categoryId, categoryName: category.categoryName)) {
                                    CategoryCard(title: category.categoryName)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding().padding(.bottom, 20)
                    }
                }
                .scrollContentBackground(.hidden).background(Color.clear)
            }
        }
        .navigationBarHidden(true)
        .onTapToDismissKeyboard()
    }
}

// ... Le struct CategoryCard e ScaleButtonStyle rimangono uguali ...
// Copiale dal file precedente se non le hai qui
struct CategoryCard: View {
    let title: String
    var iconColor: Color { [.blue, .purple, .orange, .pink, .teal, .cyan].randomElement() ?? .blue }
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle().fill(LinearGradient(colors: [iconColor.opacity(0.6), iconColor.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 70, height: 70).blur(radius: 10)
                Image(systemName: "tv.fill").font(.system(size: 30)).foregroundColor(.white).shadow(color: iconColor.opacity(0.5), radius: 5, x: 0, y: 0)
            }
            Text(title).font(.headline).fontWeight(.medium).foregroundColor(.white).multilineTextAlignment(.center).lineLimit(2).frame(maxWidth: .infinity)
        }
        .padding(20).frame(height: 160).superGlass(radius: 25, opacity: 0.5)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.94 : 1).animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
