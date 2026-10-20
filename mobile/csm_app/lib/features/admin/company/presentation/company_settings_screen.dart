
import 'package:flutter/material.dart';

import '../data/models/company_settings.dart';
import '../data/repositories/company_repository.dart';
import '../data/models/company_lookup.dart';
import '../data/repositories/backup_repository.dart';
import 'backup_screen.dart';
import '../../../../../core/network/api_client.dart';
import '../../audit/data/repositories/audit_repository.dart';
import '../../audit/presentation/audit_log_screen.dart';



class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState
    extends State<CompanySettingsScreen> {
  final _repository = CompanyRepository();
  final _backupRepository = BackupRepository(ApiClient());
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _shortName = TextEditingController();
  final _registration = TextEditingController();
  final _tax = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String _currency = 'ETB';
  String _timeZone = 'Africa/Addis_Ababa';
  int _fiscalMonth = 1;
  String _companyId = '';
  String? _selectedCompanyId;
  List<CompanyLookup> _companies = [];
  String _workStart = '08:00';
  String _workEnd = '17:00';
  int _lunchBreak = 60;

  int _lateGrace = 15;
  double _overtimeAfter = 8.0;

  bool _notifyLowInventory = true;
  bool _notifyMaintenance = true;
  bool _notifyPermitExpiry = true;
  bool _notifyDailyProgress = true;

  String _weekendDays = 'Saturday,Sunday';

  // Branding
  String? _logoUrl;
  final _primaryColor = TextEditingController(text: '#156082');
  final _secondaryColor = TextEditingController(text: '#E6F4F1');

// Localization
  String _language = 'en';
  String _dateFormat = 'dd/MM/yyyy';
  String _numberFormat = 'en-ET';
  String _measurementUnit = 'Metric';

// Document Prefixes
  final _projectPrefix = TextEditingController(text: 'PRJ');
  final _poPrefix = TextEditingController(text: 'PO');
  final _stockPrefix = TextEditingController(text: 'SI');
  final _employeePrefix = TextEditingController(text: 'EMP');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _shortName.dispose();
    _registration.dispose();
    _tax.dispose();
    _email.dispose();
    _phone.dispose();
    _website.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    _primaryColor.dispose();
    _secondaryColor.dispose();

    _projectPrefix.dispose();
    _poPrefix.dispose();
    _stockPrefix.dispose();
    _employeePrefix.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final company = await _repository.getSettings();
      _companies = await _repository.getCompanies();

      _companyId = company.id;
      _selectedCompanyId = company.id;

      _name.text = company.name;

      _companyId = company.id;
      _name.text = company.name;
      _shortName.text = company.shortName;
      _registration.text = company.registrationNumber;
      _tax.text = company.taxNumber;
      _email.text = company.email;
      _phone.text = company.phone;
      _website.text = company.website;
      _address.text = company.address;
      _city.text = company.city;
      _country.text = company.country;
      _currency = company.currency;
      _timeZone = company.timeZone;
      _fiscalMonth = company.fiscalYearStartMonth;
      _workStart = company.workStartTime;
      _workEnd = company.workEndTime;
      _lunchBreak = company.lunchBreakMinutes;

      _lateGrace = company.lateGraceMinutes;
      _overtimeAfter = company.overtimeAfterHours;

      _notifyLowInventory = company.notifyLowInventory;
      _notifyMaintenance = company.notifyMaintenance;
      _notifyPermitExpiry = company.notifyPermitExpiry;
      _notifyDailyProgress = company.notifyDailyProgress;

      _weekendDays = company.weekendDays;

      _logoUrl = company.logoUrl;

      _primaryColor.text = company.primaryColor;
      _secondaryColor.text = company.secondaryColor;

      _language = company.defaultLanguage;
      _dateFormat = company.dateFormat;
      _numberFormat = company.numberFormat;
      _measurementUnit = company.measurementUnit;

      _projectPrefix.text = company.projectPrefix;
      _poPrefix.text = company.purchaseOrderPrefix;
      _stockPrefix.text = company.stockIssuePrefix;
      _employeePrefix.text = company.employeePrefix;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updated = CompanySettings(
        id: _selectedCompanyId ?? _companyId,
        name: _name.text.trim(),
        shortName: _shortName.text.trim(),
        registrationNumber: _registration.text.trim(),
        taxNumber: _tax.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        website: _website.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        currency: _currency,
        timeZone: _timeZone,
        fiscalYearStartMonth: _fiscalMonth,

        // Business Hours
        workStartTime: _workStart,
        workEndTime: _workEnd,
        lunchBreakMinutes: _lunchBreak,

        lateGraceMinutes: _lateGrace,
        overtimeAfterHours: _overtimeAfter,

        notifyLowInventory: _notifyLowInventory,
        notifyMaintenance: _notifyMaintenance,
        notifyPermitExpiry: _notifyPermitExpiry,
        notifyDailyProgress: _notifyDailyProgress,

        weekendDays: _weekendDays,

        // Branding
        logoUrl: _logoUrl,
        primaryColor: _primaryColor.text,
        secondaryColor: _secondaryColor.text,

        defaultLanguage: _language,
        dateFormat: _dateFormat,
        numberFormat: _numberFormat,
        measurementUnit: _measurementUnit,

        projectPrefix: _projectPrefix.text,
        purchaseOrderPrefix: _poPrefix.text,
        stockIssuePrefix: _stockPrefix.text,
        employeePrefix: _employeePrefix.text,
      );

      await _repository.updateSettings(updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company settings saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Company Profile'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCompanyId,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                items: _companies
                    .map(
                      (company) => DropdownMenuItem(
                    value: company.id,
                    child: Text(company.name),
                  ),
                )
                    .toList(),
                onChanged: (value) async {
                  if (value == null || value == _selectedCompanyId) {
                    return;
                  }

                  final company = await _repository.getSettingsById(value);

                  if (!mounted) return;

                  setState(() {
                    _selectedCompanyId = company.id;
                    _companyId = company.id;

                    _name.text = company.name;
                    _shortName.text = company.shortName;
                    _registration.text = company.registrationNumber;
                    _tax.text = company.taxNumber;
                    _email.text = company.email;
                    _phone.text = company.phone;
                    _website.text = company.website;
                    _address.text = company.address;
                    _city.text = company.city;
                    _country.text = company.country;

                    _currency = company.currency;
                    _timeZone = company.timeZone;
                    _fiscalMonth = company.fiscalYearStartMonth;

                    _workStart = company.workStartTime;
                    _workEnd = company.workEndTime;
                    _lunchBreak = company.lunchBreakMinutes;

                    _lateGrace = company.lateGraceMinutes;
                    _overtimeAfter = company.overtimeAfterHours;

                    _notifyLowInventory = company.notifyLowInventory;
                    _notifyMaintenance = company.notifyMaintenance;
                    _notifyPermitExpiry = company.notifyPermitExpiry;
                    _notifyDailyProgress = company.notifyDailyProgress;

                    _weekendDays = company.weekendDays;
                  });
                },
                validator: (value) =>
                value == null ? 'Required' : null,
              ),
            ),
            _textField(_shortName, 'Short Name'),
            _textField(_registration, 'Registration Number'),
            _textField(_tax, 'Tax / VAT Number'),

            const SizedBox(height: 20),

            _sectionTitle('Contact'),
            _textField(
              _email,
              'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            _textField(
              _phone,
              'Phone',
              keyboardType: TextInputType.phone,
            ),
            _textField(
              _website,
              'Website',
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 20),

            _sectionTitle('Address'),
            _textField(_country, 'Country'),
            _textField(_city, 'City'),
            _textField(
              _address,
              'Address',
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            _sectionTitle('Regional Settings'),

            const SizedBox(height: 20),
            _sectionTitle('Business Hours'),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _workStart,
                    decoration: const InputDecoration(
                      labelText: 'Start',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _workStart = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _workEnd,
                    decoration: const InputDecoration(
                      labelText: 'End',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _workEnd = v,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              initialValue: '$_lunchBreak',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lunch Break (minutes)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _lunchBreak = int.tryParse(v) ?? 60;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              initialValue: _weekendDays,
              decoration: const InputDecoration(
                labelText: 'Weekend Days',
                border: OutlineInputBorder(),
                hintText: 'Saturday,Sunday',
              ),
              onChanged: (v) => _weekendDays = v,
            ),

            const SizedBox(height: 20),
            _sectionTitle('Attendance Rules'),

            TextFormField(
              initialValue: '$_lateGrace',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Late Grace (minutes)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _lateGrace = int.tryParse(v) ?? 15;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              initialValue: _overtimeAfter.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Overtime After (hours)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _overtimeAfter = double.tryParse(v) ?? 8.0;
              },
            ),

            const SizedBox(height: 20),
            _sectionTitle('Notification Preferences'),

            SwitchListTile(
              value: _notifyLowInventory,
              onChanged: (v) => setState(() => _notifyLowInventory = v),
              title: const Text('Low Inventory Alert'),
            ),

            SwitchListTile(
              value: _notifyMaintenance,
              onChanged: (v) => setState(() => _notifyMaintenance = v),
              title: const Text('Maintenance Reminder'),
            ),

            SwitchListTile(
              value: _notifyPermitExpiry,
              onChanged: (v) => setState(() => _notifyPermitExpiry = v),
              title: const Text('Permit Expiration Alert'),
            ),

            SwitchListTile(
              value: _notifyDailyProgress,
              onChanged: (v) => setState(() => _notifyDailyProgress = v),
              title: const Text('Daily Progress Reminder'),
            ),

            DropdownButtonFormField<String>(
              initialValue: ['ETB', 'USD'].contains(_currency)
                  ? _currency
                  : 'ETB',
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ETB', child: Text('ETB')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currency = value);
                }
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: [
                'Africa/Addis_Ababa',
                'UTC',
              ].contains(_timeZone)
                  ? _timeZone
                  : 'Africa/Addis_Ababa',
              decoration: const InputDecoration(
                labelText: 'Time Zone',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Africa/Addis_Ababa',
                  child: Text('Africa/Addis_Ababa'),
                ),
                DropdownMenuItem(
                  value: 'UTC',
                  child: Text('UTC'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _timeZone = value);
                }
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              initialValue: (_fiscalMonth >= 1 && _fiscalMonth <= 12)
                  ? _fiscalMonth
                  : 1,
              decoration: const InputDecoration(
                labelText: 'Fiscal Year Start',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                12,
                    (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('Month ${i + 1}'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _fiscalMonth = value);
                }
              },
            ),
            const SizedBox(height: 20),
            _sectionTitle('Company Branding'),

            Center(
              child: CircleAvatar(
                radius: 42,
                child: const Icon(Icons.business, size: 42),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logo upload will be enabled next.'),
                  ),
                );
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload Logo'),
            ),

            const SizedBox(height: 12),

            _textField(_primaryColor, 'Primary Color'),
            _textField(_secondaryColor, 'Secondary Color'),

            const SizedBox(height: 20),
            _sectionTitle('Localization'),

            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'am', child: Text('Amharic')),
              ],
              onChanged: (v) => setState(() => _language = v!),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _measurementUnit,
              decoration: const InputDecoration(
                labelText: 'Measurement',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Metric', child: Text('Metric')),
                DropdownMenuItem(value: 'Imperial', child: Text('Imperial')),
              ],
              onChanged: (v) => setState(() => _measurementUnit = v!),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Document Numbering'),

            _textField(_projectPrefix, 'Project Prefix'),
            _textField(_poPrefix, 'Purchase Order Prefix'),
            _textField(_stockPrefix, 'Stock Issue Prefix'),
            _textField(_employeePrefix, 'Employee Prefix'),

            const SizedBox(height: 20),
            _sectionTitle('Database Backup & Restore'),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.backup_outlined,
                  color: Colors.green,
                ),
                title: const Text('Database Backup & Restore'),
                subtitle: const Text(
                  'Create, view and restore SQL Server backups',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BackupScreen(
                        repository: _backupRepository,
                      ),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Audit Log'),
                subtitle: const Text(
                  'View all administrative activity',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuditLogScreen(
                        repository: AuditRepository(ApiClient()),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 30),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'Saving...' : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _textField(
      TextEditingController controller,
      String label, {
        bool required = false,
        TextInputType? keyboardType,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          return null;
        }
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}