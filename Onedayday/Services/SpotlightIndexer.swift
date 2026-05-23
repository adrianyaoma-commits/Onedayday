import CoreSpotlight
import AppKit

enum SpotlightIndexer {
    private static let domain = "com.onedayday.tasks"

    static func index(_ item: TodoItem) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = item.name
        attributeSet.contentDescription = item.description ?? ""
        attributeSet.keywords = [item.name, item.device, item.important ? "important" : "", item.urgent ? "urgent" : ""]

        let searchableItem = CSSearchableItem(
            uniqueIdentifier: "com.onedayday.task.\(item.id)",
            domainIdentifier: domain,
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { error in
            if let error = error { print("Spotlight index error: \(error)") }
        }
    }

    static func deindex(_ item: TodoItem) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["com.onedayday.task.\(item.id)"]) { error in
            if let error = error { print("Spotlight deindex error: \(error)") }
        }
    }

    static func deindexAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domain]) { error in
            if let error = error { print("Spotlight deindexAll error: \(error)") }
        }
    }
}
