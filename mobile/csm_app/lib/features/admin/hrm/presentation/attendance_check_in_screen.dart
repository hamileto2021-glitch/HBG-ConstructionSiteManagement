import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/attendance/attendance.dart';
import '../data/models/employee.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/employee_repository.dart';
import '../../../../core/location/location_service.dart';

class AttendanceCheckInScreen extends StatefulWidget {
  const AttendanceCheckInScreen({
    super.key,
    required this.attendanceRepository,
    required this.employeeRepository,
    required this.siteRepository,
    required this.locationService,
  });

  final AttendanceRepository attendanceRepository;
  final EmployeeRepository employeeRepository;
  final SiteRepository siteRepository;
  final LocationService locationService;

  @override
  State<AttendanceCheckInScreen> createState() =>
      _AttendanceCheckInScreenState();
}

class _AttendanceCheckInScreenState
    extends State<AttendanceCheckInScreen> {
  List<Employee> _employees = [];
  List<Site> _sites = [];

  Employee? _selectedEmployee;
  Site? _selectedSite;

  Position? _position;

  final _remarksController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _isGettingLocation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.employeeRepository.getAll(
          status: EmployeeStatus.active,
        ),
        widget.siteRepository.getAll(),
      ]);

      if (!mounted) {
        return;
      }

      final employees = results[0] as List<Employee>;
      final sites = results[1] as List<Site>;

      setState(() {
        _employees = employees;
        _sites = sites.where((site) => site.isActive).toList();
        _isLoadingData = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingData = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });

    try {
      final position =
      await widget.locationService.getCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _position = position;
        _isGettingLocation = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGettingLocation = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _checkIn() async {
    if (_selectedEmployee == null) {
      setState(() {
        _errorMessage = 'Please select an employee.';
      });
      return;
    }

    if (_selectedSite == null) {
      setState(() {
        _errorMessage = 'Please select a construction site.';
      });
      return;
    }

    if (_position == null) {
      setState(() {
        _errorMessage =
        'Please capture your current location before checking in.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.attendanceRepository.checkIn(
        employeeId: _selectedEmployee!.id,
        constructionSiteId: _selectedSite!.id,
        checkInAtUtc: DateTime.now().toUtc(),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        accuracyMeters: _position!.accuracy,
        source: AttendanceSource.mobileGps,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance check-in successful.'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
      ),
      body: _isLoadingData
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorMessage!),
              ),
            ),
          _buildEmployeeCard(context),
          const SizedBox(height: 16),
          _buildSiteCard(context),
          const SizedBox(height: 16),
          _buildLocationCard(context),
          const SizedBox(height: 16),
          _buildRemarksCard(context),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isLoading ? null : _checkIn,
            icon: const Icon(Icons.login),
            label: const Text('Check In'),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Employee>(
              initialValue: _selectedEmployee,
              decoration: const InputDecoration(
                labelText: 'Select employee',
                border: OutlineInputBorder(),
              ),
              items: _employees
                  .map(
                    (employee) => DropdownMenuItem<Employee>(
                  value: employee,
                  child: Text(
                    '${employee.employeeNumber} - '
                        '${employee.firstName} '
                        '${employee.lastName}',
                  ),
                ),
              )
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (employee) {
                setState(() {
                  _selectedEmployee = employee;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Construction Site',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Site>(
              initialValue: _selectedSite,
              decoration: const InputDecoration(
                labelText: 'Select active site',
                border: OutlineInputBorder(),
              ),
              items: _sites
                  .map(
                    (site) => DropdownMenuItem<Site>(
                  value: site,
                  child: SizedBox(
                    width: 220,
                    child: Text(
                      '${site.siteCode} - ${site.name}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              )
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (site) {
                setState(() {
                  _selectedSite = site;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    final position = _position;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GPS Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (position == null)
              const Text(
                'Current location has not been captured.',
              )
            else ...[
              Text(
                'Latitude: '
                    '${position.latitude.toStringAsFixed(6)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Longitude: '
                    '${position.longitude.toStringAsFixed(6)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Accuracy: '
                    '${position.accuracy.toStringAsFixed(1)} m',
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed:
              _isGettingLocation ? null : _getCurrentLocation,
              icon: _isGettingLocation
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.my_location),
              label: Text(
                _isGettingLocation
                    ? 'Getting Location...'
                    : 'Get Current Location',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remarks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Optional remarks',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}