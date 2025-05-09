import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';


class HomeScreen extends StatelessWidget {
  // Listă cu denumirile raselor de câini common
  final List<String> favoriteBreeds = [
      'American Staffordshire Terrier',
      'Basset',
      'Beagle',
      'Bernese Mountain Dog',
      'Blenheim Spaniel',
      'Border Collie',
      'Chihuahua',
      'Chow',
      'Cocker Spaniel',
      'Doberman',
      'French Bulldog',
      'Golden Retriever',
      'Labrador Retriever',
      'Malamute',
      'Miniature Poodle',
      'Pekinese',
      'Pomeranian',
      'Pug',
      'Rottweiler',
      'Shih-Tzu',
      'Standard Poodle',
      'Yorkshire Terrier',
    ];

  // Funcția pentru a încărca fișierul JSON
  Future<List<dynamic>> loadDogBreeds() async {
    final String response = await rootBundle.loadString('assets/dog_breeds.json');
    final data = json.decode(response);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header cu welcome și search
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/profile.png'),
                    radius: 20,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bun venit,',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Caută orice rasă de câine',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Search bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cauta...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Most Common Breeds
              Row(
                children: [
                  Text(
                    'Cei mai întâlniți',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),


              SizedBox(height: 15),

              // Dog breed grid
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: loadDogBreeds(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading data'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No dog breeds available'));
                    }

                    List<dynamic> breeds = snapshot.data!
                        .where((breed) => favoriteBreeds.contains(breed['name']))
                        .toList();
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [

            Positioned.fill(
              child: Image.asset(
                'assets/icons/Path 1.png',
                fit: BoxFit.cover,
              ),
            ),

            // Buton cameră
            Positioned(
              top: -10,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/camera'),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

            // Icon All Breeds
            Positioned(
              left: 40,
              bottom: 20,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/view_all'),
                child: Image.asset(
                  'assets/icons/allbreeds.png',
                  height: 42,
                  width: 42,
                ),
              ),
            ),

            // Icon Favorites
            Positioned(
              right: 40,
              bottom: 20,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/favorites'),
                child: Image.asset(
                  'assets/icons/heart.png',
                  height: 48,
                  width: 48,
                ),
              ),
            ),
          ],
        ),
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
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/dog_details',
          arguments: {
            'breed': breed,
            'description': description,
            'attributes': attributes,
            'imageUrl': imageUrl,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.pets, size: 50, color: Colors.grey),
                            ),
                          )
                        : Icon(Icons.pets, size: 50, color: Colors.grey),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.pets,
                        color: Colors.black54,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breed,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }

}