class CopsoqQuestion {
  final String id;
  final int number;
  final String text;
  final String dimensionId;
  final String dimensionName;
  final String domainId;
  final String domainName;
  final bool isInverted;
  final String scaleType; // 'frequency' or 'intensity'

  const CopsoqQuestion({
    required this.id,
    required this.number,
    required this.text,
    required this.dimensionId,
    required this.dimensionName,
    required this.domainId,
    required this.domainName,
    this.isInverted = false,
    this.scaleType = 'frequency',
  });
}

class CopsoqDimension {
  final String id;
  final String name;
  final String domainId;
  final String domainName;
  final List<String> questionIds;

  const CopsoqDimension({
    required this.id,
    required this.name,
    required this.domainId,
    required this.domainName,
    required this.questionIds,
  });
}
