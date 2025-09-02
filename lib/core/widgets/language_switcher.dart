import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return PopupMenuButton<String>(
          icon: Icon(
            Icons.language,
            color: Theme.of(context).iconTheme.color,
          ),
          onSelected: (String languageCode) {
            languageService.setLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'ar',
              child: Row(
                children: [
                  const Text('🇸🇦'),
                  const SizedBox(width: 8),
                  Text(
                    'العربية',
                    style: TextStyle(
                      fontWeight: languageService.isArabic 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  if (languageService.isArabic) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, size: 16),
                  ],
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                children: [
                  const Text('🇺🇸'),
                  const SizedBox(width: 8),
                  Text(
                    'English',
                    style: TextStyle(
                      fontWeight: languageService.isEnglish 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  if (languageService.isEnglish) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, size: 16),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
