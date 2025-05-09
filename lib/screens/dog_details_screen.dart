import 'package:flutter/material.dart';

class DogDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String breed = args['breed'] ?? 'Unknown Breed';
    final String description = args['description'] ?? 'No description available';
    final Map<String, dynamic> attributes = args['attributes'] ?? {};
    final String imageUrl = args['imageUrl'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Imagine câine
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.pets, size: 100, color: Colors.grey),
                        ),
                      )
                    : Center(child: Icon(Icons.pets, size: 100, color: Colors.grey)),
              ),

              // Detalii
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Titlu rasă
                      Text(
                        breed.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Descriere
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),

                      // Atribute
                      _buildAttributeSection(attributes),

                      SizedBox(height: 10),

                      // Temperament
                      if (attributes['temperament'] != null)
                        _buildTemperamentSection(attributes['temperament']),

                      SizedBox(height: 40),

                      // Buton Favorites
                      Center(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding:
                                EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Adaugă la Favorite',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Buton Back
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeSection(Map<String, dynamic> attributes) {
    final Map<String, String> translatedKeys = {
      'size': 'Mărime',
      'lifespan': 'Durată de viață',
      'weight': 'Greutate',
      'activity_level': 'Nivel de activitate',
    };

    final Map<String, String> iconPaths = {
      'size': 'assets/icons/size.png',
      'lifespan': 'assets/icons/lifespan.png',
      'weight': 'assets/icons/weight.png',
      'activity_level': 'assets/icons/activity.png',
    };

    List<String> displayAttributes = ['size', 'lifespan', 'weight', 'activity_level'];

    return Column(
      children: [
        SizedBox(height: 30),
        Center(
          child: Text(
            'ATRIBUTE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: displayAttributes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 80,
          ),
          itemBuilder: (context, index) {
            String key = displayAttributes[index];
            if (attributes.containsKey(key)) {
              return _buildAttributeItem(
                translatedKeys[key]!,
                attributes[key].toString(),
                iconPaths[key]!,
              );
            }
            return SizedBox.shrink();
          },
        ),
      ],
    );
  }


  Widget _buildAttributeItem(String title, String value, String iconPath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            iconPath,
            width: 38,
            height: 38,
          ),
        ],
      ),
    );
  }


  Widget _buildTemperamentSection(String temperament) {
    List<String> traits = temperament.split(',').map((t) => t.trim()).toList();

    return Column(
      children: [
        SizedBox(height: 30),
        Center(
          child: Text(
            'TEMPERAMENT',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: traits.map((trait) => Chip(
              label: Text(trait),
              backgroundColor: Colors.blue[50],
              labelStyle: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

}