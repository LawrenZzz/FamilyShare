import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../src/config/app_config.dart';
import '../src/providers/app_provider.dart';
import '../src/services/prefs_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final AppProvider _app;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  int _step = 0;
  String _error = '';
  bool _busy = false;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppProvider>();
    _app.addListener(_onAppChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAppChanged());
  }

  void _onAppChanged() {
    if (!mounted || _didNavigate) return;
    if (_app.familyId.isNotEmpty) _goHome();
  }

  void _goHome() {
    if (!mounted || _didNavigate) return;
    _didNavigate = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _app.removeListener(_onAppChanged);
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开始使用'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _step,
          onStepContinue: _busy ? null : _continueStep,
          onStepCancel:
              _busy || _step == 0 ? null : () => setState(() => _step--),
          controlsBuilder: (_, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Row(
                children: [
                  if (_step < 2)
                    FilledButton(
                      onPressed: _busy ? null : details.onStepContinue,
                      child: const Text('继续'),
                    ),
                  if (_step > 0) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _busy ? null : details.onStepCancel,
                      child: const Text('上一步'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('欢迎'),
              content: _buildWelcome(),
              isActive: _step >= 0,
            ),
            Step(
              title: const Text('你的称呼'),
              content: _buildNameStep(),
              isActive: _step >= 1,
            ),
            Step(
              title: const Text('家庭'),
              content: _buildFamilyStep(),
              isActive: _step >= 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.family_restroom, size: 80, color: Color(0xFF0F766E)),
        SizedBox(height: 24),
        Text(
          '家庭共享',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          '与家人安全地实时共享位置',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 18),
        Text(
          '实时位置共享\n家庭成员地图\n远程刷新位置与设备响铃\n家庭数据独立管理',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.7),
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '家人应该如何称呼你？',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '你的名字',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _error = ''),
        ),
        _errorText(),
      ],
    );
  }

  Widget _buildFamilyStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '创建或加入一个家庭',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: '家庭码（6 位）',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() => _error = ''),
        ),
        _errorText(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _createFamily,
                child: const Text('创建家庭'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _joinFamily,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('加入家庭'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _errorText() {
    if (_error.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(_error, style: const TextStyle(color: Colors.red)),
    );
  }

  void _continueStep() {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入你的名字');
      return;
    }
    PrefsService().setDeviceName(name);
    AppConfig.setDeviceName(name);
    setState(() {
      _error = '';
      _step = 2;
    });
  }

  Future<void> _createFamily() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请先输入你的名字');
      return;
    }
    PrefsService().setDeviceName(name);
    AppConfig.setDeviceName(name);
    await _runFamilyAction(() => _app.createFamily(name), creating: true);
  }

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = '请输入家庭码');
      return;
    }
    await _runFamilyAction(() => _app.joinFamily(code));
  }

  Future<void> _runFamilyAction(
    Future<void> Function() action, {
    bool creating = false,
  }) async {
    setState(() {
      _busy = true;
      _error = '';
    });
    await action();
    if (!mounted) return;
    if (_app.familyId.isNotEmpty) {
      _goHome();
      return;
    }
    setState(() {
      _busy = false;
      if (_app.pendingJoinRequestId.isNotEmpty) {
        _error = '申请已发送，正在等待群主处理。';
      } else {
        _error = creating ? '创建家庭失败，请稍后重试。' : '加入失败，请检查家庭码后重试。';
      }
    });
  }
}
