import 'dart:math';

import 'package:database_repository/database_repository.dart';

class TestResource {
  static final _random = Random();

  static List<Resource> generateTestResources({int count = 20}) {
    return List.generate(count, _createTestResource);
  }

  static Resource _createTestResource(int id) {
    // Generate random data
    final daysAgo = _random.nextInt(30); // Random days up to 30
    final lastEditDate = DateTime.now().subtract(Duration(days: daysAgo));
    final rating = _random.nextInt(5) + 1; // Ratings from 1 to 5
    final numberOfRates = _random.nextInt(100); // Number of rates up to 100

    // Example of a list of skillTreeIds (you can customize it)
    final skillTreeIds =
        List<String?>.generate(3, (_) => 'skill-${_random.nextInt(10)}');

    // Generate a list of users who rated
    final usersWhoRated = List<BaseListItem?>.generate(
      5,
      (index) => BaseListItem(id: 'user-$index'),
    );

    // Return a new Resource instance with random data
    return Resource(
      id: 'resource-$id',
      url: 'https://example.com/resource/$id',
      name: 'Test Resource $id',
      rating: rating,
      thumbnail: 'https://example.com/thumbnail/$id.jpg',
      lastEditBy: 'user-${_random.nextInt(10)}',
      description: 'Description for Test Resource $id',
      lastEditDate: lastEditDate,
      numberOfRates: numberOfRates,
      skillTreeIds: skillTreeIds,
      usersWhoRated: usersWhoRated,
    );
  }
}
