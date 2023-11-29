/// WebPageData holds key information extracted from a web page.
///
/// This class stores the title, description, and image URL of a web page,
/// which are typically used for previewing the content of the page.
///
/// Properties:
/// [title] - A `String` representing the title of the web page.
/// [description] - A `String` representing a brief
///  description or summary of the web page.
/// [imageUrl] - A `String` representing the
///  URL of a prominent image on the web page.
///
/// Usage example:
/// ```
/// var fetcher = WebPageDataFetcher('https://example.com');
/// fetcher.fetchData().then((WebPageData data) {
///   print('Title: ${data.title}');
///   print('Description: ${data.description}');
///   print('Image URL: ${data.imageUrl}');
/// });
/// ```
class WebPageData {
  // ignore: public_member_api_docs
  WebPageData({this.title, this.description, this.imageUrl});

  /// The title of the web page.
  final String? title;

  /// A brief description or summary of the web page.
  final String? description;

  /// The URL of a prominent image on the web page.
  final String? imageUrl;
}
