// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/dog_details_screen.dart';
import 'screens/view_all_screen.dart';

void main() {
  runApp(DogBreedIdentifierApp());
}

class DogBreedIdentifierApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breed Identifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Definim rutele pentru navigare
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/camera': (context) => CameraScreen(),
        '/dog_details': (context) => DogDetailsScreen(),
        '/view_all': (context) => ViewAllScreen(),
      },
    );
  }
}