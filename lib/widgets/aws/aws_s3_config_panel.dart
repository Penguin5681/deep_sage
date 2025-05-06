import 'dart:convert';

import 'package:deep_sage/core/services/core_services/dataset_sync_service/aws_s3_operation_service.dart';
import 'package:flutter/material.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AWSS3ConfigPanel extends StatefulWidget {
  const AWSS3ConfigPanel({super.key});

  @override
  State<AWSS3ConfigPanel> createState() => _AWSS3ConfigPanelState();
}

class _AWSS3ConfigPanelState extends State<AWSS3ConfigPanel> {
  final TextEditingController _accessKeyController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  String? _selectedRegion;
  String? _selectedBucket;
  List<String> _buckets = [];
  bool _configurationComplete = false;
  bool _isLoading = false;
  bool _showSecretKey = false;

  final List<Map<String, String>> _regions = [
    {'code': 'us-east-1', 'name': 'US East (N. Virginia)'},
    {'code': 'us-east-2', 'name': 'US East (Ohio)'},
    {'code': 'us-west-1', 'name': 'US West (N. California)'},
    {'code': 'us-west-2', 'name': 'US West (Oregon)'},
    {'code': 'af-south-1', 'name': 'Africa (Cape Town)'},
    {'code': 'ap-east-1', 'name': 'Asia Pacific (Hong Kong)'},
    {'code': 'ap-northeast-1', 'name': 'Asia Pacific (Tokyo)'},
    {'code': 'ap-northeast-2', 'name': 'Asia Pacific (Seoul)'},
    {'code': 'ap-northeast-3', 'name': 'Asia Pacific (Osaka)'},
    {'code': 'ap-southeast-1', 'name': 'Asia Pacific (Singapore)'},
    {'code': 'ap-southeast-2', 'name': 'Asia Pacific (Sydney)'},
    {'code': 'ap-southeast-3', 'name': 'Asia Pacific (Jakarta)'},
    {'code': 'ap-south-1', 'name': 'Asia Pacific (Mumbai)'},
    {'code': 'ca-central-1', 'name': 'Canada (Central)'},
    {'code': 'eu-central-1', 'name': 'Europe (Frankfurt)'},
    {'code': 'eu-north-1', 'name': 'Europe (Stockholm)'},
    {'code': 'eu-south-1', 'name': 'Europe (Milan)'},
    {'code': 'eu-west-1', 'name': 'Europe (Ireland)'},
    {'code': 'eu-west-2', 'name': 'Europe (London)'},
    {'code': 'eu-west-3', 'name': 'Europe (Paris)'},
    {'code': 'me-south-1', 'name': 'Middle East (Bahrain)'},
    {'code': 'sa-east-1', 'name': 'South America (São Paulo)'},
  ];

  final _awsConfigBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _accessKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  void _loadSavedConfig() {
    final accessKey = _awsConfigBox.get('aws_access_key');
    final secretKey = _awsConfigBox.get('aws_secret_key');
    final region = _awsConfigBox.get('aws_region');
    final bucket = _awsConfigBox.get('aws_bucket');
    final buckets = _awsConfigBox.get('aws_buckets');

    if (accessKey != null) _accessKeyController.text = accessKey;
    if (secretKey != null) _secretKeyController.text = secretKey;
    if (region != null) _selectedRegion = region;
    if (bucket != null) _selectedBucket = bucket;
    if (buckets != null) setState(() => _buckets = List<String>.from(buckets));

    setState(() {
      _configurationComplete =
          accessKey != null && secretKey != null && region != null && bucket != null;
    });
  }

  Future<void> _fetchBuckets() async {
    if (_accessKeyController.text.isEmpty ||
        _secretKeyController.text.isEmpty ||
        _selectedRegion == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter credentials and select a region')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('Inside Try block');
      final bucketList = await AWSS3OperationService().listBuckets(
        accessKey: _accessKeyController.text,
        secretKey: _secretKeyController.text,
        region: _selectedRegion!,
      );

      debugPrint(bucketList[0]);

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _buckets = bucketList;
        _isLoading = false;
      });

      _awsConfigBox.put('aws_access_key', _accessKeyController.text);
      _awsConfigBox.put('aws_secret_key', _secretKeyController.text);
      _awsConfigBox.put('aws_region', _selectedRegion);
      _awsConfigBox.put('aws_buckets', _buckets);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching buckets: ${e.toString()}')));
      debugPrint(e.toString());
    }
  }

  void _saveConfiguration() {
    if (_selectedBucket == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a bucket')));
      return;
    }

    _awsConfigBox.put('aws_bucket', _selectedBucket);
    setState(() => _configurationComplete = true);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('AWS S3 configuration saved')));
  }

  void _resetConfiguration() {
    setState(() {
      _accessKeyController.clear();
      _secretKeyController.clear();
      _selectedRegion = null;
      _selectedBucket = null;
      _buckets = [];
      _configurationComplete = false;
    });

    // Remove saved config
    _awsConfigBox.delete('aws_access_key');
    _awsConfigBox.delete('aws_secret_key');
    _awsConfigBox.delete('aws_region');
    _awsConfigBox.delete('aws_bucket');
    _awsConfigBox.delete('aws_buckets');
  }

  @override
  Widget build(BuildContext context) {
    final containerColor = Colors.grey[800];
    final textColor = Colors.white;
    final labelColor = Colors.grey[300];
    final borderColor = Colors.grey[700];
    final iconColor = Colors.grey[400];

    return Container(
      decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child:
          _configurationComplete
              ? _buildConfiguredState(textColor, iconColor!)
              : _buildConfigurationForm(
                textColor,
                labelColor!,
                borderColor!,
                iconColor!,
                containerColor,
              ),
    );
  }

  Widget _buildConfiguredState(Color textColor, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? AppIcons.checkDark
                  : AppIcons.checkLight,
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'AWS S3 Configuration',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.edit, color: iconColor, size: 18),
              onPressed: () => setState(() => _configurationComplete = false),
              tooltip: 'Edit configuration',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: iconColor, size: 18),
              onPressed: _resetConfiguration,
              tooltip: 'Reset configuration',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Region',
          _selectedRegion != null
              ? _regions.firstWhere((r) => r['code'] == _selectedRegion)['name'] ?? _selectedRegion!
              : 'Not selected',
          textColor,
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Bucket', _selectedBucket ?? 'Not selected', textColor),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Access Key',
          '${_accessKeyController.text.substring(0, 4)}...${_accessKeyController.text.substring(_accessKeyController.text.length - 4)}',
          textColor,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textColor, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationForm(
    Color textColor,
    Color labelColor,
    Color borderColor,
    Color iconColor,
    Color? containerColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AWS S3 Configuration',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Access Key
        Text(
          'Access Key ID',
          style: TextStyle(color: labelColor, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _accessKeyController,
          decoration: InputDecoration(
            hintText: 'Enter your AWS access key',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: borderColor),
            ),
            hintStyle: TextStyle(color: labelColor, fontSize: 13),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
        ),
        const SizedBox(height: 16),

        // Secret Key
        Text(
          'Secret Access Key',
          style: TextStyle(color: labelColor, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _secretKeyController,
          obscureText: !_showSecretKey,
          decoration: InputDecoration(
            hintText: 'Enter your AWS secret key',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: borderColor),
            ),
            hintStyle: TextStyle(color: labelColor, fontSize: 13),
            suffixIcon: IconButton(
              icon: Icon(
                _showSecretKey ? Icons.visibility_off : Icons.visibility,
                color: iconColor,
                size: 18,
              ),
              onPressed: () => setState(() => _showSecretKey = !_showSecretKey),
            ),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
        ),
        const SizedBox(height: 16),

        // Region Selection
        Text(
          'Region',
          style: TextStyle(color: labelColor, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text('Select AWS region', style: TextStyle(color: labelColor, fontSize: 13)),
              value: _selectedRegion,
              icon: Icon(Icons.arrow_drop_down, color: iconColor),
              dropdownColor: containerColor,
              style: TextStyle(color: textColor, fontSize: 14),
              onChanged: (String? newValue) {
                setState(() => _selectedRegion = newValue);
              },
              items:
                  _regions.map<DropdownMenuItem<String>>((Map<String, String> region) {
                    return DropdownMenuItem<String>(
                      value: region['code'],
                      child: Text(region['name']!, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Fetch Buckets Button
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchBuckets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                        : const Text('Fetch Buckets'),
              ),
            ),
          ],
        ),

        // Bucket Selection (only visible when buckets are loaded)
        if (_buckets.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Select Bucket',
            style: TextStyle(color: labelColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text('Select a bucket', style: TextStyle(color: labelColor, fontSize: 13)),
                value: _selectedBucket,
                icon: Icon(Icons.arrow_drop_down, color: iconColor),
                dropdownColor: containerColor,
                style: TextStyle(color: textColor, fontSize: 14),
                onChanged: (String? newValue) {
                  setState(() => _selectedBucket = newValue);
                },
                items:
                    _buckets.map<DropdownMenuItem<String>>((String bucket) {
                      return DropdownMenuItem<String>(
                        value: bucket,
                        child: Text(bucket, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveConfiguration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Save Configuration'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
