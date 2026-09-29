import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/providers/app_provider.dart';
import '../src/services/prefs_service.dart';
import '../src/config/app_config.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String _error = '';
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<AppProvider>();
      app.addListener(_onAppChanged);
      _onAppChanged();
    });
  }

  void _onAppChanged() {
    if (!mounted || _didNavigate) return;
    if (context.read<AppProvider>().familyId.isNotEmpty) {
      _goHome();
    }
  }

  void _goHome() {
    if (!mounted || _didNavigate) return;
    _didNavigate = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    context.read<AppProvider>().removeListener(_onAppChanged);
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _continueStep,
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        steps: [
          Step(
            title: const Text('Welcome'),
            content: _buildWelcome(),
            isActive: _step >= 0,
          ),
          Step(
            title: const Text('Your Name'),
            content: _buildNameStep(),
            isActive: _step >= 1,
          ),
          Step(
            title: const Text('Join Family'),
            content: _buildFamilyStep(),
            isActive: _step >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.family_restroom, size: 80, color: Color(0xFF4A6CF7)),
        const SizedBox(height: 24),
        const Text(
          'FamilyShare',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share your location with family in real-time',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n• Real-time location sharing\n• Family members map\n• Track & ring devices\n• Private & secure',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'What should we call you?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _error = ''),
        ),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error, style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildFamilyStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Join or Create a Family',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Family Code (6 digits)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => setState(() => _error = ''),
        ),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _createFamily,
                child: const Text('Create New Family'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _joinFamily,
                child: const Text('Join Family'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _continueStep() async {
    switch (_step) {
      case 0:
        setState(() => _step++);
        break;
      case 1:
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          setState(() => _error = 'Please enter your name');
          return;
        }
        PrefsService().setDeviceName(name);
        AppConfig.setDeviceName(name);
        setState(() => _step++);
        break;
      case 2:
        final code = _codeController.text.trim();
        if (code.isEmpty) {
          setState(() => _error = 'Please enter a family code');
          return;
        }
        final app = context.read<AppProvider>();
        await app.joinFamily(code);
        if (app.familyId.isNotEmpty) {
          _goHome();
        } else if (app.pendingJoinRequestId.isNotEmpty) {
          setState(
              () => _error = 'Request sent. Waiting for the family owner.');
        } else {
          setState(() =>
              _error = 'Failed to join family. Check code and try again.');
        }
        break;
    }
  }

  Future<void> _createFamily() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name first');
      return;
    }
    PrefsService().setDeviceName(name);
    AppConfig.setDeviceName(name);
    final app = context.read<AppProvider>();
    await app.createFamily(name);
    if (app.familyId.isNotEmpty) {
      _goHome();
    } else if (app.pendingJoinRequestId.isNotEmpty) {
      setState(() => _error = 'Request sent. Waiting for the family owner.');
    } else {
      setState(() => _error = 'Failed to create family');
    }
  }

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a family code');
      return;
    }
    final app = context.read<AppProvider>();
    await app.joinFamily(code);
    if (app.familyId.isNotEmpty) {
      _goHome();
    } else if (app.pendingJoinRequestId.isNotEmpty) {
      setState(() => _error = 'Request sent. Waiting for the family owner.');
    } else {
      setState(
          () => _error = 'Failed to join family. Check code and try again.');
    }
  }
}
