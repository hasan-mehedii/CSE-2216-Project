import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../database/models/que_model.dart'; // Ensure this model exists and is correct for Question
import '../database/models/que_card.dart'; // Assuming this is your McqCard widget
import 'result_screen.dart';

class ExamCard {
  final String title;
  final bool isUnlocked;
  final int pageNumber; // Added pageNumber to ExamCard

  ExamCard({required this.title, required this.isUnlocked, required this.pageNumber});
}

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  bool hasStarted = false;
  String selectedLanguage = "english"; // Default language, will be fetched from prefs
  int currentIndex = 0;
  int score = 0;
  int currentDay = 0; // Not directly used in this MCQ card logic, but kept for context
  late Timer timer;

  Duration remaining = const Duration(minutes: 30);
  Map<int, int> selectedAnswers = {};
  List<Question> todaysQuestions = []; // Questions for the current selected exam card

  // Define the list of exam cards (10 cards for 10 sets of 10 MCQs)
  // Each card will correspond to a 'page' in the backend pagination.
  List<ExamCard> examCards = List.generate(10, (index) {
    return ExamCard(
      title: "MCQ Set ${index + 1}", // Titles like "MCQ Set 1", "MCQ Set 2", etc.
      isUnlocked: true, // All sets are unlocked by default for this example
      pageNumber: index + 1, // Page number for backend (1 to 10)
    );
  });

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming 'selectedLanguage' is saved as "English", "Spanish", etc.
    // Convert to lowercase for the backend API.
    setState(() {
      selectedLanguage = (prefs.getString('selectedLanguage') ?? "English").toLowerCase();
    });
  }

  Future<void> fetchPaginatedMCQs(String languageCode, int page, int limit) async {
    // You might want to show a loading indicator here
    setState(() {
      todaysQuestions.clear(); // Clear previous questions
      currentIndex = 0; // Reset question index
      selectedAnswers.clear(); // Clear selected answers
    });

    final url = 'http://127.0.0.1:8000/mcqs/paginated/$languageCode?page=$page&limit=$limit';
    print('Fetching MCQs from: $url'); // Debugging print

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Question> fetchedQuestions = [];
        for (var q in data) {
          fetchedQuestions.add(Question(
            id: q['_id'] ?? UniqueKey().toString(), // Use _id or generate
            text: q['question'],
            options: List<String>.from(q['options']),
            answerIndex: q['answer_index'],
          ));
        }
        setState(() {
          todaysQuestions = fetchedQuestions;
        });
      } else {
        print('Failed to load MCQs: ${response.statusCode} - ${response.body}');
        // Show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load MCQs: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error fetching MCQs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: $e')),
      );
    }
  }

  void _startExam(int examPageNumber) async {
    setState(() {
      hasStarted = true;
    });
    // Fetch 10 questions for the selected page
    await fetchPaginatedMCQs(selectedLanguage, examPageNumber, 10);
    _startQuizTimer();
  }

  void _startQuizTimer() {
    remaining = const Duration(minutes: 30); // Reset timer for each exam
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

    // You might want to save the score or progress here if needed
    // final prefs = await SharedPreferences.getInstance();
    // if (score >= someThreshold && currentDay < 9) {
    //   prefs.setInt('currentDay', currentDay + 1);
    // }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: score,
          total: todaysQuestions.length,
          day: currentDay, // Consider if 'day' is still relevant here
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
          title: const Text("Select an MCQ Set"),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Choose an MCQ set to start',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 cards per row
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.2, // Adjust aspect ratio as needed
                  ),
                  itemCount: examCards.length,
                  itemBuilder: (context, index) {
                    final examCard = examCards[index];
                    return GestureDetector(
                      onTap: examCard.isUnlocked ? () => _startExam(examCard.pageNumber) : null,
                      child: Card(
                        color: examCard.isUnlocked ? Colors.green : Colors.grey[700],
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                examCard.title,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              if (!examCard.isUnlocked)
                                const Icon(Icons.lock, color: Colors.white70, size: 30),
                            ],
                          ),
                        ),
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
        title: Text("MCQ Test - ${selectedLanguage.toUpperCase()}"),
        leading: const BackButton(),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 16, color: Colors.white), // Added text style
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