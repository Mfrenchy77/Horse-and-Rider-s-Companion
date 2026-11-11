class ConnectionFailure implements Exception {
  const ConnectionFailure(this.message);

  final String message;
}
