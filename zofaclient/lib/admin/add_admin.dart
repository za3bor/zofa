import 'package:flutter/material.dart';
import 'package:zofa_client/constant.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({super.key});
  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _deleteCodeController = TextEditingController();
  final List<Map<String, String>> _adminList = [];

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _deleteCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdmins() async {
    try {
      final response =
          await http.get(Uri.parse('http://$ipAddress/api/getAllAdmins'));
      if (response.statusCode == 200) {
        final List<dynamic> admins = json.decode(response.body);
        setState(() {
          _adminList.clear();
          _adminList.addAll(admins.map((admin) {
            return {
              'name': admin['name'],
              'phone': admin['phone_number'],
            };
          }));
        });
      } else {
        _showError('Failed to fetch admins');
      }
    } catch (e) {
      _showError('Error fetching admins: $e');
    }
  }

  Future<void> _addAdmin() async {
    String phone = _phoneController.text.trim();
    String name = _nameController.text.trim();
    String code = _codeController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number.');
      return;
    }

    if (name.isEmpty) {
      _showError('Please enter a valid name.');
      return;
    }

    if (code != '97217') {
      _showError('Invalid code. Please try again.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/addAdmin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'phoneNumber': phone}),
      );

      if (response.statusCode == 201) {
        _showSuccess('Admin added successfully.');
        _fetchAdmins();
        _phoneController.clear();
        _nameController.clear();
        _codeController.clear();
      } else if (response.statusCode == 409) {
        _showError('Admin with this phone number already exists.');
      } else {
        _showError('Failed to add admin.');
      }
    } catch (e) {
      _showError('Error adding admin: $e');
    }
  }

  Future<void> _deleteAdmin(String phone) async {
    String code = _deleteCodeController.text.trim();

    if (code != '97217') {
      _showError('Invalid code. Please try again.');
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse(
            'http://$ipAddress/api/deleteAdmin/$phone'), // Correct URL with phone number
      );

      if (response.statusCode == 200) {
        _showSuccess('Admin deleted successfully.');
        _deleteCodeController.clear();
        _fetchAdmins();
      } else {
        _showError('Failed to delete admin.');
      }
    } catch (e) {
      _showError('Error deleting admin: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.green)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('מנהלים'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'מספר טלפון',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'שם',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _codeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'קוד אימות',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _addAdmin,
                child: const Text('הוספת מנהל'),
              ),
              const SizedBox(height: 16),
              Text(
                'מנהלים נוכחיים:',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _adminList.length,
                  itemBuilder: (context, index) {
                    final admin = _adminList[index];
                    return ListTile(
                      title: Text(admin['name']!),
                      subtitle: Text(admin['phone']!),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                'מחיקת מנהל',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold),
                                textAlign:
                                    TextAlign.right, // Align title to the right
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '.הזן את קוד המנהל לאישור מחיקה',
                                    textAlign: TextAlign
                                        .right, // Align content text to the right
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  SizedBox(height: 16.h),
                                  TextField(
                                    controller: _deleteCodeController,
                                    obscureText: true,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'קוד אימות',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('ביטול'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteAdmin(admin['phone']!);
                                  },
                                  child: const Text(
                                    'מחק מנהל',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
