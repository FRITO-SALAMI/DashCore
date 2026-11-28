import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';
import '../services/manual_vehicle_service.dart';

class ManualVehicleScreen extends StatefulWidget {
  const ManualVehicleScreen({super.key});
  @override
  State<ManualVehicleScreen> createState() => _ManualVehicleScreenState();
}

class _ManualVehicleScreenState extends State<ManualVehicleScreen> {
  final _form = GlobalKey<FormState>();
  final _brand = TextEditingController(),
      _name = TextEditingController(),
      _year = TextEditingController();
  String? _photo, _rearPhoto;
  String _color = '#EDF1F5';
  static const _paintOptions = {
    '#EDF1F5': ('Blanco', Color(0xFFEDF1F5)),
    '#A7AFBC': ('Plata', Color(0xFFA7AFBC)),
    '#2F3846': ('Grafito', Color(0xFF2F3846)),
    '#C4444A': ('Rojo', Color(0xFFC4444A)),
    '#3971BA': ('Azul', Color(0xFF3971BA)),
    '#407A69': ('Verde', Color(0xFF407A69)),
  };
  bool _busy = false, _ai = false;
  Future<void> _choosePhoto(bool rear) async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;
    setState(() {
      if (rear)
        _rearPhoto = photo.path;
      else
        _photo = photo.path;
    });
  }

  @override
  void dispose() {
    _brand.dispose();
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final settings = context.read<DashSettingsProvider>();
    try {
      var vehicle = await ManualVehicleService.create(
        name: _name.text,
        brand: _brand.text,
        year: _year.text,
        paintColorHex: _color,
      );
      if (_photo != null)
        vehicle = await ManualVehicleService.attachPhoto(
          vehicle,
          File(_photo!),
          cutout: _ai,
        );
      if (_rearPhoto != null) {
        vehicle = await ManualVehicleService.attachPhoto(
          vehicle,
          File(_rearPhoto!),
          rear: true,
          cutout: true,
        );
      }
      await settings.registerManualVehicle(vehicle);
      final retainedBackground =
          (_ai &&
              _photo != null &&
              vehicle.artworkPath?.endsWith('cutout.png') != true) ||
          (_rearPhoto != null &&
              vehicle.rearArtworkPath?.endsWith('cutout_rear.png') != true);
      if (!mounted) return;
      if (retainedBackground)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Guardamos la imagen local con su fondo. El recorte no estuvo disponible.',
            ),
          ),
        );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('FormatException: ', ''),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF090F18),
    appBar: AppBar(
      title: const Text('TU VEHÍCULO'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(_busy ? 'GUARDANDO…' : 'GUARDAR'),
          ),
        ),
      ],
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Un garaje a tu medida',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tu vehículo. Su vista superior funciona sin descargar modelos. Puedes guardar fotos en tu ficha.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _brand,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Marca'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Introduce la marca' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Modelo o nombre'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Introduce el modelo' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _year,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'Año / versión (opcional)',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Color en el taller',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final color in _paintOptions.entries)
                ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: color.value.$2),
                  label: Text(color.value.$1),
                  selected: _color == color.key,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _color = color.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _choosePhoto(false),
                icon: const Icon(Icons.photo_outlined),
                label: const Text('FOTO DEL VEHÍCULO'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _choosePhoto(true),
                icon: const Icon(Icons.camera_rear_outlined),
                label: const Text('FOTO TRASERA'),
              ),
            ],
          ),
          if (_rearPhoto != null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'El recorte de la foto trasera se procesa en este equipo.',
              ),
            ),
          if (_photo != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(_photo!),
                  fit: BoxFit.contain,
                  cacheWidth: 640,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _ai,
              onChanged: _busy ? null : (v) => setState(() => _ai = v),
              title: const Text('Recortar el fondo con IA local'),
              subtitle: const Text(
                'Android procesa y guarda la imagen en este equipo.',
              ),
            ),
            if (_ai)
              const Text(
                'Se conserva el ángulo original del vehículo. Para un diseño frontal, selecciona una foto de frente.',
                style: TextStyle(color: Colors.white60),
              ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    ),
  );
}
