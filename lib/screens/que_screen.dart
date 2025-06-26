import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/models/que_model.dart';
import '../database/models/que_service.dart';
import '../database/models/que_card.dart';
import 'result_screen.dart';
import 'package:http/http.dart' as http;

class ExamCard {
  final String title;
  final bool isUnlocked;
  ExamCard({required this.title, required this.isUnlocked});
}

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  bool hasStarted = false;
  String selectedLanguage = "English";
  final List<String> languages = [
    "English", "French", "Spanish", "Chinese", "Japanese"
  ];

  int currentIndex = 0;
  int score = 0;
  int currentDay = 0;
  late Timer timer;

  // Hardcoded language code for testing
  String languageCode = "english"; // Spanish language code
  int examNumber = 1; // Testing with Exam 2

  Future<void> fetchExam(String languageCode, int examNumber) async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/mcqs/$languageCode/exam/$examNumber'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Question> fetchedQuestions = [];

      // Parse the questions from the API response
      for (var question in data['questions']) {
        fetchedQuestions.add(Question(
          id: question['_id'] ?? '',  // Generate or use a placeholder for id if not provided
          text: question['question'],  // Question text
          options: List<String>.from(question['options']),
          answerIndex: question['answer_index'],  // Correct option index
        ));
      }

      // Update the state with the fetched questions
      setState(() {
        todaysQuestions = fetchedQuestions;
      });
    } else {
      print('Failed to load exam');
    }
  }

  Duration remaining = const Duration(minutes: 30);
  Map<int, int> selectedAnswers = {};
  List<Question> todaysQuestions = [];

  // Define the list of exam cards with 2 unlocked and 8 locked
  List<ExamCard> examCards = List.generate(10, (index) {
    return ExamCard(
      title: "Exam ${index + 1}",
      isUnlocked: index < 2, // The first 2 exams are unlocked
    );
  });

  @override
  void initState() {
    super.initState();
    // Quiz initialization will start only after "Start" is pressed
  }

  Future<void> initQuiz(int examNumber) async {
    final prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('selectedLanguage') ?? "English"; // Get selected language

    // Fetch the exam questions for the selected language and exam number
    await fetchExam(selectedLanguage.toLowerCase(), examNumber);

    // Start the timer for the quiz
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (remaining.inSeconds > 0) {
          remaining -= const Duration(seconds: 1);
        } else {
          timer.cancel();
          _submit();
        }
      });
    });
  }


  void _submit() async {
    for (int i = 0; i < todaysQuestions.length; i++) {
      if (selectedAnswers[i] == todaysQuestions[i].answerIndex) {
        score++;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (score >= 10 && currentDay < 9) {
      prefs.setInt('currentDay', currentDay + 1);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: score,
          total: todaysQuestions.length,
          day: currentDay,
        ),
      ),
    );
  }

  void _nextQuestion(int? selectedOption) {
    if (selectedOption != null) {
      selectedAnswers[currentIndex] = selectedOption;
      if (currentIndex < todaysQuestions.length - 1) {
        setState(() {
          currentIndex++;
        });
      } else {
        timer.cancel();
        _submit();
      }
    }
  }


  void _startExam(int examIndex) async {
    if (examCards[examIndex].isUnlocked) {
      setState(() {
        hasStarted = true;
      });

      // Call initQuiz with the selected exam number
      await initQuiz(examIndex + 1);  // Exam number starts from 1, so use examIndex + 1
    }
  }

  @override
  void dispose() {
    if (hasStarted) timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasStarted) {
      // Show the list of exam cards
      return Scaffold(
        appBar: AppBar(
          title: const Text("Select an Exam"),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Choose an exam to start',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: examCards.length,
                  itemBuilder: (context, index) {
                    final examCard = examCards[index];
                    return Card(
                      color: examCard.isUnlocked ? Colors.green : Colors.grey,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          examCard.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => _startExam(index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (todaysQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = todaysQuestions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("MCQ Test - $selectedLanguage"),
        leading: const BackButton(),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}",
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text("Question ${currentIndex + 1} of ${todaysQuestions.length}",
              style: const TextStyle(fontSize: 18)),
          Expanded(
            child: McqCard(
              question: q,
              selectedIndex: selectedAnswers[currentIndex],
              onOptionSelected: _nextQuestion,
            ),
          ),
        ],
      ),
    );
  }
}
