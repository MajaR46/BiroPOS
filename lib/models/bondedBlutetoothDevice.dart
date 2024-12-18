class BondedDevice {
  final String name;
  final String adress;

  BondedDevice({required this.name, required this.adress});

  factory BondedDevice.fronRawString(String result) {
    final parts = result.split(' (');
    return BondedDevice(
        name: parts[0],
        adress: parts.length > 1
            ? parts[1].replaceFirst(')', '').trim()
            : 'Unknown');
  }
}
