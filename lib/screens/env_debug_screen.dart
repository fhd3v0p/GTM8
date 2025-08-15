import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class EnvDebugScreen extends StatelessWidget {
  const EnvDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Environment Debug', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Environment Variables', [
                _buildEnvVar('SUPABASE_URL', ApiConfig.supabaseUrl),
                _buildEnvVar('SUPABASE_ANON_KEY', ApiConfig.supabaseAnonKey),
                _buildEnvVar('RATING_API_BASE_URL', ApiConfig.ratingApiBaseUrl),
                _buildEnvVar('SUPABASE_AI_BUCKET', ApiConfig.aiUploadsBucket),
                _buildEnvVar('SUPABASE_AI_FOLDER', ApiConfig.aiUploadsFolder),
                _buildEnvVar('TELEGRAM_BOT_TOKEN', ApiConfig.telegramBotToken),
              ]),
              const SizedBox(height: 20),
              _buildSection('Configuration Status', [
                _buildStatusItem('Supabase Configured', ApiConfig.isConfigured),
                _buildStatusItem('Web Platform', kIsWeb),
                _buildStatusItem('Debug Mode', kDebugMode),
              ]),
              const SizedBox(height: 20),
              _buildSection('URLs', [
                _buildUrlItem('API Base URL', ApiConfig.apiBaseUrl),
                _buildUrlItem('Rating API URL', ApiConfig.ratingApiBaseUrl),
                _buildUrlItem('Storage URL Example', ApiConfig.getStorageUrl('artists', 'test.jpg')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'NauryzKeds',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildEnvVar(String name, String value) {
    final bool hasValue = value.isNotEmpty;
    final String displayValue = hasValue 
        ? (value.length > 50 ? '${value.substring(0, 30)}...' : value)
        : 'NOT SET';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasValue ? Icons.check_circle : Icons.error,
            color: hasValue ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: hasValue ? Colors.white : Colors.red[300],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  displayValue,
                  style: TextStyle(
                    color: hasValue ? Colors.grey[300] : Colors.red[300],
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String name, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: status ? Colors.white : Colors.red[300],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlItem(String name, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            url.isNotEmpty ? url : 'NOT CONFIGURED',
            style: TextStyle(
              color: url.isNotEmpty ? Colors.grey[300] : Colors.red[300],
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}