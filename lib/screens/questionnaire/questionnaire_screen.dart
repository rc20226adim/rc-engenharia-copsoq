import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/response_model.dart';
import '../../models/copsoq_data.dart';
import '../../models/copsoq_model.dart';
import '../../providers/app_provider.dart';
import '../../services/copsoq_calculator.dart';
import '../../utils/app_theme.dart';
import 'questionnaire_result_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final QuestionnaireResponse response;
  const QuestionnaireScreen({super.key, required this.response});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final Map<String, int> _answers = {};
  final PageController _pageController = PageController();
  int _currentDomainIndex = 0;
  bool _isSubmitting = false;

  // Agrupar questões por domínio
  late final List<MapEntry<String, List<CopsoqQuestion>>> _domainGroups;

  @override
  void initState() {
    super.initState();
    _answers.addAll(widget.response.answers);
    _buildDomainGroups();
  }

  void _buildDomainGroups() {
    final Map<String, List<CopsoqQuestion>> groups = {};
    for (final q in CopsoqData.questions) {
      groups.putIfAbsent(q.domainName, () => []).add(q);
    }
    _domainGroups = groups.entries.toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _totalQuestions => CopsoqData.questions.length;
  int get _answeredQuestions => _answers.length;
  double get _progress => _answeredQuestions / _totalQuestions;

  bool _isDomainComplete(List<CopsoqQuestion> questions) {
    return questions.every((q) => _answers.containsKey(q.id));
  }

  void _goNext() {
    final currentDomainQs = _domainGroups[_currentDomainIndex].value;
    if (!_isDomainComplete(currentDomainQs)) {
      final unanswered =
          currentDomainQs.where((q) => !_answers.containsKey(q.id)).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Responda todas as perguntas desta seção. Faltam $unanswered.'),
        backgroundColor: AppTheme.riskYellow,
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    if (_currentDomainIndex < _domainGroups.length - 1) {
      setState(() => _currentDomainIndex++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submitQuestionnaire();
    }
  }

  void _goPrev() {
    if (_currentDomainIndex > 0) {
      setState(() => _currentDomainIndex--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitQuestionnaire() async {
    setState(() => _isSubmitting = true);

    // Calcular scores LOCALMENTE — imediato, sem depender do Firestore
    final scores = CopsoqCalculator.calculateDimensionScores(_answers);
    final colors = CopsoqCalculator.calculateColors(scores);

    final completed = QuestionnaireResponse(
      id: widget.response.id,
      companyId: widget.response.companyId,
      companyName: widget.response.companyName,
      sector: widget.response.sector,
      city: widget.response.city,
      state: widget.response.state,
      jobRole: widget.response.jobRole,
      department: widget.response.department,
      employeeName: widget.response.employeeName,
      gender: widget.response.gender,
      ageRange: widget.response.ageRange,
      education: widget.response.education,
      contractType: widget.response.contractType,
      workShift: widget.response.workShift,
      yearsInCompany: widget.response.yearsInCompany,
      answers: _answers,
      dimensionScores: scores,
      dimensionColors: colors,
      submittedAt: DateTime.now(),
      isCompleted: true,
    );

    // Salvar em background — não bloqueia navegação
    context.read<AppProvider>().submitResponse(completed).timeout(
      const Duration(seconds: 15),
      onTimeout: () {},
    ).catchError((e) {
      debugPrint('Submit background error (não crítico): $e');
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      // Navegar IMEDIATAMENTE com o objeto já calculado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionnaireResultScreen(response: completed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastDomain = _currentDomainIndex == _domainGroups.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Questionário COPSOQ (${_currentDomainIndex + 1}/${_domainGroups.length})',
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _currentDomainIndex > 0 ? _goPrev : null,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              '$_answeredQuestions/$_totalQuestions',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            height: 6,
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress.clamp(0.0, 1.0),
              child: Container(color: AppTheme.accentBlue),
            ),
          ),
          // Domain tab indicator
          Container(
            color: AppTheme.primaryBlue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _domainGroups[_currentDomainIndex].key,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(_progress * 100).toInt()}% concluído',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Questions list
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _domainGroups.length,
              itemBuilder: (context, domainIndex) {
                final entry = _domainGroups[domainIndex];
                final questions = entry.value;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length + 1,
                  itemBuilder: (ctx, idx) {
                    if (idx == 0) {
                      return _DomainHeader(
                          domainName: entry.key,
                          questionCount: questions.length);
                    }
                    final q = questions[idx - 1];
                    return _QuestionCard(
                      question: q,
                      selectedValue: _answers[q.id],
                      onChanged: (val) {
                        setState(() => _answers[q.id] = val);
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Bottom navigation
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentDomainIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _goPrev,
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        label: const Text('Anterior'),
                      ),
                    ),
                  if (_currentDomainIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _goNext,
                            icon: Icon(
                              isLastDomain
                                  ? Icons.check_circle
                                  : Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            label: Text(
                                isLastDomain ? 'Finalizar' : 'Próxima Seção'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLastDomain
                                  ? AppTheme.riskGreen
                                  : AppTheme.accentBlue,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainHeader extends StatelessWidget {
  final String domainName;
  final int questionCount;
  const _DomainHeader(
      {required this.domainName, required this.questionCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  domainName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                Text(
                  '$questionCount questões nesta seção',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final CopsoqQuestion question;
  final int? selectedValue;
  final void Function(int) onChanged;

  const _QuestionCard({
    required this.question,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scale = question.scaleType == 'frequency'
        ? CopsoqData.frequencyScale
        : CopsoqData.intensityScale;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: selectedValue != null ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: selectedValue != null
            ? const BorderSide(color: AppTheme.accentBlue, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number + text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedValue != null
                        ? AppTheme.accentBlue
                        : AppTheme.backgroundBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${question.number}',
                    style: TextStyle(
                      color: selectedValue != null
                          ? Colors.white
                          : AppTheme.darkGray,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGray,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dimension label
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                question.dimensionName,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            // Answer options
            Column(
              children: List.generate(scale.length, (i) {
                final val = i + 1;
                final isSelected = selectedValue == val;
                return InkWell(
                  onTap: () => onChanged(val),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentBlue
                          : AppTheme.backgroundBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentBlue
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.gray,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 12, color: AppTheme.accentBlue)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${val}. ${scale[i]}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.darkGray,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
