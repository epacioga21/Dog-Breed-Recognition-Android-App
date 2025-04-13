import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dog_details_screen.dart';

class ViewAllScreen extends StatelessWidget {
  Future<List<dynamic>> loadAllDogBreeds() async {
    final String response = await rootBundle.loadString('assets/dog_breeds.json');
    final data = json.decode(response);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Toate rasele'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: loadAllDogBreeds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No dog breeds available'));
          }

          List<dynamic> breeds = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: breeds.length,
              itemBuilder: (context, index) {
                var breed = breeds[index];
                return _buildDogCard(
                  context,
                  breed['name'] ?? 'Unknown Breed',
                  breed['description'] ??
                      (breed['attributes']?['temperament'] as String?) ??
                      'No description',
                  breed['image_url'] ?? '',
                  breed['attributes'] ?? {},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDogCard(
      BuildContext context,
      String breed,
      String description,
      String imageUrl,
      Map<String, dynamic> attributes,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DogDetailsScreen(),
              settings: RouteSettings(
                arguments: {
                  'breed': breed,
                  'description': description,
                  'attributes': attributes,
                  'imageUrl': imageUrl,
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagine
              Expanded(
                child: Center(
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.pets, size: 50, color: Colors.grey),
                    ),
                  )
                      : Icon(Icons.pets, size: 50, color: Colors.grey),
                ),
              ),
              SizedBox(height: 8),

              // Numele rasei
              Text(
                breed,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),

              // Temperament/Descriere
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}