import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../core/printing/print_service.dart';

/// Printer picker (Phase 4): lists Bluetooth-paired thermal printers.
/// Pair the printer in Android Settings first, then pick it here.
/// The choice is remembered for one-tap printing next time.
class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key, required this.slip});
  final SlipData slip;
  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  List<BluetoothInfo> _devices = [];
  bool _loading = true;
  bool _printing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ThermalPrintService.ensurePermissions();
    final on = await ThermalPrintService.bluetoothOn;
    final devices = await ThermalPrintService.bondedPrinters();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _loading = false;
      _message = !on
          ? 'Bluetooth is off — turn it on and pair the printer in Android Settings.'
          : devices.isEmpty
              ? 'No paired printers found. Pair your thermal printer in Android Bluetooth Settings first, then refresh.'
              : null;
    });
  }

  Future<void> _print(BluetoothInfo d) async {
    setState(() => _printing = true);
    await ThermalPrintService.rememberMac(d.macAdress);
    final ok = await ThermalPrintService.printSlip(d.macAdress, widget.slip);
    if (!mounted) return;
    setState(() {
      _printing = false;
      _message = ok
          ? 'Printed to ${d.name}. This printer is now your default.'
          : 'Could not print to ${d.name}. Is it on, in range, and loaded with paper?';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Print QR Slip')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(16), children: [
                if (_message != null)
                  Card(child: Padding(
                      padding: const EdgeInsets.all(12), child: Text(_message!))),
                for (final d in _devices)
                  ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(d.name),
                    subtitle: Text(d.macAdress),
                    trailing: FilledButton(
                      onPressed: _printing ? null : () => _print(d),
                      child: const Text('Print'),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    onPressed: () { setState(() => _loading = true); _load(); }),
                const SizedBox(height: 16),
                const Text('The slip carries your business name, the total, and '
                    'the same signed QR the buyer would scan on screen — so a '
                    'paper customer can still get the digital receipt later.'),
              ]),
      );
}
