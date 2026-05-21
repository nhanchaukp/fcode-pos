import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotLoginScreen extends StatefulWidget {
  const TelegramBotLoginScreen({super.key});

  @override
  State<TelegramBotLoginScreen> createState() => _TelegramBotLoginScreenState();
}

class _TelegramBotLoginScreenState extends State<TelegramBotLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  final _sessionStorage = TelegramBotSessionStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final api = TelegramBotApiClient();
      final session = await api.login(username: username, password: password);
      await _sessionStorage.save(session);

      if (!mounted) {
        return;
      }

      Toastr.success('Đăng nhập Telegram Bot thành công');
      Navigator.pop(context, true);
    } on TelegramBotApiException catch (error) {
      Toastr.error(error.message);
    } catch (_) {
      Toastr.error('Đăng nhập thất bại, vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập Telegram Bot')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primary,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Đăng nhập để quản lý Telegram Bot',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Vui lòng nhập username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Vui lòng nhập password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            _isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
