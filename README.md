# ListyWisty - A MinimaList App

<img src="ListyWisty/Assets.xcassets/AppIcon.appiconset/listywisty-logo.png" alt="listy wisty boy" width="400"/>

ListyWisty is a basic iOS application built with SwiftUI and powered by AI to help users create and manage shopping lists or checklists.

## Features

*   Create multiple shopping or to-do lists.
*   Add items to each list with the help of powerful LLMs.
*   Mark items as completed (checked off).
    *   Checked items are visually distinct (strikethrough, greyed out, green checkmark).
    *   Checked items automatically move to the bottom of the list, sorted by recently checked.
*   Delete individual items from a list (swipe-to-delete).
*   Delete entire lists (with confirmation).
*   Edit item names and optionally add price, quantity and units.
*   Edit list titles.
*   Persistence: Lists and items are saved locally between app launches.
*   Collaboration: Send lists to and receive lists from your friends!
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
    *   Tap the "Create" button at the bottom to create a listy.
    *   Enter a name in the alert and tap "Create".
    *   Tap on a list name to view its details.
*   **List Detail Screen:**
    *   See items in the list (unchecked first, then checked).
    *   Tap the "+" button section at the bottom to add a new item.
    *   Tap the circle next to an item (or swipe the item row to the right) to toggle its checked status.
    *   Tap an item's text to edit its name and price. Tap "Done" to save changes or "Cancel" to discard them.
    *   Swipe left on an item row to reveal the "Delete" button.
    *   Tap the trash can icon in the top-right toolbar to delete the entire list (confirmation required).
    *   Tap the pencil icon in the top-right toolbar to edit the list's title.
    *   Tap the Send button to share your listy with anyone.

## Technologies Used

*   SwiftUI
*   Swift 5.7+
*   Xcode 14+
*   iOS 16+ (Recommended)
*   gemini-2.5-pro-preview-03-25
