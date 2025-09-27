import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/models/education_model.dart';
import '../../data/services/course_service.dart';
import '../providers/app_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final CourseProgress? existingProgress;

  const CourseDetailScreen({
    Key? key,
    required this.course,
    this.existingProgress,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late YoutubePlayerController _youtubeController;
  bool _isQuizStarted = false;
  int _currentQuestionIndex = 0;
  int _selectedAnswer = -1;
  bool _showExplanation = false;
  int _correctAnswers = 0;
  List<int> _userAnswers = [];
  bool _isSaving = false; // Agregado para mostrar indicador de carga

  @override
  void initState() {
    super.initState();
    final videoId = CourseService.extractYouTubeId(widget.course.videoUrl);
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false),
    );
    
    // Si ya existe progreso, cargar el estado del quiz
    if (widget.existingProgress != null && widget.existingProgress!.isCompleted) {
      _correctAnswers = widget.existingProgress!.score;
      _userAnswers = widget.existingProgress!.userAnswers;
    }
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.course.title),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          body: _isQuizStarted ? _buildQuizView() : _buildCourseView(player),
        );
      },
    );
  }

  Widget _buildCourseView(Widget player) {
    // Verificar si el curso ya fue completado
    final appProvider = context.watch<AppProvider>();
    final isCompleted = appProvider.isCourseCompleted(widget.course.id);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          player,
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.course.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(widget.course.description),
                const SizedBox(height: 24),
                
                // Mostrar estado si ya está completado
                if (isCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¡Curso Completado!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (widget.existingProgress != null)
                                Text(
                                  'Puntuación: ${widget.existingProgress!.score}/${widget.existingProgress!.totalQuestions} (${widget.existingProgress!.percentage.toInt()}%)',
                                  style: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _isQuizStarted = true),
                    child: const Text('Intentar de Nuevo'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: () => setState(() => _isQuizStarted = true),
                    child: const Text('Empezar Examen'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    if (_currentQuestionIndex >= widget.course.questions.length) {
      return _buildResults();
    }

    final question = widget.course.questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Indicador de progreso
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.course.questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 20),
          Text('Pregunta ${_currentQuestionIndex + 1} de ${widget.course.questions.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Text(question.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...List.generate(
            question.options.length,
            (index) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<int>(
                title: Text(question.options[index]),
                value: index,
                groupValue: _selectedAnswer,
                onChanged: _showExplanation ? null : (value) => setState(() => _selectedAnswer = value!),
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          if (_showExplanation)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedAnswer == question.correctAnswerIndex ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedAnswer == question.correctAnswerIndex ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedAnswer == question.correctAnswerIndex ? Icons.check_circle : Icons.cancel,
                        color: _selectedAnswer == question.correctAnswerIndex ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedAnswer == question.correctAnswerIndex ? '¡Correcto!' : 'Incorrecto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedAnswer == question.correctAnswerIndex ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(question.explanation),
                ],
              ),
            ),
          const Spacer(),
          if (_selectedAnswer != -1)
            ElevatedButton(
              onPressed: () {
                if (!_showExplanation) {
                  // Verificar respuesta
                  if (_selectedAnswer == question.correctAnswerIndex) _correctAnswers++;
                  _userAnswers.add(_selectedAnswer);
                  setState(() => _showExplanation = true);
                } else {
                  // Siguiente pregunta
                  setState(() {
                    _currentQuestionIndex++;
                    _selectedAnswer = -1;
                    _showExplanation = false;
                  });
                }
              },
              child: Text(_showExplanation ? 'Siguiente Pregunta' : 'Verificar Respuesta'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final percentage = (_correctAnswers / widget.course.questions.length * 100).round();
    final points = (_correctAnswers / widget.course.questions.length * widget.course.maxPoints).round();
    final bool isPerfect = _correctAnswers == widget.course.questions.length;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado según el resultado
            Icon(
              isPerfect ? Icons.emoji_events : (percentage >= 70 ? Icons.check_circle : Icons.replay),
              size: 80,
              color: isPerfect ? Colors.amber : (percentage >= 70 ? Colors.green : Colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              isPerfect ? '¡Perfecto!' : (percentage >= 70 ? '¡Examen Completado!' : 'Inténtalo de Nuevo'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Círculo de porcentaje
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: percentage >= 70 ? Colors.green : Colors.red,
                  width: 4,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: percentage >= 70 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '$_correctAnswers de ${widget.course.questions.length}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Puntos ganados
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    'Has ganado $points puntos',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Botón de finalizar con indicador de carga
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveProgressAndExit(points),
              child: _isSaving 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Finalizar y Guardar'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: percentage >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            // Botón de reintentar si no aprobó
            if (percentage < 70)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isQuizStarted = false;
                    _currentQuestionIndex = 0;
                    _selectedAnswer = -1;
                    _showExplanation = false;
                    _correctAnswers = 0;
                    _userAnswers = [];
                  });
                },
                child: const Text('Volver a Intentar'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProgressAndExit(int points) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Guardar progreso
      await context.read<AppProvider>().saveCourseProgress(
        courseId: widget.course.id,
        score: _correctAnswers,
        totalQuestions: widget.course.questions.length,
        userAnswers: _userAnswers,
        pointsEarned: points,
      );
      
      if (!mounted) return;
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('¡Curso completado! +$points puntos'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Esperar un momento para que el usuario vea el mensaje
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Navegar de vuelta
      Navigator.pop(context, true); // Retornar true para indicar que se guardó
      
    } catch (e) {
      // Manejar error
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Error al guardar el progreso'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      
      debugPrint('Error al guardar progreso: $e');
    }
  }
}