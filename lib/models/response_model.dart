class QuestionnaireResponse {
  final String id;
  final String companyId;
  final String companyName;
  final String sector;
  final String city;
  final String state;
  final String jobRole;
  final String department;
  final String employeeName;
  final String gender;
  final String ageRange;
  final String education;
  final String contractType;
  final String workShift;
  final int yearsInCompany;
  final Map<String, int> answers; // questionId -> score 1-5
  final Map<String, double> dimensionScores; // dimensionId -> avg score
  final Map<String, String> dimensionColors; // dimensionId -> green/yellow/red
  final DateTime submittedAt;
  bool isCompleted;

  QuestionnaireResponse({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.sector,
    required this.city,
    required this.state,
    required this.jobRole,
    required this.department,
    required this.employeeName,
    required this.gender,
    required this.ageRange,
    required this.education,
    required this.contractType,
    required this.workShift,
    required this.yearsInCompany,
    required this.answers,
    required this.dimensionScores,
    required this.dimensionColors,
    required this.submittedAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'companyId': companyId,
    'companyName': companyName,
    'sector': sector,
    'city': city,
    'state': state,
    'jobRole': jobRole,
    'department': department,
    'employeeName': employeeName,
    'gender': gender,
    'ageRange': ageRange,
    'education': education,
    'contractType': contractType,
    'workShift': workShift,
    'yearsInCompany': yearsInCompany,
    'answers': answers,
    'dimensionScores': dimensionScores,
    'dimensionColors': dimensionColors,
    'submittedAt': submittedAt.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory QuestionnaireResponse.fromMap(Map<String, dynamic> map, [String? docId]) =>
      QuestionnaireResponse(
        id: docId ?? map['id'] ?? '',
        companyId: map['companyId'] ?? '',
        companyName: map['companyName'] ?? '',
        sector: map['sector'] ?? '',
        city: map['city'] ?? '',
        state: map['state'] ?? '',
        jobRole: map['jobRole'] ?? '',
        department: map['department'] ?? '',
        employeeName: map['employeeName'] ?? '',
        gender: map['gender'] ?? '',
        ageRange: map['ageRange'] ?? '',
        education: map['education'] ?? '',
        contractType: map['contractType'] ?? '',
        workShift: map['workShift'] ?? '',
        yearsInCompany: (map['yearsInCompany'] as num?)?.toInt() ?? 0,
        answers: Map<String, int>.from(
            (map['answers'] as Map<String, dynamic>? ?? {}).map(
                (k, v) => MapEntry(k, (v as num).toInt()))),
        dimensionScores: Map<String, double>.from(
            (map['dimensionScores'] as Map<String, dynamic>? ?? {}).map(
                (k, v) => MapEntry(k, (v as num).toDouble()))),
        dimensionColors: Map<String, String>.from(map['dimensionColors'] ?? {}),
        submittedAt: map['submittedAt'] is DateTime
            ? (map['submittedAt'] as DateTime)
            : DateTime.tryParse(map['submittedAt']?.toString() ?? '') ?? DateTime.now(),
        isCompleted: map['isCompleted'] ?? false,
      );
}
