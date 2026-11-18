import SwiftUI

// MARK: - Couleurs & styles communs

extension Color {
    static let fvPurple = Color(red: 0.49, green: 0.33, blue: 0.98)
    static let fvPink = Color(red: 0.96, green: 0.32, blue: 0.60)
    static let fvBlue = Color(red: 0.20, green: 0.55, blue: 0.98)
}

let fvGradient = LinearGradient(colors: [.fvPurple, .fvPink],
                                startPoint: .topLeading, endPoint: .bottomTrailing)

/// Petite étiquette arrondie (plateforme, FR, iPhone…)
struct FVTag: View {
    let text: String
    var color: Color = .fvPurple

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.18))
            .clipShape(Capsule())
    }
}

/// Carré coloré avec une icône SF Symbols
struct IconTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 48

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [color, color.opacity(0.65)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func fvCard() -> some View { modifier(CardStyle()) }
}

/// Rangée de filtres horizontale
struct FilterChips: View {
    let items: [String]
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selection = item }
                    } label: {
                        Text(item)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background {
                                if selection == item {
                                    Capsule().fill(fvGradient)
                                } else {
                                    Capsule().fill(Color(.secondarySystemGroupedBackground))
                                }
                            }
                            .foregroundColor(selection == item ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

/// Titre de section
struct SectionTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.title3.weight(.bold))
            if let s = subtitle {
                Text(s).font(.footnote).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Étape numérotée d'un tuto
struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.footnote.weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(fvGradient))
            Text(text).font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// Bouton plein en dégradé
struct GradientLinkButton: View {
    let title: String
    let symbol: String
    let url: String

    var body: some View {
        if let u = URL(string: url) {
            Link(destination: u) {
                Label(title, systemImage: symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(fvGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

/// Lien de recherche web, pour les projets dont l'adresse officielle peut changer.
func search(_ q: String) -> String {
    "https://duckduckgo.com/?q=" + (q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)
}
