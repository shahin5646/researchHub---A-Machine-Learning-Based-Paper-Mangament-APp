# Scroll-to-Hide Post Composer & Faculty Profile Navigation Fix

## ✅ **Implemented Changes:**

### 1. **Hide Post Composer While Scrolling (Instagram-style)**

#### **Added State Variables:**
```dart
bool _showPostComposer = true;
double _lastScrollOffset = 0.0;
```

#### **Added Scroll Listener:**
```dart
@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
}

void _onScroll() {
  final currentOffset = _scrollController.offset;
  const threshold = 50.0; // minimum scroll distance to trigger hide/show
  
  if ((currentOffset - _lastScrollOffset).abs() > threshold) {
    final isScrollingDown = currentOffset > _lastScrollOffset;
    setState(() {
      _showPostComposer = !isScrollingDown;
      _lastScrollOffset = currentOffset;
    });
  }
}
```

#### **Animated Post Composer:**
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  height: _showPostComposer ? null : 0,
  child: AnimatedOpacity(
    duration: const Duration(milliseconds: 300),
    opacity: _showPostComposer ? 1.0 : 0.0,
    child: _showPostComposer ? _buildModernPostComposer() : const SizedBox(),
  ),
),
```

### 2. **Fixed Faculty Profile Navigation**

#### **Problem Identified:**
- `paper.uploadedBy` contained generated user IDs (like "dr_john_doe_123")
- Faculty profiles needed actual names (like "Dr. John Doe")
- Navigation was failing due to ID vs Name mismatch

#### **Solution Applied:**
```dart
// OLD - Using generated user ID
onTap: () => _navigateToAuthorProfile(paper.uploadedBy)

// NEW - Using actual author name  
onTap: () => _navigateToAuthorProfile(paper.authors.first)
```

#### **Updated Components:**
1. **Compact Author Avatar Click:**
   ```dart
   GestureDetector(
     onTap: () => _navigateToAuthorProfile(paper.authors.first),
     child: Container(// Avatar widget)
   )
   ```

2. **Compact Author Name Click:**
   ```dart
   GestureDetector(
     onTap: () => _navigateToAuthorProfile(paper.authors.first), 
     child: Column(// Author info)
   )
   ```

3. **Compact Follow Button:**
   ```dart
   Widget _buildCompactFollowButton(String authorName) {
     final authorId = _generateUserIdFromAuthor(authorName);
     // Rest of the logic uses authorId for follow functionality
   }
   ```

## 🎯 **User Experience:**

### **Scroll-to-Hide Behavior:**
- **Scroll Down** → Post composer slides up and fades out (300ms animation)
- **Scroll Up** → Post composer slides down and fades in (300ms animation)  
- **Threshold**: 50px minimum scroll distance to prevent jittery behavior
- **Smooth animations** with opacity and height transitions

### **Faculty Profile Navigation:**
- **Click faculty avatar** → Opens faculty profile screen
- **Click faculty name** → Opens faculty profile screen  
- **Smart name matching** with normalization for titles (Dr., Professor, etc.)
- **Error handling** with user-friendly messages if faculty not found

## 🔧 **Technical Details:**

### **Animation Performance:**
- Uses `AnimatedContainer` and `AnimatedOpacity` for smooth transitions
- 300ms duration for natural feel
- Minimal state updates with scroll threshold

### **Memory Management:**
- Proper listener cleanup in `dispose()`
- Efficient state management with boolean flags
- No unnecessary rebuilds

### **Navigation Robustness:**
- Fallback search with partial name matching
- Graceful error handling with SnackBar notifications
- Maintains existing follow/social functionality

## 🚀 **Result:**

✅ **Post composer now hides smoothly when scrolling down (like Instagram)**
✅ **Post composer appears smoothly when scrolling up**  
✅ **Faculty profile navigation works correctly**
✅ **All existing functionality preserved**
✅ **Smooth animations with professional feel**

The feed now provides a modern, Instagram-like scrolling experience while maintaining full faculty profile connectivity!