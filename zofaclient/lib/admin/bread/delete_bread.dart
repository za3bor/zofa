import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/models/bread.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BreadDeleteScreen extends StatefulWidget {
  const BreadDeleteScreen({super.key});

  @override
  State<BreadDeleteScreen> createState() => _BreadDeleteScreenState();
}

class _BreadDeleteScreenState extends State<BreadDeleteScreen> {
  late List<Bread> breads;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBreads();
  }

  // Fetch all breads from the API
  Future<void> fetchBreads() async {
    final response =
        await http.get(Uri.parse('http://$ipAddress/api/showAllBreadTypes'));

    if (response.statusCode == 200) {
      final List<dynamic> breadJson = json.decode(response.body);
      setState(() {
        breads = breadJson.map((json) {
          return Bread(
              id: json['id'],
              name: json['name'],
              price: double.parse(json['price'].toString()),
              quantity: int.parse(json['quantity'].toString()));
        }).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load breads');
    }
  }

  // Function to delete bread by ID
  Future<void> deleteBread(int id) async {
    final response = await http.delete(
      Uri.parse('http://$ipAddress/api/deleteBreadType/$id'),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לחם נמחק בהצלחה!')),
        );
      }
      fetchBreads(); // Reload the bread list after deletion
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה במחיקת הלחם')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'מחיקת סוגי לחם',
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.all(16.0.h), // Padding for the body
                child: ListView.builder(
                  itemCount: breads.length,
                  itemBuilder: (context, index) {
                    final bread = breads[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bread.name,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'כמות: ${bread.quantity}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                // Prompt the user for confirmation before deletion
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Text('מחיקת לחם')),
                                      content: const Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                            'האם אתה בטוח שברצונך למחוק את סוג הלחם הזה?'),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('ביטול'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('מחק'),
                                          onPressed: () {
                                            deleteBread(bread.id);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
