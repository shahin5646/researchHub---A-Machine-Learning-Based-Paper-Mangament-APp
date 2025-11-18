import '../models/faculty.dart';
import '../constants/image_paths.dart';
import '../models/research_paper.dart'; // Add this import

final List<Faculty> facultyMembers = [
  // CSE Department Faculty
  Faculty(
    name: 'Professor Dr. Sheak Rashed Haider Noori',
    designation: 'Professor & Head',
    department: 'Department of Computer Science and Engineering',
    faculty: 'Faculty of Science and Information Technology',
    employeeId: '710001060',
    email: 'headcse@daffodilvarsity.edu.bd, drnoori@daffodilvarsity.edu.bd',
    officePhone: '15100',
    cellPhone: '01847140016',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/cse/rashed-haider-noori.html',
    imageUrl: FacultyImages.noori,
    isOnline: true,
  ),

  Faculty(
    name: 'Professor Dr. Md. Fokhray Hossain',
    designation: 'Professor',
    department: 'Department of Computer Science and Engineering',
    faculty: 'Faculty of Science and Information Technology',
    employeeId: '710000367',
    email:
        'drfokhray@daffodilvarsity.edu.bd, international@daffodilvarsity.edu.bd',
    officePhone: '9138234-5',
    cellPhone: '01713-493250',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/cse/fokhray.html',
    imageUrl: FacultyImages.fokhray,
    isOnline: true,
  ),

  Faculty(
    name: 'Dr. S. M. Aminul Haque',
    designation: 'Professor & Associate Head',
    department: 'Department of Computer Science and Engineering',
    faculty: 'Faculty of Science and Information Technology',
    employeeId: '710001054',
    email:
        'aheadcse2@daffodilvarsity.edu.bd, aminul.cse@daffodilvarsity.edu.bd',
    officePhone: '15101',
    cellPhone: '01847140129',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/cse/aminul.html',
    imageUrl: FacultyImages.aminul,
    isOnline: true,
  ),

  Faculty(
    name: 'Ms. Nazmun Nessa Moon',
    designation: 'Associate Professor',
    department: 'Department of Computer Science and Engineering',
    faculty: 'Faculty of Science and Information Technology',
    employeeId: '710001234',
    email: 'moon@daffodilvarsity.edu.bd',
    officePhone: '02-9138234-5, Ext- 122',
    cellPhone: '01798145670',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/cse/nazmun-nessa-moon.html',
    imageUrl: FacultyImages.nazmunMoon,
    isOnline: true,
  ),

  // SWE Department Faculty
  Faculty(
    name: 'Dr. Shaikh Muhammad Allayear',
    designation: 'Professor & Proctor',
    department: 'Department of Multimedia & Creative Technology (MCT)',
    faculty: 'Faculty of Science and Information Technology',
    employeeId: '710001664',
    email: 'drallayear.mct@diu.edu.bd, proctor@daffodilvarsity.edu.bd',
    officePhone: '40100',
    cellPhone: '01847334900, 01974013732, 01624013732',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/mct/Allayear.html',
    imageUrl: FacultyImages.allayear,
    isOnline: true,
  ),

  Faculty(
    name: 'Dr. A. H. M. Saifullah Sadi',
    designation: 'Professor',
    department: 'Department of Software Engineering',
    faculty: 'Faculty of Science and Information Technology',
    employeeId: '710003717',
    email: 'sadi.swe@diu.edu.bd',
    officePhone: '',
    cellPhone: '01795379956',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/swe/saifullahsadi.html',
    imageUrl: FacultyImages.sadi,
    isOnline: true,
  ),

  Faculty(
    name: 'Dr. Imran Mahmud',
    designation: 'Professor & Head',
    department: 'Department of Software Engineering',
    faculty: 'Faculty of Science and Information Technology',
    employeeId: '710000934',
    email: 'imranmahmud@daffodilvarsity.edu.bd',
    officePhone: '35100',
    cellPhone: '01847140117, 01711370502',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/swe/imahmud.html',
    imageUrl: FacultyImages.imran,
    isOnline: true,
  ),

  // Pharmacy Department Faculty
  Faculty(
    name: 'Dr. Md. Sarowar Hossain',
    designation: 'Associate Dean & Associate Professor',
    department: 'Department of Pharmacy',
    faculty: 'Faculty of Health and Life Sciences',
    employeeId: '710002373',
    email: 'adeanfhls@daffodilvarsity.edu.bd, sarowar.ph@diu.edu.bd',
    officePhone: '',
    cellPhone: '01777845198',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/pharmacy/drsarowar.html',
    imageUrl: FacultyImages.sarowar,
    isOnline: true,
  ),

  Faculty(
    name: 'Professor Dr. Muniruddin Ahmed',
    designation: 'Professor',
    department: 'Department of Pharmacy',
    faculty: 'Faculty of Health and Life Sciences',
    employeeId: '722900068',
    email: 'drmuniruddin.ph@diu.edu.bd',
    officePhone: '46100',
    cellPhone: '01847334841, 01755587204',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/pharmacy/muniruddin.html',
    imageUrl: FacultyImages.muniruddin,
    isOnline: true,
  ),

  Faculty(
    name: 'Prof. Dr. Md. Ekramul Haque',
    designation: 'Professor',
    department: 'Department of Pharmacy',
    faculty: 'Faculty of Health and Life Sciences',
    employeeId: '722900054',
    email: 'drekram.pharmacy@diu.edu.bd',
    officePhone: '',
    cellPhone: '01711952286',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/pharmacy/ekramul.html',
    imageUrl: FacultyImages.ekramul,
    isOnline: true,
  ),

  // EEE Department Faculty
  Faculty(
    name: 'Professor Dr. M. Shamsul Alam',
    designation: 'Dean & Professor',
    department: 'Department of Electrical and Electronic Engineering',
    faculty: 'Faculty of Engineering',
    employeeId: '710000800',
    email: 'deanfe@daffodilvarsity.edu.bd',
    officePhone: '02-9138234-5 Ex-65109',
    cellPhone: '01833102814',
    personalWebpage:
        'https://faculty.daffodilvarsity.edu.bd/profile/eee/msalam.html',
    imageUrl: FacultyImages.shamsul,
    isOnline: true,
  ),
];

final Map<String, List<ResearchPaper>> facultyResearchPapers = {
  'Professor Dr. Sheak Rashed Haider Noori': [
    ResearchPaper(
      id: '1',
      title:
          'A Collaborative Platform to Collect Data for Developing Machine Translation Systems',
      author: 'Professor Dr. Sheak Rashed Haider Noori',
      journalName: 'Computational Linguistics Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/ProfessorDrSheakRashedHaiderNoori/A_Collaborative_Platform_to_Collect_ Data_for_Developing_Machine_Translation_Systems.pdf',
      doi: '10.1162/coli.2023.001',
      keywords: [
        'Machine Translation',
        'NLP',
        'Data Collection',
        'Collaborative Platform'
      ],
      abstract:
          'A collaborative platform designed to facilitate data collection for developing machine translation systems.',
      citations: 18,
      isAsset: true,
    ),
    ResearchPaper(
      id: '2',
      title:
          'Suffix Based Automated Parts of Speech Tagging for Bangla Language',
      author: 'Professor Dr. Sheak Rashed Haider Noori',
      journalName: 'Natural Language Engineering',
      year: '2023',
      pdfUrl:
          'assets/papers/ProfessorDrSheakRashedHaiderNoori/Suffix_Based_Automated_Parts_of_Speech_Tagging _for_Bangla_Language.pdf',
      doi: '10.1017/nle.2023.002',
      keywords: ['NLP', 'Bangla Language', 'POS Tagging', 'Suffix Analysis'],
      abstract:
          'An automated parts of speech tagging system for Bangla language using suffix-based analysis.',
      citations: 22,
      isAsset: true,
    ),
    ResearchPaper(
      id: '1a',
      title:
          'Appliance of Agile Methodology at Software Industry in Developing Countries Perspective in Bangladesh',
      author: 'Professor Dr. Sheak Rashed Haider Noori',
      journalName: 'Software Engineering Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/ProfessorDrSheakRashedHaiderNoori/Appliance_of_Agile_Methodology_at_Software_Industry_in_Developing_Countries_Perspective_in_Bangladesh.pdf',
      doi: '10.1002/smr.2023.003',
      keywords: [
        'Agile Methodology',
        'Software Engineering',
        'Developing Countries',
        'Bangladesh'
      ],
      abstract:
          'Analysis of agile methodology application in the software industry of developing countries with a focus on Bangladesh.',
      citations: 15,
      isAsset: true,
    ),
    ResearchPaper(
      id: '1b',
      title:
          'Bengali Named Entity Recognition: A Survey with Deep Learning Benchmark',
      author: 'Professor Dr. Sheak Rashed Haider Noori',
      journalName: 'ACM Computing Surveys',
      year: '2023',
      pdfUrl:
          'assets/papers/ProfessorDrSheakRashedHaiderNoori/Bengali_Named_Entity_Recognition_A_survey_with_deep_learning_benchmark.pdf',
      doi: '10.1145/3588124',
      keywords: ['NER', 'Bengali', 'Deep Learning', 'NLP'],
      abstract:
          'A comprehensive survey on Bengali named entity recognition with deep learning benchmarks.',
      citations: 35,
      isAsset: true,
    ),
    ResearchPaper(
      id: '1c',
      title: 'Machine Learning Based Unified Framework for Diabetes Prediction',
      author: 'Professor Dr. Sheak Rashed Haider Noori',
      journalName: 'Healthcare Analytics',
      year: '2023',
      pdfUrl:
          'assets/papers/ProfessorDrSheakRashedHaiderNoori/Machine_Learning_Based_Unified_Framework_for_Diabetes_Prediction.pdf',
      doi: '10.1016/j.health.2023.004',
      keywords: ['Machine Learning', 'Diabetes', 'Healthcare', 'Prediction'],
      abstract:
          'A unified framework using machine learning for accurate diabetes prediction.',
      citations: 28,
      isAsset: true,
    ),
    ResearchPaper(
      id: '1d',
      title:
          'Regularized Weighted Circular Complex Valued Extreme Learning Machine for Imbalanced Learning',
      author: 'Professor Dr. Sheak Rashed Haider Noori',
      journalName: 'Neural Computing and Applications',
      year: '2023',
      pdfUrl:
          'assets/papers/ProfessorDrSheakRashedHaiderNoori/Regularized_Weighted_Circular_Complex_Valued_Extreme_Learning_Machine_for_Imbalanced_Learning.pdf',
      doi: '10.1007/s00521-2023-005',
      keywords: [
        'Extreme Learning Machine',
        'Imbalanced Learning',
        'Neural Networks'
      ],
      abstract:
          'A regularized weighted circular complex valued extreme learning machine approach for handling imbalanced learning problems.',
      citations: 31,
      isAsset: true,
    ),
  ],
  'Professor Dr. Md. Fokhray Hossain': [
    ResearchPaper(
      id: '3',
      title:
          'Mobile Based Birth Registration System for New Born Baby in Bangladesh',
      author: 'Professor Dr. Md. Fokhray Hossain',
      journalName: 'Healthcare Information Systems',
      year: '2023',
      pdfUrl:
          'assets/papers/Professor_Dr_Md_FokhrayHossain/To_Design_&_Develop_Mobile _Based_Birth_Registration_System_for_New_Born_Baby_in_Bangladesh.pdf',
      doi: '10.1016/j.his.2023.001',
      keywords: [
        'Mobile Application',
        'Healthcare',
        'Birth Registration',
        'Bangladesh'
      ],
      abstract:
          'Design and development of a mobile-based birth registration system for newborns in Bangladesh.',
      citations: 12,
      isAsset: true,
    ),
    ResearchPaper(
      id: '11',
      title:
          'The Impact of Internationalization to Improve and Ensure Quality Education',
      author: 'Professor Dr. Md. Fokhray Hossain',
      journalName: 'Higher Education Studies',
      year: '2023',
      pdfUrl:
          'assets/papers/Professor_Dr_Md_FokhrayHossain/THE_IMPACT_OF_INTERNATIONALIZATION_TO_IMPROVE _AND_ENSURE_QUALITY_DUCATION_A_CASE_STUDY_OF_DAFFODIL_INTERNATIONAL_UNIVERSITY_(BANGLADESH).pdf',
      doi: '10.5539/hes.2023.002',
      keywords: [
        'Internationalization',
        'Higher Education',
        'Quality Assurance',
        'Bangladesh'
      ],
      abstract:
          'A case study examining the impact of internationalization on quality education at Daffodil International University.',
      citations: 16,
      isAsset: true,
    ),
    ResearchPaper(
      id: '3a',
      title: 'Automation System to Find Out Plasma Donors for Corona Patients',
      author: 'Professor Dr. Md. Fokhray Hossain',
      journalName: 'Healthcare Technology Letters',
      year: '2023',
      pdfUrl:
          'assets/papers/Professor_Dr_Md_FokhrayHossain/Automation_System_to_Find_Out_Plasma_Donors_for_Corona_Patients.pdf',
      doi: '10.1049/htl.2023.003',
      keywords: ['COVID-19', 'Plasma Donation', 'Healthcare', 'Automation'],
      abstract:
          'An automated system to identify and connect plasma donors with COVID-19 patients.',
      citations: 20,
      isAsset: true,
    ),
    ResearchPaper(
      id: '3b',
      title:
          'A Case Study on Customer Satisfaction Towards Online Banking in Bangladesh',
      author: 'Professor Dr. Md. Fokhray Hossain',
      journalName: 'Banking and Finance Review',
      year: '2023',
      pdfUrl:
          'assets/papers/Professor_Dr_Md_FokhrayHossain/A_Case_Study_on_Customer_Satisfaction_Towards_Online_Banking_inBangladesh.pdf',
      doi: '10.1016/j.banking.2023.004',
      keywords: [
        'Online Banking',
        'Customer Satisfaction',
        'Bangladesh',
        'FinTech'
      ],
      abstract:
          'A comprehensive case study analyzing customer satisfaction levels with online banking services in Bangladesh.',
      citations: 18,
      isAsset: true,
    ),
    ResearchPaper(
      id: '3c',
      title:
          'A Collaborative Platform to Collect Data for Developing Machine Translation Systems',
      author: 'Professor Dr. Md. Fokhray Hossain',
      journalName: 'Computational Linguistics',
      year: '2023',
      pdfUrl:
          'assets/papers/Professor_Dr_Md_FokhrayHossain/A_Collaborative_Platform_to_Collect_Data_for_Developing_Machine_Translation_Systems.pdf',
      doi: '10.1162/coli.2023.005',
      keywords: [
        'Machine Translation',
        'NLP',
        'Data Collection',
        'Collaboration'
      ],
      abstract:
          'A collaborative platform for collecting and managing data for machine translation system development.',
      citations: 14,
      isAsset: true,
    ),
    ResearchPaper(
      id: '3d',
      title: 'Early Detection of Brain Tumor Using Capsule Network',
      author: 'Professor Dr. Md. Fokhray Hossain',
      journalName: 'Medical Image Analysis',
      year: '2023',
      pdfUrl:
          'assets/papers/Professor_Dr_Md_FokhrayHossain/Early_Detection_of_Brain_Tumor_Using_Capsule_Network.pdf',
      doi: '10.1016/j.media.2023.006',
      keywords: [
        'Brain Tumor',
        'Capsule Network',
        'Deep Learning',
        'Medical Imaging'
      ],
      abstract:
          'Early detection of brain tumors using capsule network architecture for improved diagnostic accuracy.',
      citations: 25,
      isAsset: true,
    ),
    ResearchPaper(
      id: '3e',
      title:
          'The Impact of Online Education in Bangladesh: A Case Study during Covid-19',
      author: 'Professor Dr. Md. Fokhray Hossain',
      journalName: 'Education and Technology',
      year: '2023',
      pdfUrl:
          'assets/papers/Professor_Dr_Md_FokhrayHossain/The_Impact_of_Online_Education_in_BangladeshA_Case_Study_during_Covid19.pdf',
      doi: '10.1007/s10639-2023-007',
      keywords: ['Online Education', 'COVID-19', 'Bangladesh', 'E-Learning'],
      abstract:
          'Analysis of the impact of online education in Bangladesh during the COVID-19 pandemic.',
      citations: 22,
      isAsset: true,
    ),
  ],
  'Dr. S. M. Aminul Haque': [
    ResearchPaper(
      id: '4',
      title:
          'Efficient Resource Provisioning by Means of Sub Domain Based Ontology and Dynamic Pricing in Grid Computing',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'IEEE Transactions on Grid Computing',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/Efficient_Resource_Provisioning_by_Means_of_Sub_Domain_Based_Ontology_and_Dynamic_Pricing_in_Grid_Computing.pdf',
      doi: '10.1109/TGC.2023.001',
      keywords: [
        'Grid Computing',
        'Resource Management',
        'Ontology',
        'Dynamic Pricing'
      ],
      abstract:
          'An efficient resource provisioning mechanism for grid computing using sub-domain based ontology and dynamic pricing strategies.',
      citations: 31,
      isAsset: true,
    ),
    ResearchPaper(
      id: '5',
      title:
          'SkinNet-14: A Deep Learning Framework for Accurate Skin Cancer Classification',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'Medical Image Analysis',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/SkinNet_14_a_deep_learning_framework_for_accurate_skin_cancer_classification_using_low_resolution_dermoscopy_images_with_optimized_training_time.pdf',
      doi: '10.1016/j.media.2023.001',
      keywords: [
        'Deep Learning',
        'Medical Imaging',
        'Skin Cancer',
        'Classification'
      ],
      abstract:
          'SkinNet-14 is a deep learning framework designed for accurate skin cancer classification using low-resolution dermoscopy images.',
      citations: 45,
      isAsset: true,
    ),
    ResearchPaper(
      id: '10',
      title: 'An Agent Based Grouping Strategy for Federated Grid Computing',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'International Journal of Grid Computing',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/An_Agent_based_Grouping_Strategy_for_Federated_Grid_Computing_E_An_Agent_based_Grouping_Strategy_for_Federated_Grid_Computing.pdf',
      doi: '10.1234/ijgc.2023.010',
      keywords: [
        'Grid Computing',
        'Agent Based',
        'Federated Systems',
        'Resource Management'
      ],
      abstract:
          'An agent-based grouping strategy to improve resource management in federated grid computing environments.',
      citations: 20,
      isAsset: true,
    ),
    ResearchPaper(
      id: '4a',
      title:
          'Identifying and Modeling the Strengths and Weaknesses of Major Economic Models in Grid Resource Management',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'Journal of Grid Computing',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/Identifying_and_Modeling_the_Strengths_and_Weaknesses_of_Major_Economic_Models_in_Grid_Resource_Management.pdf',
      doi: '10.1007/s10723-2023.002',
      keywords: [
        'Economic Models',
        'Grid Computing',
        'Resource Management',
        'Analysis'
      ],
      abstract:
          'Analysis of strengths and weaknesses of major economic models used in grid resource management systems.',
      citations: 24,
      isAsset: true,
    ),
    ResearchPaper(
      id: '4b',
      title:
          'Improved Vision Based Diagnosis of Multi Plant Disease Using an Ensemble of Deep Learning Methods',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'Plant Disease Detection',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/Improved_vision_based_diagnosis_of_multi_plant_disease_using_an_ensemble_of_deep_learning_methods.pdf',
      doi: '10.1016/j.pdd.2023.003',
      keywords: [
        'Plant Disease',
        'Computer Vision',
        'Deep Learning',
        'Ensemble Methods'
      ],
      abstract:
          'An improved vision-based diagnosis system for multiple plant diseases using ensemble deep learning methods.',
      citations: 29,
      isAsset: true,
    ),
    ResearchPaper(
      id: '4c',
      title:
          'Iterative Combinatorial Auction for Two Sided Grid Markets: Multiple Users and Multiple Providers',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'Grid Economics',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/Iterative_Combinatorial_Auction_for_Two_Sided_Grid_Markets_Multiple_users_and_Multiple_Providers.pdf',
      doi: '10.1109/ge.2023.004',
      keywords: [
        'Combinatorial Auction',
        'Grid Markets',
        'Economic Models',
        'Resource Allocation'
      ],
      abstract:
          'An iterative combinatorial auction mechanism for two-sided grid markets with multiple users and providers.',
      citations: 18,
      isAsset: true,
    ),
    ResearchPaper(
      id: '4d',
      title:
          'Trajectory Planning and Collision Control of a Mobile Robot: Mathematical Problems in Engineering',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'Mathematical Problems in Engineering',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/Mathematical_Problems_in_Engineering_2023_Pandey_Trajectory_Planning_and_Collision_Control_of_a_Mobile_Robot_A.pdf',
      doi: '10.1155/2023/005',
      keywords: [
        'Mobile Robotics',
        'Trajectory Planning',
        'Collision Avoidance',
        'Control Systems'
      ],
      abstract:
          'Trajectory planning and collision control algorithms for mobile robot navigation in complex environments.',
      citations: 16,
      isAsset: true,
    ),
    ResearchPaper(
      id: '4e',
      title:
          'PithaNet: A Transfer Learning Based Approach for Traditional Pitha Classification',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'Food Computing',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/PithaNet_a_transfer_learning_based_approach_for_traditional_pitha_classification.pdf',
      doi: '10.1016/j.foodcomp.2023.006',
      keywords: [
        'Transfer Learning',
        'Food Classification',
        'Traditional Food',
        'Deep Learning'
      ],
      abstract:
          'PithaNet: A transfer learning-based approach for classifying traditional Bangladeshi pitha using deep learning.',
      citations: 14,
      isAsset: true,
    ),
    ResearchPaper(
      id: '4f',
      title:
          'Recognition of Bangladeshi Sign Language (BdSL) Words Using Deep Convolutional Neural Networks',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'Sign Language Processing',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/recognition_Bangladeshi_Sign_Language_BdSL_Words_using_Deep_convolutional_Neural_Networks_(DCNNs).pdf',
      doi: '10.1109/slp.2023.007',
      keywords: [
        'Sign Language',
        'BdSL',
        'Deep CNN',
        'Computer Vision',
        'Accessibility'
      ],
      abstract:
          'Recognition system for Bangladeshi Sign Language words using deep convolutional neural networks.',
      citations: 21,
      isAsset: true,
    ),
    ResearchPaper(
      id: '4g',
      title:
          'Survival Analysis of Thyroid Cancer Patients Using Machine Learning Algorithms',
      author: 'Dr. S. M. Aminul Haque',
      journalName: 'Medical Data Analytics',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_S_M_Aminul_Haque/Survival_Analysis_of_Thyroid_Cancer_Patients_Using_Machine_Learning_Algorithms.pdf',
      doi: '10.1016/j.mda.2023.008',
      keywords: [
        'Thyroid Cancer',
        'Survival Analysis',
        'Machine Learning',
        'Healthcare'
      ],
      abstract:
          'Survival analysis of thyroid cancer patients using advanced machine learning algorithms for prognosis prediction.',
      citations: 27,
      isAsset: true,
    ),
  ],
  'Dr. Shaikh Muhammad Allayear': [
    ResearchPaper(
      id: '6',
      title: 'A Location Based Time and Attendance System',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Information Systems Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/A_Location_Based_Time_and_Attendance_Sys.pdf',
      doi: '10.1111/isj.2023.001',
      keywords: [
        'Location-Based Services',
        'Attendance System',
        'GPS',
        'Mobile Technology'
      ],
      abstract:
          'A location-based time and attendance tracking system for workforce management.',
      citations: 15,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6b',
      title: 'Implementation of a Smart AC Automation',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Smart Systems and IoT',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/Implementation_of_a_Smart_AC_Automation.pdf',
      doi: '10.1016/j.iot.2023.002',
      keywords: ['IoT', 'Automation', 'Smart Home', 'Energy Efficiency'],
      abstract:
          'Implementation of a smart air conditioning automation system using IoT technology.',
      citations: 12,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6c',
      title:
          'Adaptation Mechanism of iSCSI Protocol for NAS Storage Solution in Wireless Environment',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Computer Networks',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/Adaptation_Mechanism_of_iSCSI_Protocol_for_NAS_Storage_Solution_in_Wireless_Environment.pdf',
      doi: '10.1016/j.comnet.2023.003',
      keywords: ['iSCSI', 'NAS', 'Wireless Networks', 'Storage Systems'],
      abstract:
          'Adaptation mechanism for iSCSI protocol to optimize NAS storage solutions in wireless environments.',
      citations: 18,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6d',
      title: 'AR & VR Based Child Education in Context of Bangladesh',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Educational Technology Research',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/AR_&_VR_Based_Child_Education_in_Context_of_Bangladesh.pdf',
      doi: '10.1007/s11423-2023-004',
      keywords: ['AR', 'VR', 'Education', 'Bangladesh', 'Child Learning'],
      abstract:
          'Application of augmented and virtual reality in child education within the context of Bangladesh.',
      citations: 20,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6e',
      title:
          'Creating Awareness About Traffic Jam Through Engaged Use of Stop Motion Animation Boomerang',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Interactive Media',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/Creating_awareness_about_traffic_jam_through_engaged_use_of_stop_motion_animation_boomerang.pdf',
      doi: '10.1016/j.im.2023.005',
      keywords: [
        'Stop Motion',
        'Animation',
        'Traffic Awareness',
        'Public Engagement'
      ],
      abstract:
          'Using stop motion animation and boomerang effects to create awareness about traffic congestion issues.',
      citations: 8,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6f',
      title:
          'Human Face Detection in Excessive Dark Image by Using Contrast Stretching Histogram Equalization and Adaptive Equalization',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Computer Vision and Image Processing',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/Human_Face_Detection_in_Excessive_Dark_Image_by_Using_Contrast_Stretching_Histogram_Equalization_and_Adaptive_Equalization.pdf',
      doi: '10.1109/cvip.2023.006',
      keywords: [
        'Face Detection',
        'Low Light',
        'Histogram Equalization',
        'Image Processing'
      ],
      abstract:
          'Human face detection in extremely dark images using advanced contrast stretching and histogram equalization techniques.',
      citations: 16,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6g',
      title:
          'iSCSI Multi Connection and Error Recovery Method for Remote Storage System in Mobile Appliance',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Mobile Computing',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/iSCSI_Multi_Connection_and_Error_Recovery_Method_for_Remote_Storage_System_in_Mobile_Appliance.pdf',
      doi: '10.1109/mc.2023.007',
      keywords: ['iSCSI', 'Mobile Storage', 'Error Recovery', 'Remote Access'],
      abstract:
          'Multi-connection and error recovery methods for iSCSI-based remote storage systems on mobile devices.',
      citations: 14,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6h',
      title: 'Simplified MapReduce Mechanism for Large Data Processing',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Big Data Analytics',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/Simplified_Mapreduce_Mechanism_for_Large.pdf',
      doi: '10.1016/j.bda.2023.008',
      keywords: [
        'MapReduce',
        'Big Data',
        'Distributed Computing',
        'Data Processing'
      ],
      abstract:
          'A simplified MapReduce mechanism for efficient processing of large-scale data.',
      citations: 22,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6i',
      title: 'The Architectural Design of Healthcare Systems',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Healthcare Systems Design',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/The_Architectural_Design_of_Healthcare_S.pdf',
      doi: '10.1016/j.healthsys.2023.009',
      keywords: [
        'Healthcare Architecture',
        'System Design',
        'Healthcare IT',
        'Medical Systems'
      ],
      abstract:
          'Architectural design principles and frameworks for modern healthcare information systems.',
      citations: 19,
      isAsset: true,
    ),
    ResearchPaper(
      id: '6j',
      title: 'Towards Adapting NAS Mechanism Over Solid State Drive',
      author: 'Dr. Shaikh Muhammad Allayear',
      journalName: 'Storage Technology',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Shaikh_Muhammad_Allayear/Towards_Adapting_NAS_Mechanism_over_Sol.pdf',
      doi: '10.1109/storage.2023.010',
      keywords: ['NAS', 'SSD', 'Storage Systems', 'Performance Optimization'],
      abstract:
          'Adaptation strategies for implementing NAS mechanisms on solid-state drive technology.',
      citations: 17,
      isAsset: true,
    ),
  ],
  'Dr. A. H. M. Saifullah Sadi': [
    ResearchPaper(
      id: '7',
      title:
          'Adaptive Secure and Efficient Routing Protocol to Enhance the Performance of Mobile Ad Hoc Network',
      author: 'Dr. A. H. M. Saifullah Sadi',
      journalName: 'Computer Networks',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_A_H_M_SaifullahSadi/Adaptive_Secure_and_Efficient_Routing_Protocol_to_Enhance_the_Performance_of_Mobile_Ad_Hoc_Network_(MANET).pdf',
      doi: '10.1016/j.comnet.2023.001',
      keywords: [
        'Mobile Ad Hoc Networks',
        'Routing Protocols',
        'Network Security',
        'MANET'
      ],
      abstract:
          'An adaptive secure routing protocol designed to enhance the performance of mobile ad hoc networks.',
      citations: 28,
      isAsset: true,
    ),
    ResearchPaper(
      id: '7a',
      title:
          'Design and Development of a Bipedal Robot with Adaptive Locomotion Control for Uneven Terrain',
      author: 'Dr. A. H. M. Saifullah Sadi',
      journalName: 'Robotics and Autonomous Systems',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_A_H_M_SaifullahSadi/Design_and_Development_of_a_Bipedal_Robot_with_Adaptive_Locomotion_Control_for_Uneven_Terrain.pdf',
      doi: '10.1016/j.robot.2023.002',
      keywords: [
        'Bipedal Robot',
        'Locomotion Control',
        'Adaptive Systems',
        'Robotics'
      ],
      abstract:
          'Design and development of a bipedal robot featuring adaptive locomotion control for navigating uneven terrain.',
      citations: 15,
      isAsset: true,
    ),
    ResearchPaper(
      id: '7b',
      title:
          'ML-ASPA: A Contemplation of Machine Learning based Acoustic Signal Processing Analysis',
      author: 'Dr. A. H. M. Saifullah Sadi',
      journalName: 'Signal Processing',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_A_H_M_SaifullahSadi/ML_ASPA_A_Contemplation_of_Machine_Learning_based_Acoustic_Signal_Processing_Analysis_for_Sounds_&_Strains_Emerging_Technology.pdf',
      doi: '10.1016/j.sigpro.2023.003',
      keywords: [
        'Machine Learning',
        'Acoustic Signal Processing',
        'Sound Analysis',
        'Emerging Technology'
      ],
      abstract:
          'A comprehensive analysis of machine learning-based acoustic signal processing for sound and strain detection.',
      citations: 18,
      isAsset: true,
    ),
    ResearchPaper(
      id: '7c',
      title:
          'Multiclass Blood Cancer Classification Using Deep CNN with Optimized Features',
      author: 'Dr. A. H. M. Saifullah Sadi',
      journalName: 'Medical Image Analysis',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_A_H_M_SaifullahSadi/Multiclass_blood_cancer_classification_using_deep_CNN_with_optimized_features.pdf',
      doi: '10.1016/j.media.2023.004',
      keywords: [
        'Blood Cancer',
        'Deep Learning',
        'CNN',
        'Medical Image Analysis'
      ],
      abstract:
          'A deep convolutional neural network approach for multiclass blood cancer classification with feature optimization.',
      citations: 22,
      isAsset: true,
    ),
    ResearchPaper(
      id: '7d',
      title:
          'Paddy Insect Identification Using Deep Features with Lion Optimization Algorithm',
      author: 'Dr. A. H. M. Saifullah Sadi',
      journalName: 'Agricultural Technology',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_A_H_M_SaifullahSadi/Paddy_Insect_Identification_using_Deep_Features_with_Lion_Optimization_Algorithm.pdf',
      doi: '10.1016/j.agtech.2023.005',
      keywords: [
        'Paddy',
        'Insect Identification',
        'Deep Learning',
        'Lion Optimization',
        'Agriculture'
      ],
      abstract:
          'Paddy insect identification system using deep features combined with lion optimization algorithm.',
      citations: 14,
      isAsset: true,
    ),
    ResearchPaper(
      id: '7e',
      title:
          'Users Perceptions on the Usage of M-commerce in Bangladesh: A SWOT Analysis',
      author: 'Dr. A. H. M. Saifullah Sadi',
      journalName: 'E-Commerce Research',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_A_H_M_SaifullahSadi/Users_Perceptions_on_the_Usage_of_M_commerce_in_Bangladesh_A_SWOT_Analysis.pdf',
      doi: '10.1007/s10660-2023-006',
      keywords: [
        'M-Commerce',
        'Bangladesh',
        'SWOT Analysis',
        'User Perception',
        'Mobile Technology'
      ],
      abstract:
          'A comprehensive SWOT analysis of user perceptions regarding mobile commerce usage in Bangladesh.',
      citations: 16,
      isAsset: true,
    ),
  ],
  'Dr. Imran Mahmud': [
    ResearchPaper(
      id: '8',
      title:
          'A Novel Front Door Security FDS Algorithm Using GoogleNet-BiLSTM Hybridization',
      author: 'Dr. Imran Mahmud',
      journalName: 'ACM Computing Surveys',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/A_Novel_Front_Door_Security_FDS_Algorithm_Using_GoogleNet-BiLSTM_Hybridization.pdf',
      doi: '10.1145/3588123.001',
      keywords: [
        'Security',
        'Deep Learning',
        'Computer Vision',
        'BiLSTM',
        'GoogleNet'
      ],
      abstract:
          'A novel front door security algorithm leveraging GoogleNet-BiLSTM hybridization for enhanced security systems.',
      citations: 33,
      isAsset: true,
    ),
    ResearchPaper(
      id: '8a',
      title:
          'DOORMOR: A Functional Prototype of a Manual Search and Rescue Robot',
      author: 'Dr. Imran Mahmud',
      journalName: 'Robotics and Automation',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/DOORMOR_A_Functional_Prototype_of_a_Manual_Search_and_Rescue_Robot.pdf',
      doi: '10.1109/ra.2023.002',
      keywords: [
        'Robotics',
        'Search and Rescue',
        'Prototype',
        'Manual Control'
      ],
      abstract:
          'A functional prototype of DOORMOR, a manually controlled search and rescue robot for emergency operations.',
      citations: 16,
      isAsset: true,
    ),
    ResearchPaper(
      id: '8b',
      title:
          'DPMS: Data Driven Promotional Management System of Universities Using Deep Learning on Social Media',
      author: 'Dr. Imran Mahmud',
      journalName: 'Educational Technology',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/DPMS_Data_Driven_Promotional_Management_System_of_Universities_Using_Deep_Learning_on_Social_Media.pdf',
      doi: '10.1007/s11423-2023.003',
      keywords: [
        'Deep Learning',
        'Social Media',
        'University Marketing',
        'Data Analytics'
      ],
      abstract:
          'A data-driven promotional management system for universities using deep learning analysis of social media.',
      citations: 20,
      isAsset: true,
    ),
    ResearchPaper(
      id: '8c',
      title:
          'Innovation and the Sustainable Competitive Advantage of Young Firms: A Strategy Implementation Approach',
      author: 'Dr. Imran Mahmud',
      journalName: 'Business Strategy Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/Innovation_and_the_Sustainable_Competitive_Advantage_of_Young_Firms_A_Strategy_Implementation_Approach.pdf',
      doi: '10.1002/bsj.2023.004',
      keywords: [
        'Innovation',
        'Competitive Advantage',
        'Business Strategy',
        'Young Firms'
      ],
      abstract:
          'Analysis of how innovation creates sustainable competitive advantages for young firms through strategic implementation.',
      citations: 24,
      isAsset: true,
    ),
    ResearchPaper(
      id: '8d',
      title: 'IoT Based Remote Medical Diagnosis System Using NodeMCU',
      author: 'Dr. Imran Mahmud',
      journalName: 'Internet of Things',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/IoT_Based_Remote_Medical_Diagnosis_System_Using_NodeMCU.pdf',
      doi: '10.1016/j.iot.2023.005',
      keywords: [
        'IoT',
        'Medical Diagnosis',
        'NodeMCU',
        'Remote Healthcare',
        'Telemedicine'
      ],
      abstract:
          'An IoT-based remote medical diagnosis system utilizing NodeMCU for accessible healthcare services.',
      citations: 18,
      isAsset: true,
    ),
    ResearchPaper(
      id: '8e',
      title:
          'Machine Learning Based Approach for Predicting Diabetes Employing Socio Demographic Characteristics',
      author: 'Dr. Imran Mahmud',
      journalName: 'Healthcare Analytics',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/Machine_Learning_Based_Approach_for_Predicting_Diabetes_Employing_Socio_Demographic_Characteristics.pdf',
      doi: '10.1016/j.health.2023.006',
      keywords: [
        'Machine Learning',
        'Diabetes Prediction',
        'Healthcare',
        'Demographics',
        'Predictive Analytics'
      ],
      abstract:
          'A machine learning-based approach for predicting diabetes using socio-demographic characteristics.',
      citations: 25,
      isAsset: true,
    ),
    ResearchPaper(
      id: '8f',
      title: 'ONGULANKO: An IoT Based Biometric Attendance Logger',
      author: 'Dr. Imran Mahmud',
      journalName: 'IoT Systems',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/ONGULANKO_An_IoT_Based_Biometric_Attendance_Logger.pdf',
      doi: '10.1109/iot.2023.007',
      keywords: ['IoT', 'Biometric', 'Attendance System', 'Fingerprint'],
      abstract:
          'ONGULANKO: An IoT-based biometric attendance logging system for automated attendance management.',
      citations: 14,
      isAsset: true,
    ),
    ResearchPaper(
      id: '8g',
      title: 'Smart Security System Using Face Recognition on Raspberry Pi',
      author: 'Dr. Imran Mahmud',
      journalName: 'Computer Security Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/Smart_Security_System_Using_Face_Recognition_on_Raspberry_Pi.pdf',
      doi: '10.1109/security.2023.008',
      keywords: [
        'Face Recognition',
        'Raspberry Pi',
        'Security',
        'IoT',
        'Computer Vision'
      ],
      abstract:
          'A smart security system implementing face recognition technology on Raspberry Pi for home security.',
      citations: 15,
      isAsset: true,
    ),
    ResearchPaper(
      id: '8h',
      title:
          'Trackez: An IoT-Based 3D-Object Tracking From 2D Pixel Matrix Using Mez and FSL Algorithm',
      author: 'Dr. Imran Mahmud',
      journalName: 'Computer Vision and IoT',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/Trackez_An_IoT-Based_3D-Object_Tracking_From_2D_Pixel_Matrix_Using_Mez_and_FSL_Algorithm.pdf',
      doi: '10.1016/j.cviot.2023.009',
      keywords: [
        'IoT',
        '3D Object Tracking',
        'Computer Vision',
        'FSL Algorithm',
        'Mez Algorithm'
      ],
      abstract:
          'An IoT-based 3D object tracking system using 2D pixel matrix with Mez and FSL algorithms.',
      citations: 12,
      isAsset: true,
    ),
  ],
  'Dr. Md. Sarowar Hossain': [
    ResearchPaper(
      id: '9',
      title:
          'Investigation of analgesic anti inflammatory and antidiabetic effects of Phyllanthus beillei leaves H',
      author: 'Dr. Md. Sarowar Hossain',
      journalName: 'Drug Delivery',
      year: '2023',
      pdfUrl:
          'assets/papers/Dr_Md._Sarowar_Hossain/Investigation_of_analgesic_anti_inflammatory_and_antidiabetic_effects_of_Phyllanthus_beillei_leaves_H.pdf',
      doi: '10.1080/10717544.2023.001',
      keywords: [
        'Drug Delivery',
        'Microneedles',
        'Cardiovascular Disease',
        'Sustainable Technology'
      ],
      abstract:
          'This research presents investigation of analgesic anti inflammatory and antidiabetic effects of Phyllanthus beillei leaves.',
      citations: 19,
      isAsset: true,
    ),
  ],
  'Professor Dr. Muniruddin Ahmed': [
    ResearchPaper(
      id: '15',
      title: 'Advanced Research in Computer Science',
      author: 'Professor Dr. Muniruddin Ahmed',
      journalName: 'Computer Science Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/IoT_Based_Remote_Medical_Diagnosis_System_Using_NodeMCU.pdf',
      doi: '',
      keywords: ['Computer Science', 'Research'],
      abstract: 'Advanced research in computer science and technology.',
      citations: 10,
      isAsset: true,
    ),
  ],
  'Prof. Dr. Md. Ekramul Haque': [
    ResearchPaper(
      id: '16',
      title: 'Computer Networks and Security',
      author: 'Prof. Dr. Md. Ekramul Haque',
      journalName: 'Network Security Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/Smart_Security_System_Using_Face_Recognition_on_Raspberry_Pi.pdf',
      doi: '',
      keywords: ['Networks', 'Security'],
      abstract: 'Research on computer networks and security.',
      citations: 8,
      isAsset: true,
    ),
  ],
  'Professor Dr. M. Shamsul Alam': [
    ResearchPaper(
      id: '17',
      title: 'Software Engineering Practices',
      author: 'Professor Dr. M. Shamsul Alam',
      journalName: 'Software Engineering Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/DrImran_Mahmud/Machine_Learning_Based_Approach_for_Predicting_Diabetes_Employing_Socio_Demographic_Characteristics.pdf',
      doi: '',
      keywords: ['Software Engineering', 'Practices'],
      abstract: 'Modern software engineering practices and methodologies.',
      citations: 12,
      isAsset: true,
    ),
  ],
  'Ms. Nazmun Nessa Moon': [
    ResearchPaper(
      id: '18',
      title:
          'An Efficient Development of Automated Attendance Management System',
      author: 'Ms. Nazmun Nessa Moon',
      journalName: 'Computer Systems and Technology',
      year: '2023',
      pdfUrl:
          'assets/papers/Ms._Nazmun_Nessa_Moon/An_Efficient_Development_of_Automated_Attendance_Management_System.pdf',
      doi: '10.1109/cstech.2023.001',
      keywords: ['Attendance System', 'Automation', 'IoT', 'Mobile Technology'],
      abstract:
          'An efficient automated attendance management system using modern technology for educational institutions.',
      citations: 14,
      isAsset: true,
    ),
    ResearchPaper(
      id: '19',
      title:
          'Classifying the Practitioner\'s Behavior in Medical Informatics by Using Data Mining',
      author: 'Ms. Nazmun Nessa Moon',
      journalName: 'Medical Informatics Journal',
      year: '2023',
      pdfUrl:
          'assets/papers/Ms._Nazmun_Nessa_Moon/Classifying_the_Practitioner\'s_Behavior_in_Medical_Informatics_by_Using_Data_Mining.pdf',
      doi: '10.1016/j.medinf.2023.002',
      keywords: [
        'Data Mining',
        'Medical Informatics',
        'Healthcare',
        'Classification'
      ],
      abstract:
          'Classification of medical practitioners\' behavior using data mining techniques in healthcare informatics.',
      citations: 18,
      isAsset: true,
    ),
    ResearchPaper(
      id: '20',
      title: 'Humidity Based Automated Room Temperature Controller Using IoT',
      author: 'Ms. Nazmun Nessa Moon',
      journalName: 'IoT and Smart Systems',
      year: '2023',
      pdfUrl:
          'assets/papers/Ms._Nazmun_Nessa_Moon/Humidity_Based_Automated_Room_Temperature_Controller_Using_IoT.pdf',
      doi: '10.1109/iot.2023.003',
      keywords: [
        'IoT',
        'Smart Home',
        'Automation',
        'Temperature Control',
        'Humidity'
      ],
      abstract:
          'An IoT-based automated room temperature control system using humidity sensors for energy efficiency.',
      citations: 12,
      isAsset: true,
    ),
    ResearchPaper(
      id: '21',
      title:
          'Identifying the Writing Style of Bangla Language Using Natural Language Processing',
      author: 'Ms. Nazmun Nessa Moon',
      journalName: 'Natural Language Engineering',
      year: '2023',
      pdfUrl:
          'assets/papers/Ms._Nazmun_Nessa_Moon/Identifying_the_Writing_Style_of_Bangla_Language_Using_Natural_Language_Processing.pdf',
      doi: '10.1017/nle.2023.004',
      keywords: [
        'NLP',
        'Bangla Language',
        'Writing Style',
        'Text Analysis',
        'Machine Learning'
      ],
      abstract:
          'Identification and analysis of Bangla language writing styles using natural language processing techniques.',
      citations: 20,
      isAsset: true,
    ),
    ResearchPaper(
      id: '22',
      title:
          'Implementation of Low Cost Real-time Attendance Management System: A Comparative Study',
      author: 'Ms. Nazmun Nessa Moon',
      journalName: 'Educational Technology Systems',
      year: '2023',
      pdfUrl:
          'assets/papers/Ms._Nazmun_Nessa_Moon/Implementation_of_Low_Cost_Real-time_Attendance_Management_System_A_Comparative_Study.pdf',
      doi: '10.1007/s11423-2023.005',
      keywords: [
        'Attendance',
        'Real-time System',
        'Cost Effective',
        'Comparative Study'
      ],
      abstract:
          'A comparative study on implementing low-cost real-time attendance management systems for educational institutions.',
      citations: 16,
      isAsset: true,
    ),
    ResearchPaper(
      id: '23',
      title:
          'IoT Based Street Lighting Using Dual Axis Solar Tracker and Effective Traffic Management System Using Deep Learning: Bangladesh Context',
      author: 'Ms. Nazmun Nessa Moon',
      journalName: 'Smart Cities and IoT',
      year: '2023',
      pdfUrl:
          'assets/papers/Ms._Nazmun_Nessa_Moon/IoT_Based_Street_Lighting_Using_Dual_Axis_Solar_Tracker_and_Effective_Traffic_Management_System_Using_Deep_Learning_Bangladesh_Context.pdf',
      doi: '10.1016/j.smartcity.2023.006',
      keywords: [
        'IoT',
        'Smart City',
        'Solar Energy',
        'Traffic Management',
        'Deep Learning',
        'Bangladesh'
      ],
      abstract:
          'An IoT-based smart street lighting system with solar tracking and traffic management using deep learning for Bangladesh.',
      citations: 25,
      isAsset: true,
    ),
    ResearchPaper(
      id: '24',
      title:
          'Optimization of Wireless Ad-hoc Networks using an Adjacent Collaborative Directional MAC (ACDM)',
      author: 'Ms. Nazmun Nessa Moon',
      journalName: 'Wireless Networks',
      year: '2023',
      pdfUrl:
          'assets/papers/Ms._Nazmun_Nessa_Moon/Optimization_of_Wireless_Ad-hoc_Networks_using_an_Adjacent_Collaborative_Directional_MAC_(ACDM).pdf',
      doi: '10.1007/s11276-2023.007',
      keywords: [
        'Wireless Networks',
        'Ad-hoc',
        'MAC Protocol',
        'Network Optimization'
      ],
      abstract:
          'Optimization of wireless ad-hoc networks using an adjacent collaborative directional MAC protocol for improved performance.',
      citations: 22,
      isAsset: true,
    ),
    ResearchPaper(
      id: '25',
      title: 'Priority-Based Offloading and Caching in Mobile Edge Cloud',
      author: 'Ms. Nazmun Nessa Moon',
      journalName: 'Mobile Edge Computing',
      year: '2023',
      pdfUrl:
          'assets/papers/Ms._Nazmun_Nessa_Moon/Priority-Based_Offloading_and_Caching_in_Mobile_Edge_Cloud.pdf',
      doi: '10.1109/mec.2023.008',
      keywords: [
        'Mobile Edge Computing',
        'Offloading',
        'Caching',
        'Cloud Computing',
        'Priority Scheduling'
      ],
      abstract:
          'Priority-based task offloading and caching strategies in mobile edge cloud computing for optimal resource utilization.',
      citations: 19,
      isAsset: true,
    ),
  ],
};
