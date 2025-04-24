# ChessApp Style Guide

This document outlines the visual style and design guidelines for the ChessApp.

## 1. Color Palette

*   **Primary:** `#0A7AFF` (Apple's standard Blue - good for interactive elements)
*   **Secondary:** `#5AC8FA` (Apple's standard Teal - for accents)
*   **Background:** `#F2F2F7` (System Gray 6 - light background)
*   **Surface:** `#FFFFFF` (White - for cards, sheets, elevated surfaces)
*   **Text/On Primary:** `#FFFFFF` (White)
*   **Text/On Secondary:** `#FFFFFF` (White)
*   **Text/On Background:** `#1C1C1E` (System Gray 1 - primary text)
*   **Text/On Surface:** `#1C1C1E` (System Gray 1 - primary text on white)
*   **Text/Secondary:** `#8E8E93` (System Gray - for less important text)
*   **Error:** `#FF3B30` (System Red - for errors and destructive actions)
*   **Board Light Squares:** `#E1E1E1` (Light Gray)
*   **Board Dark Squares:** `#6D8A96` (Desaturated Blue/Gray)
*   **Board Highlight/Valid Move:** `rgba(10, 122, 255, 0.3)` (Translucent Primary Blue)
*   **Board Selection:** `rgba(90, 200, 250, 0.5)` (Translucent Secondary Teal)
*   **Board Check Highlight:** `rgba(255, 59, 48, 0.4)` (Translucent System Red)

## 2. Typography

*   **Primary Font:** SF Pro (System Font)
*   **Headings:**
    *   H1 (Large Title): 34pt, Bold
    *   H2 (Title 1): 28pt, Bold
    *   H3 (Title 2): 22pt, Bold
*   **Body:** 17pt, Regular
*   **Subheadline:** 15pt, Regular
*   **Buttons:** 17pt, Semibold, Uppercase (for prominent buttons if desired, otherwise Sentence case)
*   **Captions/Labels:** 12pt, Regular

## 3. Spacing & Layout

*   **Base Unit:** 8pt
*   **Padding:**
    *   Small: 8pt (1 * base unit)
    *   Medium: 16pt (2 * base unit)
    *   Large: 24pt (3 * base unit)
*   **Margins:** Standard 16pt horizontal margins for screen content.
*   **Corner Radius:** 10pt (Standard rounded corners)

## 4. Iconography

*   Use **SF Symbols** primarily for consistency with the platform. Ensure appropriate weights are used to match accompanying text.

## 5. Components

*   **Buttons:**
    *   Primary: Solid background (Primary color), Text (Text/On Primary), 10pt corner radius, Medium padding.
    *   Secondary: Solid background (Secondary color or a light gray), Text (Text/On Secondary or Primary), 10pt corner radius, Medium padding.
    *   Text: No background, Text (Primary color).
*   **Text Fields:** Standard iOS style with clear background/border, 10pt corner radius, Medium padding. Use Error color for border/tint when invalid.
*   **Board Elements:**
    *   Pieces: High-contrast vector style (ensure clear distinction between black/white pieces on both light/dark squares).
    *   Square Highlighting: Use defined board highlight colors (Valid Move, Selection, Check).

## 6. Animations & Transitions

*   Use standard SwiftUI animations (`.easeInOut`, `.spring()`) for transitions.
*   Keep animations purposeful and brief (e.g., ~0.2-0.3 seconds). 