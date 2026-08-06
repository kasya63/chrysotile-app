import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/features/auth/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  String? _avatarPath;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  String get _previewDisplayName {
    final value =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    return value.isEmpty ? '—' : value;
  }

  String get _previewNickname {
    final value = _previewDisplayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zа-яё0-9]+', caseSensitive: false), '.')
        .replaceAll(RegExp(r'^\.|\.$'), '');
    return value.isEmpty ? '—' : value;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    setState(() => _avatarPath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            avatarPath: _avatarPath,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _error = _mapError(error);
        _loading = false;
      });
      return;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ImageProvider<Object>? avatarImage = _avatarPath != null
        ? FileImage(File(_avatarPath!))
        : (user?.avatarUrl.isNotEmpty == true
            ? CachedNetworkImageProvider(user!.avatarUrl)
            : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.blueSoft,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(Icons.person, size: 48, color: Colors.white)
                        : null,
                  ),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.blue,
                      child: Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Имя'),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if ((value == null || value.trim().isEmpty) &&
                        _lastNameController.text.trim().isEmpty) {
                      return 'Укажите имя или фамилию';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Фамилия'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                _ReadonlyField(
                  label: 'Отображать как',
                  value: _previewDisplayName,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _ReadonlyField(
                  label: 'Ник',
                  value: _previewNickname,
                  isDark: isDark,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return error.message ?? 'Ошибка сети';
    }
    return error.toString();
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(
        value,
        style: TextStyle(
          color: isDark ? AppColors.darkTextSoft : AppColors.gray,
        ),
      ),
    );
  }
}
