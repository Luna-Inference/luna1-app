import 'package:universal_ble/universal_ble.dart';
import 'dart:async';

test(){
  // Get scan updates from stream
  UniversalBle.scanStream.listen((BleDevice bleDevice) {
    // e.g. Use BleDevice ID to connect
  });

// Or set a handler
  UniversalBle.onScanResult = (bleDevice) {};

// Perform a scan
  UniversalBle.startScan();

// Or optionally add a scan filter
  UniversalBle.startScan(
      scanFilter: ScanFilter(
        withServices: ["SERVICE_UUID"],
        withManufacturerData: [ManufacturerDataFilter(companyIdentifier: 0x004c)],
        withNamePrefix: ["NAME_PREFIX"],
      )
  );

// Stop scanning
  UniversalBle.stopScan();
}

/// Scans for nearby Bluetooth LE devices for [scanDuration] and returns the
/// discovered device IDs. Each ID is also printed to the console as it is
/// discovered.
Future<List<String>> scanNearbyDeviceIds({Duration scanDuration = const Duration(seconds: 5)}) async {
  final List<String> deviceIds = [];

  // Listen to the scan stream.
  final StreamSubscription<BleDevice> subscription = UniversalBle.scanStream.listen((BleDevice device) {
    if (!deviceIds.contains(device.deviceId)) {
      deviceIds.add(device.deviceId);
      // Print each unique device ID when discovered.
      // ignore: avoid_print
      if (device.deviceId == '03:91:d8:1c:a0:84') {
        // ignore: avoid_print
        print('Target Device Found -> Full Info: '
            'id: \\${device.deviceId}, '
            'name: \\${device.name}, '
            'rawName: \\${device.rawName}, '
            'isSystemDevice: \\${device.isSystemDevice}, '
            'manufacturerData: \\${device.manufacturerData}, \\${device.manufacturerDataList}, '
            'serviceData: \\${device.services}, '
            'rssi: \\${device.rssi}');
      } else {
        // ignore: avoid_print
        print('Found BLE device: \\${device.deviceId}');
      }
    }
  });

  // Start scanning.
  await UniversalBle.startScan();

  // Continue scanning for the specified duration.
  await Future.delayed(scanDuration);

  // Stop scanning and clean up.
  await UniversalBle.stopScan();
  await subscription.cancel();

  return deviceIds;
}