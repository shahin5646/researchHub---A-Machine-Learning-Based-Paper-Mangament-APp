# All Research Papers - Testing Checklist ✅

## Pre-Testing
- [ ] Hot restart the app (not just hot reload)
- [ ] Clear any cached state

## Basic Display Tests

### 1. Papers Loading
- [ ] Navigate to All Research Papers screen
- [ ] Verify "10 papers" shows in header (not "0 papers")
- [ ] Verify papers are displaying in list
- [ ] Verify no "No research papers available" empty state

### 2. Category View (Default)
- [ ] Verify "All Papers" toggle is selected by default
- [ ] Verify papers are grouped by categories
- [ ] Should see these categories:
  - [ ] Computer Science (4 papers)
  - [ ] Biomedical Research (3 papers)
  - [ ] Software Engineering (1 paper)
  - [ ] Education (1 paper)
  - [ ] Business & Economics (1 paper)

### 3. Author View
- [ ] Tap "By Author" toggle button
- [ ] Verify papers are grouped by author names
- [ ] Verify alphabetical sorting by author
- [ ] Should see these authors:
  - [ ] Dr. A.H.M. Saifullah Sadi
  - [ ] Dr. Imran Mahmud
  - [ ] Dr. Md. Sarowar Hossain
  - [ ] Dr. S.M. Aminul Haque
  - [ ] Dr. Shaikh Muhammad Allayear
  - [ ] Professor Dr. Md. Fokhray Hossain
  - [ ] Professor Dr. Sheak Rashed Haider Noori

### 4. Trending View
- [ ] Tap "Trending" toggle button
- [ ] Verify papers display with view counts
- [ ] Verify papers are sorted by popularity
- [ ] Verify view/download badges show

## Paper Card Tests

### 5. Card Design
- [ ] Verify minimal flat design (no shadows/gradients)
- [ ] Verify 1px borders on cards
- [ ] Verify category badges display correctly
- [ ] Verify badge colors match category:
  - Computer Science: Blue (#3B82F6)
  - Biomedical Research: Red (#EF4444)
  - Software Engineering: Green (#10B981)
  - Education: Orange (#F59E0B)
  - Business & Economics: Purple (#8B5CF6)

### 6. Paper Information
- [ ] Verify paper title displays (16px, semibold)
- [ ] Verify author name displays (14px, medium)
- [ ] Verify year displays (13px)
- [ ] Verify proper text truncation (no overflow)

### 7. Interaction
- [ ] Tap paper card - should navigate to PDF viewer
- [ ] Verify InkWell ripple effect on tap
- [ ] Verify paper opens correctly in PDF viewer

## Search Tests

### 8. Search Functionality
- [ ] Tap search field
- [ ] Type "machine learning"
- [ ] Verify papers filter in real-time
- [ ] Should show 2 papers:
  - Heart disease detection paper
  - ML Healthcare paper
- [ ] Clear search (tap X button)
- [ ] Verify all papers return

### 9. Search Edge Cases
- [ ] Search by author name (e.g., "Noori")
- [ ] Search by year (e.g., "2024")
- [ ] Search by category keyword (e.g., "Computer")
- [ ] Search with no results (e.g., "xyz123")
- [ ] Verify "No papers found" message shows

## Navigation Tests

### 10. AppBar
- [ ] Verify 68px minimal flat AppBar
- [ ] Verify back button has 1px border
- [ ] Tap back button - returns to previous screen
- [ ] Verify title "All Research Papers" displays

### 11. Screen Transitions
- [ ] Navigate to All Papers from home
- [ ] Switch between view modes smoothly
- [ ] No lag or jank during transitions
- [ ] Proper state preservation

## Performance Tests

### 12. Scrolling
- [ ] Scroll through paper list smoothly
- [ ] No overflow errors in console
- [ ] No nested scroll warnings
- [ ] Scroll position maintained on view toggle

### 13. State Management
- [ ] Switch view modes - state persists
- [ ] Search then switch views - search clears
- [ ] Navigate away and back - state reloads
- [ ] Hot reload - papers still display

## Visual Tests

### 14. Layout
- [ ] Verify SafeArea padding
- [ ] Verify proper spacing (16px between cards)
- [ ] Verify card padding (20px)
- [ ] Verify card radius (16px)

### 15. Typography
- [ ] Inter font family used throughout
- [ ] Negative letter spacing (-0.3 to -0.5)
- [ ] Proper font weights (medium, semibold, bold)
- [ ] Text colors match theme

### 16. Dark/Light Mode
- [ ] Test in light mode
- [ ] Test in dark mode
- [ ] Verify borders visible in both modes
- [ ] Verify text contrast in both modes

## Edge Cases

### 17. Empty States
- [ ] Mock empty paper list - verify empty state
- [ ] Search with no results - verify message
- [ ] Trending with no views - verify display

### 18. Error Handling
- [ ] Mock PDF load error - verify graceful handling
- [ ] Mock service error - verify error message
- [ ] Network issues - verify offline behavior

## Integration Tests

### 19. Full User Flow
- [ ] Open app → Navigate to All Papers
- [ ] Search for paper → Tap result
- [ ] View PDF → Go back
- [ ] Switch to Author view
- [ ] Switch to Trending view
- [ ] Return to home

### 20. Cross-Feature Tests
- [ ] Compare with My Papers screen design consistency
- [ ] Verify similar papers show in both screens
- [ ] Test navigation between My Papers and All Papers
- [ ] Verify consistent PDF viewer behavior

## Bug Checklist

### Known Issues (Should NOT Occur)
- [ ] ❌ Papers not showing (0 papers)
- [ ] ❌ Empty state when papers exist
- [ ] ❌ Overflow errors
- [ ] ❌ Nested scroll warnings
- [ ] ❌ ExpansionTiles hiding papers
- [ ] ❌ Category counts showing 0

### Expected Behavior
- [ ] ✅ 10 papers showing
- [ ] ✅ All categories populated
- [ ] ✅ Smooth scrolling
- [ ] ✅ Clean minimal design
- [ ] ✅ No console errors

---

## Test Results Template

**Date**: _________________  
**Tester**: _________________  
**Device**: _________________  
**OS**: _________________

**Total Tests**: 20  
**Passed**: ___  
**Failed**: ___  
**Blocked**: ___

**Critical Issues**:
- [ ] Papers not loading
- [ ] PDF viewer not working
- [ ] App crashes

**Minor Issues**:
- [ ] Visual inconsistencies
- [ ] Performance lag
- [ ] Text overflow

**Notes**:
_________________________________
_________________________________
_________________________________

---

**Status**: Ready for Testing  
**Priority**: High  
**Estimated Time**: 30-45 minutes
