import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Album App',
      theme: ThemeData(
        canvasColor: Color.fromRGBO(218, 216, 177, 1),
        hintColor: Color.fromARGB(255, 0, 255, 162),
        scaffoldBackgroundColor: Color.fromARGB(255, 238, 132, 132),
        cardColor: Color.fromARGB(255, 1, 181, 251),
        hoverColor: Color.fromARGB(255, 38, 40, 40),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontStyle: FontStyle.italic,
            color: Color.fromARGB(255, 167, 255, 2),
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            fontStyle: FontStyle.italic,
            color: Color.fromARGB(221, 241, 1, 141),
            fontSize: 16.0,
          ),
          // New style for italic font
          bodyMedium: TextStyle(
            color: Color.fromRGBO(3, 3, 251, 1),
            fontStyle: FontStyle.italic,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
      ),
      home: const AlbumList(),
    );
  }
}

class AlbumList extends StatefulWidget {
  const AlbumList({Key? key}) : super(key: key);

  @override
  _AlbumListState createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  late Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = fetchAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album App of 211025'),
      ),
      body: Center(
        child: FutureBuilder<List<Album>>(
          future: futureAlbums,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return AlbumListView(albums: snapshot.data!, onDelete: _deleteAlbum);
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }

            return const CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAlbumScreen(),
            ),
          ).then((value) {
            // Refresh the album list after adding a new album
            setState(() {
              futureAlbums = fetchAlbums();
            });
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteAlbum(int id) async {
    final response = await http.delete(
      Uri.parse('https://jsonplaceholder.typicode.com/albums/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete album $id');
    }

    // Print statement for debugging
    print('Album deleted successfully with ID: $id');

    // Refresh the album list after deleting
    setState(() {
      futureAlbums = fetchAlbums();
    });
  }
}

class AlbumListView extends StatelessWidget {
  final List<Album> albums;
  final Function(int) onDelete;

  const AlbumListView({Key? key, required this.albums, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 3.0,
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('ID: ${albums[index].id} - ${albums[index].title}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // Show a confirmation dialog before deleting the album
                bool deleteConfirmed = await showDeleteConfirmationDialog(context);

                if (deleteConfirmed) {
                  onDelete(albums[index].id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Album deleted'),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this album?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel deletion
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm deletion
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if the user dismisses the dialog
  }
}

class AddAlbumScreen extends StatefulWidget {
  const AddAlbumScreen({Key? key}) : super(key: key);

  @override
  _AddAlbumScreenState createState() => _AddAlbumScreenState();
}

class _AddAlbumScreenState extends State<AddAlbumScreen> {
  final TextEditingController titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Album'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title of the Album',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // Add the album
                    await addAlbum(titleController.text);
                    // Navigate back to the album list
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Add Album to the List'),
                ),
                const SizedBox(height: 20),
                const Text(
                  '© 2023 Shwetank Anand. All rights reserved.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Image.network(
                  'https://t3.ftcdn.net/jpg/05/66/48/04/240_F_566480427_pTG8xyhrVAkbDbsyNpYUVqEcwa6n4dze.jpg', // Replace with the actual image URL
                  height: 400, // Adjust the height as needed
                  width: 400, // Adjust the width as needed
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<List<Album>> fetchAlbums() async {
  final response =
      await http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums'));

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List)
        .map((data) => Album.fromJson(data))
        .toList();
  } else {
    throw Exception('Failed to load albums.');
  }
}

Future<void> addAlbum(String title) async {
  final response = await http.post(
    Uri.parse('https://jsonplaceholder.typicode.com/albums'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'title': title,
    }),
  );

  if (response.statusCode != 201) {
    throw Exception('Failed to add album $title');
  }

  // Print statement for debugging
  print('Album added successfully: $title');
}

class Album {
  final int id;
  final int userId;
  final String title;

  const Album({
    required this.id,
    required this.userId,
    required this.title,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
    );
  }
}
