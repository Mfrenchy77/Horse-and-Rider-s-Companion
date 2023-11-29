import 'package:database_repository/database_repository.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

class WebPageDataFetcher {
  WebPageDataFetcher(this.url);
  final String url;

  Future<WebPageData> fetchData() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = parser.parse(response.body);

      final title = _extractTitle(document);
      final description = _extractDescription(document);
      final imageUrl = _extractImageUrl(document);

      return WebPageData(
        title: title,
        description: description,
        imageUrl: imageUrl,
      );
    } else {
      // Handle the case when the page is not successfully fetched
      throw Exception('Failed to load web page');
    }
  }

  String? _extractTitle(Document document) {
    return document.getElementsByTagName('title').isNotEmpty
        ? document.getElementsByTagName('title')[0].text
        : null;
  }

  String? _extractDescription(Document document) {
    final metaTags = document.getElementsByTagName('meta');
    for (final tag in metaTags) {
      if (tag.attributes['name'] == 'description') {
        return tag.attributes['content'];
      }
    }
    return null;
  }

  String? _extractImageUrl(Document document) {
    final metaTags = document.getElementsByTagName('meta');
    for (final tag in metaTags) {
      if (tag.attributes['property'] == 'og:image') {
        return tag.attributes['content'];
      }
    }
    return null;
  }
}
