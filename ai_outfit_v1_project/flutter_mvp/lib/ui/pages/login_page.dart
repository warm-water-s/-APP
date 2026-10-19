import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// UI-02 登录 / 注册（演示）。
///
/// 不发送真实短信、不创建账号；仅用于演示表单状态与进入主界面的路径。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _error;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendCode() {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      setState(() => _error = '请输入 11 位手机号');
      return;
    }
    _countdownTimer?.cancel();
    setState(() {
      _error = null;
      _countdown = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('演示模式：未发送真实短信，请输入任意 4 位验证码'),
      ),
    );
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      setState(() => _error = '请输入 11 位手机号');
      return;
    }
    if (code.length < 4) {
      setState(() => _error = '请输入至少 4 位验证码（演示可任意填写）');
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录 / 注册')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        children: <Widget>[
          const Text(
            '手机号登录',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '正式版本将发送短信验证码；当前为演示界面，不连接任何短信或账号服务。',
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            key: const Key('login-phone'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            decoration: const InputDecoration(
              labelText: '手机号',
              hintText: '11 位手机号',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('login-code'),
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '验证码',
                    hintText: '演示可任意填写',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                key: const Key('login-send-code'),
                onPressed: _countdown > 0 ? null : _sendCode,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(104, 56),
                ),
                child: Text(_countdown > 0 ? '${_countdown}s' : '获取验证码'),
              ),
            ],
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const Key('login-error'),
              style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            key: const Key('login-submit'),
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('登录（演示）'),
          ),
          const SizedBox(height: 12),
          const Text(
            '继续即表示同意用户协议与隐私政策。当前版本不创建账号、不保存手机号。',
            style: TextStyle(
              fontSize: 10,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          OutlinedButton(
            key: const Key('login-skip'),
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('暂不登录，体验演示衣橱'),
          ),
        ],
      ),
    );
  }
}
