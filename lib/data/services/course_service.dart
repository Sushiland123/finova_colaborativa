import '../models/education_model.dart';

class CourseService {
  static List<Course> getAllCourses() {
    return [
      Course(
        id: 'course_1',
        title: 'Evita Gastos Vampiro',
        description: 'Identifica y elimina esos pequeños gastos que drenan tu dinero sin que te des cuenta.',
        thumbnailUrl: 'https://img.youtube.com/vi/Of1490doP8c/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=Of1490doP8c',
        durationMinutes: 15,
        category: 'Ahorro',
        difficulty: 'Fácil',
        questions: [
          QuizQuestion(
            question: '¿Qué son los gastos vampiro?',
            options: [
              'Gastos grandes e importantes',
              'Pequeños gastos recurrentes que pasan desapercibidos',
              'Gastos en entretenimiento',
              'Gastos médicos',
            ],
            correctAnswerIndex: 1,
            explanation: 'Los gastos vampiro son pequeños gastos recurrentes que drenan tu dinero sin que te des cuenta, como suscripciones no utilizadas.',
          ),
          QuizQuestion(
            question: '¿Cuál es un ejemplo típico de gasto vampiro?',
            options: [
              'Pago de renta',
              'Compra de comida',
              'Suscripción a servicio que no usas',
              'Gastos médicos',
            ],
            correctAnswerIndex: 2,
            explanation: 'Las suscripciones a servicios que no utilizas son el ejemplo perfecto de gastos vampiro.',
          ),
          QuizQuestion(
            question: '¿Cómo puedes identificar gastos vampiro?',
            options: [
              'Ignorando tus estados de cuenta',
              'Revisando detalladamente tus gastos mensuales',
              'Gastando más dinero',
              'No usando tarjetas de crédito',
            ],
            correctAnswerIndex: 1,
            explanation: 'Revisar detalladamente tus estados de cuenta te ayuda a identificar gastos pequeños recurrentes.',
          ),
          QuizQuestion(
            question: '¿Qué porcentaje de tu ingreso pueden representar los gastos vampiro?',
            options: [
              '1-2%',
              '5-10%',
              '10-20%',
              '30-40%',
            ],
            correctAnswerIndex: 2,
            explanation: 'Los gastos vampiro pueden representar entre 10-20% de tus ingresos sin que te des cuenta.',
          ),
          QuizQuestion(
            question: '¿Cuál es la mejor estrategia para eliminar gastos vampiro?',
            options: [
              'Cancelar todos los servicios',
              'Hacer una auditoría mensual de gastos',
              'No revisar los estados de cuenta',
              'Gastar todo en efectivo',
            ],
            correctAnswerIndex: 1,
            explanation: 'Una auditoría mensual de gastos te permite identificar y eliminar gastos innecesarios.',
          ),
        ],
      ),
      
      Course(
        id: 'course_2',
        title: 'Método 50/30/20 de Presupuesto',
        description: 'Aprende la regla de oro para distribuir tus ingresos de manera inteligente.',
        thumbnailUrl: 'https://img.youtube.com/vi/Gqfh_Ul_Uu0/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=Gqfh_Ul_Uu0',
        durationMinutes: 20,
        category: 'Presupuesto',
        difficulty: 'Fácil',
        questions: [
          QuizQuestion(
            question: '¿Qué porcentaje se destina a necesidades en el método 50/30/20?',
            options: [
              '20%',
              '30%',
              '50%',
              '70%',
            ],
            correctAnswerIndex: 2,
            explanation: 'El 50% de tus ingresos debe destinarse a necesidades básicas como vivienda, comida y servicios.',
          ),
          QuizQuestion(
            question: '¿Qué se considera como "deseos" en este método?',
            options: [
              'Renta y servicios',
              'Entretenimiento y lujos',
              'Ahorro e inversión',
              'Seguros médicos',
            ],
            correctAnswerIndex: 1,
            explanation: 'Los deseos incluyen entretenimiento, cenas fuera, hobbies y otros gastos no esenciales.',
          ),
          QuizQuestion(
            question: '¿Qué porcentaje se destina al ahorro?',
            options: [
              '10%',
              '20%',
              '30%',
              '50%',
            ],
            correctAnswerIndex: 1,
            explanation: 'El 20% de tus ingresos debe destinarse al ahorro y pago de deudas.',
          ),
          QuizQuestion(
            question: '¿En qué categoría entra el pago de deudas?',
            options: [
              'Necesidades',
              'Deseos',
              'Ahorro (20%)',
              'No está incluido',
            ],
            correctAnswerIndex: 2,
            explanation: 'El pago de deudas se incluye en el 20% destinado al ahorro.',
          ),
          QuizQuestion(
            question: '¿Es flexible la regla 50/30/20?',
            options: [
              'No, debe seguirse exactamente',
              'Sí, se puede ajustar según tu situación',
              'Solo el 30% es flexible',
              'Solo el 20% es flexible',
            ],
            correctAnswerIndex: 1,
            explanation: 'La regla es una guía que puedes ajustar según tu situación personal y metas financieras.',
          ),
        ],
      ),
      
      Course(
        id: 'course_3',
        title: 'Fondo de Emergencia',
        description: 'Cómo crear tu colchón financiero para imprevistos y dormir tranquilo.',
        thumbnailUrl: 'https://img.youtube.com/vi/4j2emMn7UaI/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=4j2emMn7UaI',
        durationMinutes: 12,
        category: 'Ahorro',
        difficulty: 'Medio',
        questions: [
          QuizQuestion(
            question: '¿Cuántos meses de gastos debe cubrir un fondo de emergencia?',
            options: [
              '1-2 meses',
              '3-6 meses',
              '12 meses',
              '24 meses',
            ],
            correctAnswerIndex: 1,
            explanation: 'Lo ideal es tener entre 3 a 6 meses de gastos básicos cubiertos.',
          ),
          QuizQuestion(
            question: '¿Dónde es mejor guardar el fondo de emergencia?',
            options: [
              'En casa bajo el colchón',
              'En inversiones de alto riesgo',
              'En una cuenta de ahorros separada',
              'En la misma cuenta de gastos',
            ],
            correctAnswerIndex: 2,
            explanation: 'Una cuenta de ahorros separada evita la tentación de usarlo y mantiene el dinero accesible.',
          ),
          QuizQuestion(
            question: '¿Para qué NO debe usarse el fondo de emergencia?',
            options: [
              'Pérdida de empleo',
              'Emergencia médica',
              'Vacaciones',
              'Reparación urgente del auto',
            ],
            correctAnswerIndex: 2,
            explanation: 'Las vacaciones son un gasto planeado, no una emergencia.',
          ),
          QuizQuestion(
            question: '¿Cuál es la mejor forma de crear un fondo de emergencia?',
            options: [
              'Ahorrar grandes cantidades esporádicamente',
              'Ahorrar un porcentaje fijo mensualmente',
              'Esperar un bono o ingreso extra',
              'Pedir un préstamo',
            ],
            correctAnswerIndex: 1,
            explanation: 'Ahorrar un porcentaje fijo cada mes crea el hábito y es más sostenible.',
          ),
          QuizQuestion(
            question: '¿Qué hacer después de usar el fondo de emergencia?',
            options: [
              'Olvidarse de él',
              'Reponerlo lo antes posible',
              'Usarlo para otras cosas',
              'Cerrarlo',
            ],
            correctAnswerIndex: 1,
            explanation: 'Es crucial reponer el fondo de emergencia después de usarlo para estar preparado para futuras emergencias.',
          ),
        ],
      ),
    ];
  }

  static String extractYouTubeId(String url) {
    final regex = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regex.firstMatch(url);
    return match?.group(1) ?? '';
  }
}