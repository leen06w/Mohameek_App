import '../models/lawyer.dart';
import '../models/legal_case.dart';
import '../models/request_item.dart';

class DashboardStat {
  final String label;
  final String value;
  final String? note;

  const DashboardStat(this.label, this.value, [this.note]);
}

class MockData {
  static const demoCredentials = {
    'user@test.com': {
      'password': '123',
      'role': 'user',
      'path': '/user/dashboard'
    },
    'lawyer@test.com': {
      'password': '123',
      'role': 'lawyer',
      'path': '/lawyer/dashboard'
    },
    'admin@test.com': {
      'password': '123',
      'role': 'admin',
      'path': '/admin/dashboard'
    },
  };

  static const quickQuestions = [
    'كيف أرفع دعوى قضائية؟',
    'ما هي حقوقي في عقد العمل؟',
    'أحتاج استشارة عقارية',
  ];

  static const fallbackLegalResponses = [
    'بناءً على القوانين السعودية، يمكن البدء بجمع المستندات ثم تحديد الجهة القضائية أو الإدارية المختصة.',
    'من المهم مراجعة العقد أو المستند محل النزاع قبل اتخاذ أي إجراء نظامي.',
    'أنصحك بالاستفادة من استشارة محامٍ مختص لأن التفاصيل الدقيقة قد تغيّر التكييف القانوني بالكامل.',
    'هذه إجابة عامة أولية ولا تغني عن استشارة قانونية مرخصة مبنية على مستندات القضية.',
  ];

  static const List<Lawyer> lawyers = [
    Lawyer(
      id: '1',
      name: 'د. أحمد محمد العلي',
      specialty: 'القانون التجاري',
      rating: 4.9,
      reviews: 150,
      cases: 200,
      city: 'الرياض',
      price: '500',
      casesCount: '150',
      experience: '15 سنة',
      lat: 24.7136,
      lng: 46.6753,
      email: 'ahmad@mahamik.sa',
      phone: '+966 50 123 4567',
      officeName: 'مكتب العلي للمحاماة والاستشارات القانونية',
      officeAddress: 'طريق الملك فهد، حي العليا، الرياض 12211',
      workHours: 'الأحد - الخميس: 9:00 ص - 5:00 م',
      bio:
          'محامٍ مرخص متخصص في القانون التجاري والشركات بخبرة تزيد عن 15 عاماً في المحاماة والاستشارات القانونية.',
      licenseNumber: '12345678',
    ),
    Lawyer(
      id: '2',
      name: 'د. سارة عبدالله',
      specialty: 'قانون الأسرة',
      rating: 4.8,
      reviews: 120,
      casesCount: '150',
      cases: 180,
      city: 'جدة',
      price: '450',
      experience: '12 سنة',
      lat: 21.5433,
      lng: 39.1728,
      email: 'sara@mahamik.sa',
      phone: '+966 55 987 6543',
      officeName: 'مكتب الأسرة والاستشارات',
      officeAddress: 'شارع الأمير سلطان، جدة، المملكة العربية السعودية',
      workHours: 'الأحد - الخميس: 10:00 ص - 6:00 م',
      bio:
          'متخصصة في قضايا الأسرة والأحوال الشخصية وصياغة الاتفاقيات الأسرية وتسوية النزاعات بالطرق الودية والقضائية.',
      licenseNumber: '22334455',
    ),
    Lawyer(
      id: '3',
      name: 'د. خالد السعيد',
      specialty: 'القانون الجنائي',
      rating: 4.7,
      reviews: 200,
      casesCount: '150',
      cases: 250,
      city: 'الدمام',
      price: '600',
      experience: '18 سنة',
      lat: 26.4207,
      lng: 50.0888,
      email: 'khaled@mahamik.sa',
      phone: '+966 54 321 0987',
      officeName: 'مكتب السعيد للمرافعات',
      officeAddress: 'حي المزروعية، الدمام، المملكة العربية السعودية',
      workHours: 'الأحد - الخميس: 9:30 ص - 5:30 م',
      bio:
          'متخصص في القضايا الجنائية وتمثيل المتقاضين أمام المحاكم والنيابات مع خبرة واسعة في الاستشارات الوقائية.',
      licenseNumber: '88776655',
    ),
    Lawyer(
      id: '4',
      name: 'د. فاطمة محمود',
      specialty: 'القانون العقاري',
      rating: 4.9,
      reviews: 95,
      casesCount: '150',
      cases: 140,
      city: 'الرياض',
      price: '550',
      experience: '10 سنوات',
      lat: 24.7743,
      lng: 46.7386,
      email: 'fatimah@mahamik.sa',
      phone: '+966 53 111 2222',
      officeName: 'المكتب العقاري القانوني',
      officeAddress: 'طريق الملك فهد، الرياض، المملكة العربية السعودية',
      workHours: 'الأحد - الخميس: 9:00 ص - 4:30 م',
      bio:
          'خبرة في المنازعات العقارية وصياغة عقود البيع والإيجار والفرز والتطوير العقاري.',
      licenseNumber: '55667788',
    ),
    Lawyer(
      id: '5',
      name: 'د. عمر حسن',
      specialty: 'قانون العمل',
      rating: 4.6,
      reviews: 110,
      casesCount: '150',
      cases: 160,
      city: 'جدة',
      price: '400',
      experience: '8 سنوات',
      lat: 21.5721,
      lng: 39.1618,
      email: 'omar@mahamik.sa',
      phone: '+966 56 333 4444',
      officeName: 'مكتب العمل والأنظمة',
      officeAddress: 'حي الروضة، جدة، المملكة العربية السعودية',
      workHours: 'الأحد - الخميس: 8:30 ص - 4:30 م',
      bio:
          'يعالج قضايا الفصل التعسفي والحقوق العمالية والعقود وسياسات الامتثال في المنشآت.',
      licenseNumber: '33445566',
    ),
  ];

  static const List<LegalCase> userCases = [
    LegalCase(
      id: '1',
      title: 'قضية تجارية',
      client: 'أنا',
      type: 'تجارية',
      status: 'قيد المراجعة',
      progress: 60,
      updatedAt: '2026-04-01',
    ),
    LegalCase(
      id: '2',
      title: 'استشارة قانونية',
      client: 'أنا',
      type: 'استشارة',
      status: 'مكتملة',
      progress: 100,
      updatedAt: '2026-03-28',
    ),
    LegalCase(
      id: '3',
      title: 'نزاع عقد عمل',
      client: 'أنا',
      type: 'عمالية',
      status: 'نشطة',
      progress: 35,
      updatedAt: '2026-04-05',
    ),
  ];

  static const List<LegalCase> lawyerCases = [
    LegalCase(
      id: '1',
      title: 'قضية عقارية',
      client: 'أحمد محمد',
      type: 'عقارية',
      status: 'قيد المراجعة',
      progress: 60,
      updatedAt: '2026-04-01',
    ),
    LegalCase(
      id: '2',
      title: 'قضية تجارية',
      client: 'شركة النور',
      type: 'تجارية',
      status: 'نشطة',
      progress: 40,
      updatedAt: '2026-04-03',
    ),
    LegalCase(
      id: '3',
      title: 'استشارة أسرية',
      client: 'سارة علي',
      type: 'أسرية',
      status: 'مكتملة',
      progress: 100,
      updatedAt: '2026-03-29',
    ),
  ];

  static const List<RequestItem> requests = [
    RequestItem(
      id: '1',
      lawyerName: 'د. أحمد محمد',
      lawyerSpecialty: 'القانون التجاري',
      consultationType: 'استشارة عن بعد',
      preferredDate: '2026-04-08',
      preferredTime: '10:00 صباحاً',
      caseType: 'قضايا تجارية',
      description:
          'أحتاج استشارة قانونية حول عقد شراكة تجارية جديدة وتوزيع الأرباح.',
      status: 'accepted',
      submittedAt: '2026-04-06 09:30',
      price: '500',
      negotiationNote: 'تم قبول طلبك. يرجى الدفع لتأكيد الموعد.',
    ),
    RequestItem(
      id: '2',
      lawyerName: 'د. سارة العلي',
      lawyerSpecialty: 'قانون الأسرة',
      consultationType: 'حضوري',
      preferredDate: '2026-04-09',
      preferredTime: '02:00 مساءً',
      caseType: 'قضايا أسرية',
      description: 'استشارة حول قضية حضانة أطفال ومتابعة إجراءاتها القانونية.',
      status: 'negotiating',
      submittedAt: '2026-04-06 11:15',
      price: '600',
      negotiationNote:
          'المحامي يقترح تغيير الموعد إلى 2026-04-10 الساعة 03:00 مساءً. الرسوم: 600 ر.س',
    ),
    RequestItem(
      id: '3',
      lawyerName: 'د. خالد السعيد',
      lawyerSpecialty: 'القانون الجنائي',
      consultationType: 'هاتفي',
      preferredDate: '2026-04-07',
      preferredTime: '04:00 مساءً',
      caseType: 'قضايا جنائية',
      description: 'استشارة عاجلة حول قضية جنائية وإجراءات الدفاع.',
      status: 'pending',
      submittedAt: '2026-04-06 14:20',
    ),
    RequestItem(
      id: '4',
      lawyerName: 'د. فاطمة أحمد',
      lawyerSpecialty: 'القانون العقاري',
      consultationType: 'استشارة عن بعد',
      preferredDate: '2026-04-11',
      preferredTime: '01:00 مساءً',
      caseType: 'قضايا عقارية',
      description: 'مراجعة عقد بيع عقاري والتأكد من التزامات الأطراف.',
      status: 'rejected',
      submittedAt: '2026-04-07 10:00',
      negotiationNote: 'اعتذر المحامي عن قبول الطلب بسبب تعارض الموعد.',
    ),
  ];
}
