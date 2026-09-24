# DiscoScan

A native iOS app for vinyl collectors. DiscoScan connects to your [Discogs](https://www.discogs.com) account so you can search releases, browse your collection, manage your want list, and identify records by barcode or sleeve photo.

Built with SwiftUI, targeting iOS 26.5+. The app uses a dark-only color scheme with a shared design token layer and reusable UI components.

## Features

### Search

- **Text search** — Search artists, albums, and labels from the system search tab. Recent queries are saved and suggested as you type.
- **Barcode scanning** — Scan a record's barcode with the device camera. When Discogs returns a single release match, the app opens the release detail automatically.
- **Sleeve photo identification** — Capture or pick a sleeve photo; Google Gemini extracts artist, title, and catalog number, then runs a Discogs search. Works best with readable text or recognizable artwork.

### Library

- **Collection folders** — Browse Discogs collection folders with item counts. Pull to refresh.
- **Folder contents** — View releases in a folder and swipe to remove items from your collection.
- **Create folders** — Add custom collection folders from the Library tab.
- **Want list** — Toggle between Collection and Wantlist. Add or remove releases from the want list on release detail or via swipe-to-delete.

### Release details

- Artwork, artist, title, year, country, and release date
- Format, label, genres & styles
- Full tracklist with durations
- Community stats (have / want / ratings)
- **Add to collection** — Pick a folder and add the release
- **Want list toggle** — Heart button to add or remove

### Account

- **Discogs OAuth** — Sign in with your Discogs account. Tokens are stored in the Keychain.
- **Profile tab** — Avatar, display name, location, collection size, member since, and bio from your Discogs profile. Pull to refresh; sign out from the toolbar.

## Architecture

DiscoScan follows a protocol-oriented MV pattern:

| Layer          | Description                                                                                                                                        |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Views**      | SwiftUI views bind directly to `@Observable` stores                                                                                                |
| **Stores**     | `CollectionStore`, `WantListStore`, `ReleaseStore`, `SearchStore`, `ProfileStore`, `AuthSession` — async loading via `ResourceState<T>`            |
| **Async UI**   | Screen-level loading/error/empty states via `ResourceContainerView`; paginated release lists via `PaginatedReleaseListView`                        |
| **Design**     | Static tokens in `Design/` (`AppSpacing`, `AppTypography`, `AppIconSize`); shared components in `Views/` (rows, artwork, brand icon, empty states) |
| **Networking** | Typed `EndpointProtocol` structs via [NetworkKit](https://github.com/DamienThomp/NetworkKit)                                                       |
| **Caching**    | SwiftData-backed `CachedFetcher` with TTL policies per data type                                                                                   |
| **Navigation** | Typed `AppRoute` + `NavigationPath` via `AppRouter`                                                                                                |

Key integrations:

- **Discogs API** — OAuth 1.0a, rate-limit handling, collection/wantlist/search/release endpoints
- **Google Gemini** — Sleeve identification from JPEG photos

## Requirements

- Xcode with iOS 26.5 SDK
- iPhone or simulator with camera (for barcode / photo features)
- Discogs developer account ([register here](https://www.discogs.com/settings/developers))
- Google Gemini API key (for sleeve photo identification)

## Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/DamienThomp/DiscoScan.git
   cd DiscoScan
   ```

2. **Configure secrets**

   Copy the example config and fill in your credentials:

   ```bash
   cp DiscoScan/Configuration/Secrets.xcconfig.example DiscoScan/Configuration/Secrets.xcconfig
   ```

   Edit `Secrets.xcconfig`:

   | Key                       | Description                                                |
   | ------------------------- | ---------------------------------------------------------- |
   | `DISCOGS_CONSUMER_KEY`    | Discogs app consumer key                                   |
   | `DISCOGS_CONSUMER_SECRET` | Discogs app consumer secret                                |
   | `DISCOGS_CALLBACK_URL`    | OAuth callback — use `discoscan:/oauth/callback`           |
   | `DISCOGS_USER_AGENT`      | User-Agent string (include contact URL per Discogs policy) |
   | `GEMINI_API_KEY`          | Google Gemini API key                                      |
   | `GEMINI_MODEL`            | Model name (default: `gemini-3.5-flash-lite`)              |

   In your Discogs developer settings, set the callback URL to `discoscan:/oauth/callback`.

3. **Open in Xcode**

   Open `DiscoScan.xcodeproj`. Xcode resolves the private NetworkKit Swift Package dependency automatically (requires repository access).

4. **Build and run**

   Select an iPhone simulator or device and run (⌘R). Sign in with Discogs on first launch.

## Project structure

```
DiscoScan/
├── App/              # AppDependencies, AppRouter
├── Auth/             # OAuth, Keychain token storage
├── Configuration/    # DiscogsConfig, GeminiConfig, Secrets.xcconfig
├── Data/             # CachedFetcher, RecentSearchStore
├── Design/           # Spacing, typography, and icon size tokens
├── Environment/      # Store and service environment keys
├── Features/
│   ├── Auth/         # Login
│   ├── Collection/   # Folders, releases, create folder
│   ├── Navigation/   # AppRoute stack and destinations
│   ├── Profile/      # Profile store and My Profile screen
│   ├── Release/      # Release detail, folder picker
│   ├── Root/         # RootView, MainTabView
│   ├── Search/       # Search, barcode, image identification
│   └── WantList/     # Want list
├── Models/           # Decodable domain types
├── Networking/       # Endpoints, interceptors, Gemini client
└── Views/            # Shared UI across features
    ├── AsyncState/   # ResourceContainerView, loading/error/empty states
    ├── Brand/        # BrandDiscIcon
    ├── Cells/        # Release rows, tracklist, format tags
    ├── Detail/       # Detail section blocks
    ├── Image/        # ReleaseArtworkView, AvatarView
    └── Text/         # Secondary footnote text
```

## Testing

The project uses [Swift Testing](https://developer.apple.com/documentation/testing). Run tests in Xcode (⌘U) or via CLI:

```bash
xcodebuild test -scheme DiscoScan -destination 'platform=iOS Simulator,name=iPhone 17'
```

Test coverage includes stores (collection, want list, release, search, profile), OAuth, caching, rate limiting, search endpoints, and Gemini sleeve identification.

## Permissions

The app requests:

- **Camera** — Barcode scanning and sleeve photos
- **Photo Library** — Choosing an existing sleeve photo

## License

MIT — see [LICENSE](LICENSE).
