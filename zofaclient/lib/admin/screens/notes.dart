import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/models/note.dart';
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/widgets/snow_layer.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() {
    return _NotesScreenState();
  }
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Note> _notes = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response =
          await http.get(Uri.parse('http://$ipAddress:3000/api/getAllNotes'));
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(response.body); // Parse the response as dynamic
        if (responseData is List) {
          if (mounted) {
            // Check if the widget is still mounted before calling setState
            setState(() {
              _notes.clear();
              _notes.addAll(responseData
                  .map((note) => Note(
                        id: note['id'],
                        content: note['content'] as String,
                      ))
                  .toList());
            });
          }
        } else if (responseData is Map && responseData.containsKey('message')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(responseData['message'] ?? 'No notes found')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch notes: ${response.body}')),
          );
        }
      }
    } catch (error) {
      print('Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching notes')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addNote() async {
    if (_controller.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note content cannot be empty')),
        );
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress:3000/api/addNewNote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': _controller.text}),
      );
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 201) {
        final newNote = Note(
          id: jsonDecode(response.body)['id'],
          content: _controller.text,
        );
        if (mounted) {
          setState(() {
            _notes.add(newNote);
            _controller.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note added successfully')),
          );
        }
      } else {
        final message =
            jsonDecode(response.body)['message'] ?? 'Failed to add note';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (error) {
      print('Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding note')),
        );
      }
    }
  }

  Future<void> _deleteNote(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://$ipAddress:3000/api/deleteNote/$id'),
      );

      // Log the response status and body for debugging
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Only update UI and show snack bar if the widget is still mounted
        if (mounted) {
          setState(() {
            _notes.removeWhere(
                (note) => note.id == id); // Remove the note from the list
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted successfully')),
          );
        }
      } else {
        final message =
            jsonDecode(response.body)['message'] ?? 'Failed to delete note';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (error) {
      print('Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting note')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace:
            const SnowLayer(), // Directly use SnowLayer without Container

        title: const Text('פתקים'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'כתוב פתק...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addNote,
                  ),
                ),
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _notes.isEmpty
                        ? const Center(child: Text('No notes available'))
                        : ListView.builder(
                            itemCount: _notes.length,
                            itemBuilder: (context, index) {
                              return Dismissible(
                                key: Key(_notes[index].id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Icon(Icons.delete),
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  final noteId = _notes[index].id;

                                  setState(() {
                                    _notes.removeAt(index);
                                  });

                                  try {
                                    await _deleteNote(noteId);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to delete note: $e'),
                                      ),
                                    );
                                  }
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      _notes[index].content[0].toUpperCase(),
                                    ),
                                  ),
                                  title: Text(_notes[index].content),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
