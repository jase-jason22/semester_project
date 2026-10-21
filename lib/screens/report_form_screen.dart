import 'package:flutter/material.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

enum ReportUiState { idle, loading, success, empty, error }

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Simulated in-memory records (no backend yet).
  final List<String> _reports = [];
  ReportUiState _uiState = ReportUiState.idle;
  bool _simulateFailure = false;
  bool _showReports = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _required(String? v, String name, {int min = 1}) {
    if (v == null || v.trim().isEmpty) return '$name is required';
    if (v.trim().length < min) return '$name must be at least $min characters';
    return null;
  }

  Future<void> submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _uiState = ReportUiState.loading);
    try {
      await Future<void>.delayed(const Duration(seconds: 4));
      if (_simulateFailure) throw Exception('Simulated failure');
      if (!mounted) return;
      setState(() {
        _reports.add(_titleController.text.trim());
        _titleController.clear();
        _locationController.clear();
        _descriptionController.clear();
        _uiState = ReportUiState.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uiState = ReportUiState.error);
    }
  }

  void _retry() {
    setState(() => _simulateFailure = false);
    submitReport();
  }

  void _viewReports() {
    setState(() {
      _showReports = true;
      _uiState = _reports.isEmpty ? ReportUiState.empty : ReportUiState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = _uiState == ReportUiState.loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a Report')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Report Title',
                        controller: _titleController,
                        enabled: !loading,
                        validator: (v) => _required(v, 'Title', min: 5),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Location',
                        controller: _locationController,
                        enabled: !loading,
                        validator: (v) => _required(v, 'Location'),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        enabled: !loading,
                        maxLines: 3,
                        validator: (v) =>
                            _required(v, 'Description', min: 10),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: const Text('Simulate failure (demo only)'),
                  value: _simulateFailure,
                  onChanged: loading
                      ? null
                      : (v) => setState(() => _simulateFailure = v),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: loading ? 'Submitting...' : 'Submit Report',
                  onPressed: loading ? null : submitReport,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'View Reports',
                  onPressed: loading ? null : _viewReports,
                ),
                const SizedBox(height: 24),
                _buildStatus(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    switch (_uiState) {
      case ReportUiState.loading:
        return const Column(children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Submitting your report... (simulated request)'),
        ]);
      case ReportUiState.success:
        return Column(children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          const Text('Report submitted successfully (simulated).'),
          const SizedBox(height: 8),
          AppButton(label: 'View Reports', onPressed: _viewReports),
        ]);
      case ReportUiState.empty:
        return const Column(children: [
          Icon(Icons.inbox_outlined, size: 48),
          SizedBox(height: 8),
          Text('No reports yet. Fill out the form above to submit your first report.'),
        ]);
      case ReportUiState.error:
        return Column(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          const Text('Submission failed (simulated). Please try again.'),
          const SizedBox(height: 8),
          AppButton(label: 'Retry', onPressed: _retry),
        ]);
      case ReportUiState.idle:
        if (_showReports && _reports.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submitted reports (simulated):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (final r in _reports) ListTile(title: Text(r)),
            ],
          );
        }
        return const SizedBox.shrink();
    }
  }
}