import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/simple_ai_chat_widget.dart';
import '../services/general_ai_chat_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/role_management_service.dart';
import '../../../locator.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  late final GeneralAIChatService _aiChatService;

  @override
  void initState() {
    super.initState();
    _aiChatService = GeneralAIChatService();
    
    // Check if user is super admin
    final authService = locator<AuthService>();
    final roleService = locator<RoleManagementService>();
    final currentUser = authService.currentUser;
    
    if (currentUser == null || roleService.getUserRole(currentUser) != UserRole.superAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Super Admin privileges required.'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _aiChatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('AI Chat Assistant'),
          ],
        ),
        actions: [
          Text(
            'Super Admin Only',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ChangeNotifierProvider<GeneralAIChatService>.value(
        value: _aiChatService,
        child: const SimpleAIChatWidget(),
      ),
    );
  }
}
