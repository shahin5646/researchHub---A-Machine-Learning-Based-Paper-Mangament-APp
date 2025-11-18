import '../models/research_paper.dart';

final List<ResearchPaper> featuredPapers = [
  ResearchPaper(
    id: 'paper_001',
    title:
        'A cloud based four-tier architecture for early detection of heart disease with machine learning algorithms',
    author: 'Professor Dr. Sheak Rashed Haider Noori',
    journalName: 'IEEE Transactions on Biomedical Engineering',
    year: '2024',
    pdfUrl:
        'assets/papers/ProfessorDrSheakRashedHaiderNoori/heart_disease_detection.pdf',
    doi: '10.1109/TBME.2024.001',
    keywords: [
      'Machine Learning',
      'Cloud Computing',
      'Heart Disease',
      'Healthcare'
    ],
    abstract:
        'This paper presents a novel cloud-based four-tier architecture for early detection of heart disease using advanced machine learning algorithms. The proposed system achieves 95% accuracy in early detection.',
    citations: 42,
    authorImagePath: 'assets/images/faculty/noori_siRk.jpg',
    views: 1378,
    downloads: 120,
    category: 'Biomedical Research',
    publishDate: DateTime(2024, 1, 15),
    isAsset: true,
  ),
  ResearchPaper(
    id: 'paper_002',
    title:
        'Advanced Neural Networks for Environmental Monitoring and Prediction',
    author: 'Professor Dr. Sheak Rashed Haider Noori',
    journalName: 'Nature Environmental Science',
    year: '2024',
    pdfUrl:
        'assets/papers/ProfessorDrSheakRashedHaiderNoori/environmental_monitoring.pdf',
    doi: '10.1038/s41561-2024.002',
    keywords: [
      'Neural Networks',
      'Environmental Science',
      'Prediction Models',
      'Climate Change'
    ],
    abstract:
        'A comprehensive study on the application of advanced neural networks for environmental monitoring and climate prediction with improved accuracy.',
    citations: 38,
    authorImagePath: 'assets/images/faculty/noori_siRk.jpg',
    views: 965,
    downloads: 87,
    category: 'Environmental Science',
    publishDate: DateTime(2024, 2, 20),
    isAsset: true,
  ),
  ResearchPaper(
    id: 'paper_003',
    title:
        'Investigation of Analgesic, Anti-inflammatory, and Antidiabetic Effects of Phyllanthus beillei Leaves',
    author: 'Dr. Md. Sarowar Hossain',
    journalName: 'Journal of Medicinal Plants Research',
    year: '2024',
    pdfUrl:
        'assets/papers/Dr_Md._Sarowar_Hossain/Investigation_of_analgesic_anti_inflammatory_and_antidiabetic_effects_of_Phyllanthus_beillei_leaves_H.pdf',
    doi: '10.5897/JMPR.2024.003',
    keywords: [
      'Phyllanthus',
      'Analgesic',
      'Anti-inflammatory',
      'Antidiabetic',
      'Medicinal Plants'
    ],
    abstract:
        'This research investigates the analgesic, anti-inflammatory, and antidiabetic effects of Phyllanthus beillei leaves through comprehensive laboratory studies.',
    citations: 29,
    authorImagePath: 'assets/images/faculty/sarowar_hossain.jpg',
    views: 743,
    downloads: 56,
    category: 'Medical Science',
    publishDate: DateTime(2024, 3, 10),
    isAsset: true,
  ),
  ResearchPaper(
    id: 'paper_004',
    title:
        'Artificial Intelligence in Drug Discovery: Current Trends and Future Prospects',
    author: 'Dr. A.H.M. Saifullah Sadi',
    journalName: 'Drug Discovery Today',
    year: '2024',
    pdfUrl: 'assets/papers/Dr_A_H_M_SaifullahSadi/ai_drug_discovery.pdf',
    doi: '10.1016/j.drudis.2024.004',
    keywords: [
      'Artificial Intelligence',
      'Drug Discovery',
      'Pharmaceutical',
      'Machine Learning'
    ],
    abstract:
        'An extensive review of AI applications in drug discovery, highlighting current trends and future prospects in pharmaceutical research.',
    citations: 51,
    authorImagePath: 'assets/images/faculty/sadi_sir.jpg',
    views: 1205,
    downloads: 143,
    category: 'Biomedical Research',
    publishDate: DateTime(2024, 4, 5),
    isAsset: true,
  ),
  ResearchPaper(
    id: 'paper_005',
    title: 'Sustainable Software Engineering Practices for Green Computing',
    author: 'Dr. S.M. Aminul Haque',
    journalName: 'IEEE Software',
    year: '2024',
    pdfUrl: 'assets/papers/Dr_S_M_Aminul_Haque/sustainable_software.pdf',
    doi: '10.1109/MS.2024.005',
    keywords: [
      'Sustainable Software',
      'Green Computing',
      'Energy Efficiency',
      'Software Engineering'
    ],
    abstract:
        'This paper discusses sustainable software engineering practices that contribute to green computing and energy-efficient systems.',
    citations: 33,
    authorImagePath: 'assets/images/faculty/aminul_haque.jpg',
    views: 892,
    downloads: 78,
    category: 'Software Engineering',
    publishDate: DateTime(2024, 5, 18),
    isAsset: true,
  ),
];

final List<ResearchPaper> trendingPapers = [
  ResearchPaper(
    id: 'paper_006',
    title: 'Quantum Computing Applications in Cryptography and Cybersecurity',
    author: 'Dr. Shaikh Muhammad Allayear',
    journalName: 'Quantum Information Processing',
    year: '2024',
    pdfUrl: 'assets/papers/Dr_Shaikh_Muhammad_Allayear/quantum_crypto.pdf',
    doi: '10.1007/s11128-2024.006',
    keywords: [
      'Quantum Computing',
      'Cryptography',
      'Cybersecurity',
      'Quantum Algorithms'
    ],
    abstract:
        'Exploring the revolutionary impact of quantum computing on cryptography and cybersecurity protocols.',
    citations: 67,
    authorImagePath: 'assets/images/faculty/allayear_sir.jpg',
    views: 1567,
    downloads: 201,
    category: 'Computer Science',
    publishDate: DateTime(2024, 6, 12),
    isAsset: true,
  ),
  ResearchPaper(
    id: 'paper_007',
    title: 'Deep Learning for Medical Image Analysis and Diagnosis',
    author: 'Dr. Imran Mahmud',
    journalName: 'Medical Image Analysis',
    year: '2024',
    pdfUrl: 'assets/papers/DrImran_Mahmud/deep_learning_medical.pdf',
    doi: '10.1016/j.media.2024.007',
    keywords: [
      'Deep Learning',
      'Medical Imaging',
      'Computer Vision',
      'Healthcare AI'
    ],
    abstract:
        'A comprehensive study on deep learning applications in medical image analysis for improved diagnostic accuracy.',
    citations: 45,
    authorImagePath: 'assets/images/faculty/imran_mahmud.jpg',
    views: 1134,
    downloads: 165,
    category: 'Artificial Intelligence',
    publishDate: DateTime(2024, 7, 8),
    isAsset: true,
  ),
];

final List<ResearchPaper> allResearchPapers = [
  ...featuredPapers,
  ...trendingPapers,
];

// Helper function to get papers by category
List<ResearchPaper> getPapersByCategory(String category) {
  if (category == 'All') return allResearchPapers;
  return allResearchPapers
      .where((paper) => paper.category == category)
      .toList();
}

// Helper function to get papers by author
List<ResearchPaper> getPapersByAuthor(String author) {
  return allResearchPapers
      .where(
          (paper) => paper.author.toLowerCase().contains(author.toLowerCase()))
      .toList();
}

// Helper function to search papers
List<ResearchPaper> searchPapers(String query) {
  if (query.isEmpty) return allResearchPapers;

  final lowercaseQuery = query.toLowerCase();
  return allResearchPapers
      .where((paper) =>
          paper.title.toLowerCase().contains(lowercaseQuery) ||
          paper.author.toLowerCase().contains(lowercaseQuery) ||
          paper.keywords.any(
              (keyword) => keyword.toLowerCase().contains(lowercaseQuery)) ||
          paper.abstract.toLowerCase().contains(lowercaseQuery))
      .toList();
}
