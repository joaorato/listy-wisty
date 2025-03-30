# ListyWisty - Simple Shopping List App

ListyWisty is a basic iOS application built with SwiftUI to help users create and manage simple shopping lists or checklists.

## Features

*   Create multiple shopping lists.
*   Add items to each list.
*   Mark items as completed (checked off).
    *   Checked items are visually distinct (strikethrough, greyed out, green checkmark).
    *   Checked items automatically move to the bottom of the list, sorted by recently checked.
*   Delete individual items from a list (swipe-to-delete).
*   Delete entire lists (with confirmation).
*   Edit item names and optionally add a price.
*   Edit list titles.
*   Persistence: Lists and items are saved locally between app launches.
*   Basic Dark Mode support.

## Setup

1.  Clone or download this repository.
2.  Open the `.xcodeproj` file in Xcode (requires Xcode 14+ or later, targeting iOS 16+ or later recommended due to SwiftUI features used).
3.  Connect a physical iPhone/iPad or select an iOS Simulator.
4.  If running on a physical device for the first time:
    *   Select your Apple ID under `Signing & Capabilities` for the `ListyWisty` target (a free account is sufficient for personal device testing).
    *   Trust the developer certificate on your device (`Settings` > `General` > `VPN & Device Management`).
5.  Build and run the app (`Cmd + R`).

## Usage

*   **Main Screen:**
    *   See existing lists.
    *   Tap the "Create List" button at the bottom.
    *   Enter a name in the alert and tap "Create".
    *   Tap on a list name to view its details.
*   **List Detail Screen:**
    *   See items in the list (unchecked first, then checked).
    *   Tap the "+" button section at the bottom to add a new item.
    *   Tap the circle next to an item (or the item row) to toggle its checked status.
    *   Tap an item's text to edit its name and price. Tap "Done" or press Return to save changes.
    *   Swipe left on an item row to reveal the "Delete" button.
    *   Tap the trash can icon in the top-right toolbar to delete the entire list (confirmation required).
    *   Tap the pencil icon in the top-right toolbar to edit the list's title.

## Technologies Used

*   SwiftUI
*   Swift 5.7+
*   Xcode 14+
*   iOS 16+ (Recommended)
