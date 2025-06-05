# Tim App Wireframes

This directory contains detailed text wireframes for all 6 core screens of the Tim app.

## Screen Overview

1. **01_onboarding_screen.txt** - 3-page onboarding flow introducing Tim and the concept
2. **02_onboarding_flow.txt** - Continuation of onboarding (screens 2-3)
3. **03_login_register.txt** - Authentication screen with subtle Tim presence
4. **04_account_overview.txt** - List of connected accounts with status indicators
5. **05_integrated_account_flow.txt** - Plaid connection → immediate categorization flow
6. **06_widget_preview.txt** - Shows user their actual widget with real data
7. **07_functional_dashboard.txt** - 2-tab dashboard (Dashboard + Settings)

## User Flow Summary

```
Onboarding → Login → Account Overview → Connect Accounts → Categorize → Widget Preview → Dashboard
```

## Design Principles

- **Tim as Widget Setup Tool**: Focused on getting users to a working widget quickly
- **Minimal Re-engagement**: Most users will primarily use the widget, not the app
- **Tim's Presence**: Key moments only (onboarding, login corner, dashboard encouragement)
- **2-Tab Navigation**: Simplified from current 4-tab structure
- **Integrated Flow**: Plaid connection immediately followed by categorization

## How to Edit

Each wireframe file contains:
- **ASCII art layout** showing screen structure
- **Element descriptions** in brackets [like this]
- **Notes section** explaining design decisions
- **Measurements** for Tim character sizing

Feel free to:
- Modify layouts by editing the ASCII art
- Change element positions and sizes
- Update content and messaging
- Add or remove features
- Adjust Tim's presence and messaging

## Brand Guidelines

- **Background**: Cream (#FDFBD4)
- **Primary**: Black text and borders
- **Cards**: White background with black borders
- **Tim Character**: Your 600x600 PNG in various sizes
- **Typography**: Tim design system (casual sans serif)

## Implementation Priority

**Must Have (Weekend MVP):**
- Onboarding flow (screens 1-2)
- Enhanced login (screen 3)
- Account overview (screen 4)
- Integrated account flow (screen 5)
- Widget preview (screen 6)
- Functional dashboard (screen 7)

**Current vs. New:**
- Login/Register: ✅ Exists, needs Tim branding update
- Dashboard: ✅ Exists, needs simplification to 2-tab structure
- Account management: 🔄 Need to integrate Plaid + Category flows
- Onboarding: ❌ New screen needed
- Widget preview: ❌ New screen needed

## Notes

- All measurements are suggestions and can be adjusted
- Tim character sizing: Large (onboarding) → Medium (dashboard) → Small (login corner)
- Focus on widget setup completion over ongoing engagement
- Real user data in widget preview builds confidence 