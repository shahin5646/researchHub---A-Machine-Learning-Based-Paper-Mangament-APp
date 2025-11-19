# ResearchHub — ML-Based Paper Management App

A lightweight Flutter mobile app for research paper discovery and management with built-in machine learning capabilities for smarter search, categorization and clustering.

Short, focused, and effective — highlights: automated paper categorization, clustering, and semantic search powered by ML embeddings.

**Key ML Features:**
- **Automated Categorization:** classifies uploaded papers into topical categories to speed discovery.
- **Clustering & Recommendations:** groups related papers (topic clusters) to surface similar work.
- **Semantic Search & Embeddings:** improves query matching using text embeddings for better relevance than keyword-only search.
- **Online / Offline-friendly:** ML pipeline supports server-side training and lightweight inference for fast app responses.

**Screenshots**

<div style="display: flex; gap: 8px; flex-wrap: wrap; justify-content: center;">
  <img src="https://github.com/shahin5646/researchHub---A-Machine-Learning-Based-Paper-Mangament-APp/blob/53b5b569d5616db71cccdca8b98c8977bbaf8763/App%20Screenshots/App%20Pictures/Screenshot_2025-11-18-12-46-52-78_7bc93c426dac36c82d484dc4c898cdc0.jpg" alt="Homepage" style="width: 120px; border-radius: 8px;"/>
  <img src="https://github.com/shahin5646/researchHub---A-Machine-Learning-Based-Paper-Mangament-APp/blob/53b5b569d5616db71cccdca8b98c8977bbaf8763/App%20Screenshots/App%20Pictures/Screenshot_2025-11-18-12-47-00-15_7bc93c426dac36c82d484dc4c898cdc0.jpg" alt="Research Feed" style="width: 120px; border-radius: 8px;"/>
  <img src="https://github.com/shahin5646/researchHub---A-Machine-Learning-Based-Paper-Mangament-APp/blob/53b5b569d5616db71cccdca8b98c8977bbaf8763/App%20Screenshots/App%20Pictures/Screenshot_2025-11-18-12-47-10-18_7bc93c426dac36c82d484dc4c898cdc0.jpg" alt="Faculty" style="width: 120px; border-radius: 8px;"/>
  <img src="https://github.com/shahin5646/researchHub---A-Machine-Learning-Based-Paper-Mangament-APp/blob/53b5b569d5616db71cccdca8b98c8977bbaf8763/App%20Screenshots/App%20Pictures/Screenshot_2025-11-18-12-47-15-22_7bc93c426dac36c82d484dc4c898cdc0.jpg" alt="Faculty Profile" style="width: 120px; border-radius: 8px;"/>
  <img src="https://github.com/shahin5646/researchHub---A-Machine-Learning-Based-Paper-Mangament-APp/blob/53b5b569d5616db71cccdca8b98c8977bbaf8763/App%20Screenshots/App%20Pictures/Screenshot_2025-11-18-12-47-35-05_7bc93c426dac36c82d484dc4c898cdc0.jpg" alt="Research Papers" style="width: 120px; border-radius: 8px;"/>
  <img src="https://github.com/shahin5646/researchHub---A-Machine-Learning-Based-Paper-Mangament-APp/blob/53b5b569d5616db71cccdca8b98c8977bbaf8763/App%20Screenshots/App%20Pictures/Screenshot_2025-11-18-12-47-52-29_7bc93c426dac36c82d484dc4c898cdc0.jpg" alt="Chat" style="width: 120px; border-radius: 8px;"/>
  <img src="https://github.com/shahin5646/researchHub---A-Machine-Learning-Based-Paper-Mangament-APp/blob/53b5b569d5616db71cccdca8b98c8977bbaf8763/App%20Screenshots/App%20Pictures/Screenshot_2025-11-18-12-48-04-72_7bc93c426dac36c82d484dc4c898cdc0.jpg" alt="Categories" style="width: 120px; border-radius: 8px;"/>
</div>


**Quick Start**

1. Install Flutter and set up your platform (Android/iOS).  
2. Add Firebase config files (`google-services.json` / `GoogleService-Info.plist`) — do NOT commit these.  
3. Run:

```powershell
flutter pub get
flutter run
```

**Notes on ML**
- Training: model training and dataset prep were done outside the app (Python — scikit-learn / Hugging Face transformers or similar).  
- Inference: app uses precomputed embeddings and lightweight clustering or a small on-device model / server API depending on deployment.  
- Goals: improve discovery, surface related work, and enable category-based navigation.

Contributing: open issues or PRs; see code and docs in the repo.  

License: MIT (or add your preferred license).
# research_v07

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
