import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/user_profile_provider.dart';
import '../screens/mcq_cards_screen.dart';
import 'home_screens/dashboard.dart';
import 'home_screens/live_quiz.dart';
import 'home_screens/routine.dart';
import 'home_screens/writing.dart';
import 'home_screens/settings.dart';
import 'home_screens/pro.dart';
import 'home_screens/video_lessons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentAdIndex = 0;
  final PageController _pageController = PageController();
  late Timer _adTimer;

  final List<String> adImages = [
    'assets/ad1.jpg',
    'assets/ad2.jpg',
    'assets/ad3.jpg',
  ];

  final List<Map<String, String>> languages = [
    {"name": "English", "info": "10,000 learners"},
    {"name": "Spanish", "info": "20,000 learners"},
    {"name": "German", "info": "12,000 learners"},
    {"name": "Arabic", "info": "15,000 learners"},
    {"name": "French", "info": "18,000 learners"},
  ];

  @override
  void initState() {
    super.initState();
    _adTimer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (_pageController.hasClients) {
        _currentAdIndex = (_currentAdIndex + 1) % adImages.length;
        _pageController.animateToPage(
          _currentAdIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _adTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout(BuildContext context) async {
    await StorageService.clearStorage();
    Provider.of<UserProfileProvider>(context, listen: false).clearUserProfile();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  ListTile _buildDrawerItem(IconData icon, String label, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () async {
        final token = await StorageService.getToken();
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in first.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          _navigateTo(page);
        }
      },
    );
  }

  Widget _buildLanguageCard(String language, String subtitle, int index) {
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple];

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors[index % colors.length].withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    language,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfileProvider>(context).userProfile;
    final isPremium = Provider.of<UserProfileProvider>(context).isPremium;

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('LangBuddy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              _buildDrawerItem(Icons.workspace_premium, "Get Pro", const ProPage()),
              if (isPremium)
                _buildDrawerItem(Icons.video_library, "Video Lessons", const VideoLessonsPage()),
              _buildDrawerItem(Icons.bar_chart, "Progress", const RoutinePage()),
              _buildDrawerItem(Icons.menu_book, "Vocabulary", const LiveQuizPage()),
              _buildDrawerItem(Icons.check_circle_outline, "MCQ Test", const McqCardsScreen()),
              _buildDrawerItem(Icons.edit_note, "Written Test", const WritingTestPage()),
              _buildDrawerItem(Icons.settings, "Settings", const SettingsPage()),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(userProfile?.fullName ?? 'Guest'),
                onTap: () => _navigateTo(const StudentDashboard()),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('LangBuddy'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: adImages.length,
              itemBuilder: (context, index) {
                return Image.asset(adImages[index], fit: BoxFit.cover);
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Popular Languages", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                return _buildLanguageCard(lang["name"]!, lang["info"]!, index);
              },
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                const Text(
                  'All rights reserved 2025, Version 25.24.1',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.facebook, color: Colors.blue, size: 24),
                    SizedBox(width: 16),
                    Icon(Icons.code, color: Colors.black, size: 24), // GitHub
                    SizedBox(width: 16),
                    Icon(Icons.business_center, color: Color(0xFF0A66C2), size: 24), // LinkedIn
                    SizedBox(width: 16),
                    Icon(Icons.email, color: Colors.red, size: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}