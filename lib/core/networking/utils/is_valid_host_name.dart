/// Verifies that [address] is a valid DNS host address.
bool isValidHostName(String address) {
  final regex = RegExp(
    r"^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$",
  );

  return regex.stringMatch(address)?.length == address.length;
}
