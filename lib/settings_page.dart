import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/main.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  final passwordController = TextEditingController();
  bool initialized = false;
  String? error;
  bool saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final account = AppScope.of(context).currentAccount!;
    nameController = TextEditingController(text: account.displayName);
    phoneController = TextEditingController(text: account.phone);
    initialized = true;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    return Scaffold(
      appBar: AppBar(title: Text(s.personalSettingsPage)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: nameController, label: s.nickname),
          AppTextField(controller: phoneController, label: s.phone),
          AppTextField(
            controller: passwordController,
            label: s.newPasswordLeaveBlank,
            obscureText: true,
          ),
          if (account.role == AccountRole.user)
            SwitchListTile(
              title: Text(s.autoUseFreeWash),
              value: account.autoUseFreeWash,
              onChanged: (value) {
                appStore.setAutoUseFreeWash(value);
                if (ApiClient.accessToken != null) {
                  ApiClient.updateMe({'auto_use_free_wash': value});
                }
              },
            ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      final body = <String, dynamic>{
                        'display_name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                      };
                      if (passwordController.text.trim().isNotEmpty) {
                        body['password'] = passwordController.text.trim();
                      }
                      if (ApiClient.accessToken != null) {
                        final data = await ApiClient.updateMe(body);
                        final current = appStore.currentAccount!;
                        current.displayName =
                            data['display_name'] as String? ?? current.displayName;
                        current.phone =
                            data['phone'] as String? ?? current.phone;
                      } else {
                        account.displayName = nameController.text.trim();
                        account.phone = phoneController.text.trim();
                        if (passwordController.text.trim().isNotEmpty) {
                          account.password = passwordController.text.trim();
                        }
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.settingsSaved)),
                      );
                      Navigator.pop(context);
                    } on Object catch (exception) {
                      setState(() => error = exception.toString());
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
            child: Text(saving ? s.saving : s.save),
          ),
        ],
      ),
    );
  }
}
