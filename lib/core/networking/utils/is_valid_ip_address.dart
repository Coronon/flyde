/// Verifies that [address] is a valid IPv4 address.
bool isValidIPAddress(String address) {
  final regex = RegExp(
    r"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$",
  );

  return regex.stringMatch(address)?.length == address.length;
}
