# Smart Ledger Form Tokens

This document defines the Smart Ledger style tokens used for input fields across the app.

## Geometry
- Field height: 56dp (single-line input)
- Corner radius: 12px (use 12–16 for larger containers)
- Inner padding: 16px horizontal, 12px vertical
- Icon size: 20–24px

## Colors
- Surface (field background): #F2F4F8
- Border: #E0E3E7
- Focus outline / accent: #2F6DA4
- Error: #D9534F
- Text primary: #111827
- Label / hint: #6B7280

## Typography
- Label: 12sp, weight: regular
- Value text: 14–16sp, weight: regular/medium
- Error/help text: 12sp, weight: regular

## Elevation / Shadow
- Subtle elevation: elevation 1 or BoxShadow(blurRadius: 6, color: rgba(0,0,0,0.04))

## Interaction
- Focus animation: 120ms ease (AnimatedContainer) for outline and shadow
- Ripple on icons / buttons: standard Material ripple
- Touch targets: min 44×44dp for actionable icons/buttons

## Accessibility
- Provide `semanticsLabel` for each input when visually labeled text is not sufficient
- Ensure contrast ratio >= 4.5:1 for primary text

## Examples
- Single-line input: 56dp high, left label small (12sp), placeholder hint removes when value present
- Two-column layout: ensure equal heights and vertical center alignment

