# Collection Sync and Local Search

The Discogs "All" folder (folder id `0`) is served from a local SwiftData index. Other folders load paginated releases from the Discogs API. Both paths are orchestrated by `CollectionStore`.

## Dual data paths

```mermaid
flowchart LR
    subgraph folderZero [Folder id 0 All]
        sync[CollectionSyncService]
        index[CollectionLocalIndex]
        items[folderZeroItems]
        sync --> index
        index --> items
    end

    subgraph otherFolders [Folders 1 and above]
        api[CachedFetcher]
        memory[releasesByFolderID]
        api --> memory
    end

    store[CollectionStore]
    store --> folderZero
    store --> otherFolders
```

| Folder | Source | Pagination | Offline |
| ------ | ------ | ---------- | ------- |
| `.zero` ("All") | `CollectionLocalIndex` | All items loaded from index | Yes, after sync |
| 1+ | Discogs API via `CachedFetcher` | 50 per page, infinite scroll | No (cached pages only) |

Primary files:

- [`CollectionSyncService.swift`](../DiscoScan/Data/CollectionSync/CollectionSyncService.swift)
- [`CollectionLocalIndex.swift`](../DiscoScan/Data/CollectionSync/CollectionLocalIndex.swift)
- [`LocalCollectionItem.swift`](../DiscoScan/Data/CollectionSync/LocalCollectionItem.swift)
- [`CollectionSyncMetadata.swift`](../DiscoScan/Data/CollectionSync/CollectionSyncMetadata.swift)
- [`CollectionSearchMatching.swift`](../DiscoScan/Data/CollectionSync/CollectionSearchMatching.swift)
- [`CollectionStore.swift`](../DiscoScan/Features/Collection/Store/CollectionStore.swift)
- [`CollectionListView.swift`](../DiscoScan/Features/Collection/Views/CollectionListView.swift)

## Sync pipeline

```mermaid
flowchart TD
    triggers["Sign-in / open All / foreground / pull-to-refresh"]
    store[CollectionStore]
    loadLocal[Show local index items first]
    service["CollectionSyncService.refresh(username, mode)"]
    decide{"force or count mismatch or unsealed or stale?"}
    begin[beginSyncGeneration]
    pages["Fetch pages via NetworkManagerProtocol"]
    upsert["upsertSynced batched per page"]
    verify{"synced == remoteTotal?"}
    sweep[sweep and seal]
    unsealed["incompleteSync leave unsealed"]
    triggers --> store
    store --> loadLocal
    store --> service
    service --> decide
    decide -->|no| idleNode[Emit idle]
    decide -->|yes| begin
    begin --> pages
    pages --> upsert
    upsert --> pages
    pages -->|last page| verify
    verify -->|yes| sweep
    verify -->|no| unsealed
```

### Sync triggers

| Trigger | Entry point |
| ------- | ----------- |
| Sign-in | `DiscoScanApp` → `ensureFolderZeroIndexReady()` |
| Open All folder | `CollectionListView.task` → `ensureFolderZeroIndexReady()` |
| Pull-to-refresh | `syncFolderZeroIndex(forceRefresh: true)` → `refresh(mode: .force)` |
| App foreground | `ensureFolderZeroIndexReady()` |
| Count mismatch | Local `fetchCount` ≠ remote All-folder count |
| Unsealed generation | Previous sync interrupted before sweep |
| Stale index | `lastSyncedAt` older than 24 hours (default) |

### Coalescing and cancellation

`CollectionSyncService` holds one in-flight task per username. Concurrent refreshes for the same user await the same task. `cancel(username:)` runs before the local index is cleared on logout or user switch.

Sync pagination uses `NetworkManagerProtocol` directly (not `CachedFetcher`), so failed pages never fall back to stale cached data.

### Progress phases

```swift
enum CollectionSyncPhase {
    case idle
    case checking
    case syncing(synced: Int, total: Int)
    case failed(String)
}
```

`CollectionStore` subscribes once for the app lifetime. On `.checking`, `folderZeroItems` enters refresh. Terminal `.idle` reloads items; `.failed` surfaces an error with Retry. `.checking` is emitted only when a sync will run.

### Error cases

| Error | Cause |
| ----- | ----- |
| `allFolderNotFound` | Folders response missing id `0` |
| `paginationFailed(page:message:)` | Network failure on a sync page |
| `indexWriteFailed(message:)` | SwiftData write failure during upsert |
| `incompleteSync(expected:received:)` | Pagination returned fewer items than the remote total; generation stays unsealed |

## Mark-and-sweep generations

Sync uses a generation counter in `CollectionSyncMetadata` per username:

```
beginSyncGeneration:
  if activeGeneration == sealedGeneration:
    activeGeneration += 1

upsertSynced(items, generation):
  batch upsert each item with syncGeneration = generation

upsertLive(item) / delete(instanceId):
  upsert or remove using meta.activeGeneration

sweep(keeping: generation):
  DELETE items WHERE syncGeneration < generation
  sealedGeneration = generation
  lastSyncedAt = now
```

**Why generations matter:**

- An interrupted sync leaves `activeGeneration > sealedGeneration` (`hasUnsealedGeneration`), forcing a retry even if counts match.
- Live mutations during sync tag rows with `activeGeneration`, so they survive the sweep.
- Remote removals are handled by sweep: items not re-upserted in the new generation are deleted.
- Before sweep, the service verifies the number of items received from pagination equals the remote All-folder count.

## LocalCollectionItem

Each synced release becomes a denormalized SwiftData row keyed by `(username, instanceId)` with a uniqueness constraint. Duplicate pressings share a `releaseId` but have distinct `instanceId` values.

| Field | Source |
| ----- | ------ |
| `instanceId`, `releaseId`, `folderId`, `dateAdded` | Discogs collection item |
| `dateAddedAt` | Parsed `Date` for sort order |
| `artistName`, `title`, `labelName`, `catno`, `year` | Release basic information |
| `searchableText` | Lowercased join of artist, title, label, catno, year |
| `syncGeneration` | Current sync generation tag |

Indexes: `(username, instanceId)`, `(username, dateAddedAt)`, `(username, syncGeneration)`.

### Display order

[`CollectionLocalIndex`](../DiscoScan/Data/CollectionSync/CollectionLocalIndex.swift) sorts by `dateAddedAt` descending (newest first). Sync fetches pages with default API sort (artist ascending), but display order comes from the local fetch descriptor.

## Local search

Search applies only to folder `.zero` in [`CollectionListView`](../DiscoScan/Features/Collection/Views/CollectionListView.swift) via `.searchable`.

### Searchable text

`CollectionReleaseItem.searchableText` and `CollectionSearchText.make` build:

```
[artist, title, label, catno, year?.description ?? ""]
  .joined(separator: " ")
  .lowercased()
```

Stored rows keep a denormalized `searchableText` column for consistency with sync writes.

### Matching algorithm

`CollectionSearchMatching.matches(query:searchableText:)`:

1. Trim and lowercase the query.
2. Split on whitespace into tokens.
3. Empty query matches all items.
4. Every token must appear as a substring in `searchableText` (order-independent).

No fuzzy matching, stemming, or word boundaries.

`CollectionStore.searchFolderZero(query:)` filters `folderZeroItems.value` in memory using the shared helpers above.

## Mutations

Add and delete keep the local index, in-memory folder lists, and folder counts in sync:

**Add release:**

1. Discogs API add
2. `localIndex.upsertLive(item)`
3. Prepend to `releasesByFolderID[folderId]` if loaded
4. `reloadFolderZeroItems()`
5. Refresh folder counts

**Delete release:**

1. Discogs API delete
2. `localIndex.delete(instanceId:)`
3. Filter item from `releasesByFolderID[folderId]`
4. `reloadFolderZeroItems()`
5. Refresh folder counts

## Loading semantics

`ensureFolderZeroIndexReady()` loads local items before contacting the network, so offline users see the last synced index immediately.

When local count is zero but a sync is pending, `folderZeroItems` stays in `.loading` (not `.loaded([])`) until sync completes or fails.

## Storage and schema changes

[`ModelContainerFactory`](../DiscoScan/Data/ModelContainerFactory.swift) bumps a `schemaVersion` in `UserDefaults`. When the version changes, the on-disk SwiftData store is deleted and recreated. The collection index, API cache, and sync metadata are all re-fetched on the next sync. Failed opens log to `os.Logger`, retry after delete, then fall back to an in-memory container as a last resort.

## Related docs

- [stores-and-state.md](stores-and-state.md) — `ResourceState` and `CollectionSyncPhase`
- [caching.md](caching.md) — API cache for folder 1+ (folder 0 sync bypasses `CachedFetcher`)
- [auth.md](auth.md) — Sync cancelled and index cleared on logout or user switch
