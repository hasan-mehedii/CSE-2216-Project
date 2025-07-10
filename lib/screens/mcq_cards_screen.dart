import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../screens/home.dart';

class Question {
  final String? id;
  final String? text;
  final List<String>? options;
  final int? answerIndex;

  Question({
    this.id,
    this.text,
    this.options,
    this.answerIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    print('Parsing Question from JSON: $json');
    try {
      return Question(
        id: json['_id'] as String?,
        text: json['question'] as String?,
        options: (json['options'] as List<dynamic>?)?.cast<String>() ?? ['A', 'B', 'C', 'D'],
        answerIndex: (json['answer_index'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      print('Question parsing error: $e');
      return Question(id: null, text: 'Parse Error', options: ['A', 'B', 'C', 'D'], answerIndex: 0);
    }
  }
}

class MCQCardData {
  final int? cardNumber;
  final List<Question> questions;

  MCQCardData({this.cardNumber, required this.questions});

  factory MCQCardData.fromJson(Map<String, dynamic> json) {
    print('Parsing MCQCardData from JSON: $json');
    try {
      return MCQCardData(
        cardNumber: (json['card_number'] as num?)?.toInt() ?? 1,
        questions: (json['questions'] as List<dynamic>?)?.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList() ?? [],
      );
    } catch (e) {
      print('MCQCardData parsing error: $e');
      return MCQCardData(cardNumber: 1, questions: []);
    }
  }
}

class McqCard extends StatelessWidget {
  final Question question;
  final int? selectedIndex;
  final ValueChanged<int?> onOptionSelected;

  const McqCard({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text ?? 'No Question',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...(question.options?.asMap().entries.map((entry) {
              int index = entry.key;
              String option = entry.value;
              return RadioListTile<int>(
                title: Text(option),
                value: index,
                groupValue: selectedIndex,
                onChanged: onOptionSelected,
              );
            }) ?? [const Text('No options available')]),
          ],
        ),
      ),
    );
  }
}

class McqCardsScreen extends StatefulWidget {
  const McqCardsScreen({super.key});

  @override
  State<McqCardsScreen> createState() => _McqCardsScreenState();
}

class _McqCardsScreenState extends State<McqCardsScreen> {
  List<MCQCardData> mcqCards = [];
  bool isLoading = true;
  String languageCode = "english"; // Default language
  Map<int, Map<int, int>> selectedAnswers = {}; // cardNumber -> questionIndex -> selectedOption
  Map<int, int> cardScores = {}; // cardNumber -> score
  String? rawResponse; // Store raw API response for debugging
  int fetchAttempts = 0;
  static const maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    fetchMcqCards();
  }

  Future<void> fetchMcqCards() async {
    if (fetchAttempts >= maxAttempts) {
      print('Max fetch attempts ($maxAttempts) reached');
      setState(() => isLoading = false);
      return;
    }

    setState(() {
      isLoading = true;
      fetchAttempts++;
    });
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        print('No token found, navigating to login');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      print('Fetch attempt $fetchAttempts with token: $token');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/mcqs/$languageCode/cards'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() {
        rawResponse = response.body; // Store raw response
      });

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        print('Decoded data type: ${data.runtimeType}, content: $data');
        if (data is List<dynamic>) {
          print('Decoded data length: ${data.length}');
          setState(() {
            mcqCards = data.map((json) => MCQCardData.fromJson(json as Map<String, dynamic>)).toList();
            isLoading = false;
          });
        } else {
          print('Unexpected data format: $data');
          throw Exception('Invalid response format: Expected a list');
        }
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fetch error: $e');
      setState(() {
        isLoading = false;
        rawResponse = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fetch error: $e. Attempt $fetchAttempts of $maxAttempts')),
      );
    }
  }

  void selectAnswer(int cardIndex, int questionIndex, int? optionIndex) {
    setState(() {
      if (!selectedAnswers.containsKey(cardIndex)) {
        selectedAnswers[cardIndex] = {};
      }
      selectedAnswers[cardIndex]![questionIndex] = optionIndex!;
    });
  }

  void submitCard(int cardIndex) {
    final card = mcqCards[cardIndex];
    int score = 0;
    for (int i = 0; i < card.questions.length; i++) {
      final question = card.questions[i];
      final selected = selectedAnswers[cardIndex]?[i];
      if (selected != null && selected == (question.answerIndex ?? 0)) {
        score++;
      }
    }
    setState(() {
      cardScores[cardIndex] = score;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Card ${card.cardNumber} Score: $score/10')),
    );
  }

  void refreshData() {
    setState(() {
      mcqCards.clear();
      rawResponse = null;
      fetchAttempts = 0;
    });
    fetchMcqCards();
  }

  @override
  Widget build(BuildContext context) {
    print('mcqCards length: ${mcqCards.length}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCQ Test Cards'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mcqCards.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No MCQ cards available. Check backend or data.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (rawResponse != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Raw Response: $rawResponse',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchAttempts < maxAttempts ? refreshData : null,
              child: Text(fetchAttempts < maxAttempts ? 'Retry' : 'Max Attempts Reached'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: mcqCards.length,
        itemBuilder: (context, cardIndex) {
          final card = mcqCards[cardIndex];
          return Card(
            elevation: 6,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card ${card.cardNumber ?? cardIndex + 1}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...card.questions.asMap().entries.map((entry) {
                    int questionIndex = entry.key;
                    Question question = entry.value;
                    return McqCard(
                      question: question,
                      selectedIndex: selectedAnswers[cardIndex]?[questionIndex],
                      onOptionSelected: (option) => selectAnswer(cardIndex, questionIndex, option),
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: selectedAnswers[cardIndex]?.length == (card.questions.length)
                        ? () => submitCard(cardIndex)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: const Text(
                      'Submit Card',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  if (cardScores.containsKey(cardIndex))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Score: ${cardScores[cardIndex]}/${card.questions.length}',
                        style: const TextStyle(fontSize: 18, color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}