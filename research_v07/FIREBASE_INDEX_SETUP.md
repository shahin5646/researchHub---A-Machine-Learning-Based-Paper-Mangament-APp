# Firebase Firestore Index Setup Instructions

## Quick Fix (Recommended)

The easiest way to create the required index is to **click the link in the error message** that appears in your app. The error shows a direct URL to create the index automatically.

Example error message:
```
The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/research-hub-d9034/firestore/indexes?create_composite=...
```

Just click that link and Firebase will create the index for you!

---

## Manual Setup (Alternative Method)

If you prefer to create the index manually or the link doesn't work, follow these steps:

### Step 1: Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **research-hub-d9034**
3. Click on **Firestore Database** in the left sidebar
4. Click on the **Indexes** tab at the top

### Step 2: Create Composite Index for "Following" Feed

Click **"Create Index"** and configure:

#### Index Configuration:
- **Collection ID:** `papers`
- **Query Scope:** `Collection`

#### Fields to index (in this exact order):
1. **Field 1:**
   - Field path: `uploadedBy`
   - Query scope: `Ascending`

2. **Field 2:**
   - Field path: `visibility`
   - Query scope: `Ascending`

3. **Field 3:**
   - Field path: `uploadedAt`
   - Query scope: `Descending`

4. **Field 4 (automatic):**
   - Field path: `__name__`
   - Query scope: `Descending`

### Step 3: Create Index
1. Click **"Create Index"**
2. Wait for the index to build (usually takes 1-5 minutes)
3. Status will show as "Building..." then "Enabled"

### Step 4: Verify
Once the index status shows **"Enabled"**, return to your app and:
1. Close and reopen the app (or hot restart with 'R')
2. Tap the **"Following"** tab
3. Papers should now load without errors

---

## Current Index Status

### ✅ All Tab - Working
The "All" tab doesn't require an index because we fetch all papers and filter/sort in memory.

### ⚠️ Following Tab - Requires Index
The "Following" tab needs the composite index because it queries:
- Papers from specific authors (IN query on `uploadedBy`)
- With public visibility (WHERE `visibility == 'public'`)
- Sorted by upload date (ORDER BY `uploadedAt DESC`)

This combination requires a composite index in Firestore.

---

## Alternative: Use All Tab
While waiting for the index to build, you can use the **"All"** tab which shows all papers sorted by engagement (likes, comments, shares, clicks).

---

## Troubleshooting

### Index Building Takes Too Long
- Indexes usually build in 1-5 minutes
- If it takes longer than 10 minutes, try deleting and recreating
- Check your Firebase project quota in the Firebase Console

### Index Creation Fails
1. Verify you have **Owner** or **Editor** permissions on the Firebase project
2. Check that the field names match exactly (case-sensitive)
3. Ensure the collection name is `papers` (lowercase)

### Still Getting Errors After Index is Enabled
1. Hot restart the app (press 'R' in the terminal)
2. Fully close and reopen the app
3. Check Firebase Console to confirm index status is "Enabled"
4. Verify you're logged in and following at least one faculty member

---

## Technical Details

### Why This Index is Needed
Firestore requires composite indexes for queries that:
- Use IN queries (checking if `uploadedBy` matches multiple values)
- Combine WHERE clauses with ORDER BY on different fields
- Query on fields that aren't in the index

### Query Structure
```dart
Query(
  papers 
  where uploadedBy in [user_dr._imran_mahmud, user_professor_dr._m._shamsul_alam] 
  and visibility == public 
  order by -uploadedAt, -__name__
)
```

This requires indexing all three fields: `uploadedBy`, `visibility`, and `uploadedAt`.

---

## Need Help?

If you continue to experience issues:
1. Check the Flutter console for the exact error message
2. Copy the URL from the error message and open it in a browser
3. Verify your Firebase project is **research-hub-d9034**
4. Ensure you have the necessary permissions in Firebase Console
