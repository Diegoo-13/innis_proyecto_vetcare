import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';
import 'pet_detail_screen.dart';

class ClientePetsTab extends StatefulWidget {
  const ClientePetsTab({super.key});

  @override
  State<ClientePetsTab> createState() => _ClientePetsTabState();
}

class _ClientePetsTabState extends State<ClientePetsTab> {
  bool _adding = false;
  String _species = 'Perro';
  final TextEditingController _name = TextEditingController();
  final TextEditingController _breed = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _owner = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _color.dispose();
    _age.dispose();
    _owner.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final state = AppScope.of(context, listen: false);
    final String? err = state.addPet(
      name: _name.text,
      species: _species,
      category: categoryForSpecies(_species),
      breed: _breed.text,
      color: _color.text,
      age: _age.text,
      owner: _owner.text,
      phone: _phone.text,
    );
    if (err != null) {
      toast(context, err);
      return;
    }
    toast(context, '${_name.text.trim()} fue registrado/a');
    setState(() {
      _adding = false;
      _species = 'Perro';
      _name.clear();
      _breed.clear();
      _color.clear();
      _age.clear();
      _owner.clear();
      _phone.clear();
    });
  }

  Widget _form() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: spaced([
          const Text('Nueva mascota', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          AppField(label: 'Nombre', controller: _name, hint: 'Ej. Rocco'),
          AppDropdown<String>(
            label: 'Especie',
            value: _species,
            items: kSpecies,
            labelOf: (String s) => s,
            onChanged: (String? v) => setState(() => _species = v ?? _species),
          ),
          Row(
            children: [
              const Text('Categoría: ', style: TextStyle(fontSize: 12.5, color: C.muted)),
              Pill(categoryForSpecies(_species).label, kind: PillKind.info),
            ],
          ),
          AppField(label: 'Raza', controller: _breed, hint: 'Ej. Golden Retriever'),
          AppField(label: 'Color', controller: _color, hint: 'Ej. Dorado'),
          AppField(label: 'Edad', controller: _age, hint: 'Años o texto, ej. 3 meses', keyboardType: TextInputType.text),
          AppField(label: 'Dueño (opcional)', controller: _owner, hint: 'Por defecto, tu nombre'),
          AppField(label: 'Teléfono (opcional)', controller: _phone, hint: 'Por defecto, tu teléfono', keyboardType: TextInputType.phone),
          Row(
            children: [
              Expanded(child: AppButton('Cancelar', kind: BtnKind.ghost, onPressed: () => setState(() => _adding = false))),
              const SizedBox(width: 10),
              Expanded(child: AppButton('Guardar', onPressed: _save)),
            ],
          ),
        ], 12),
      ),
    );
  }

  Widget _petCard(Pet p) {
    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PetDetailScreen(petId: p.id))),
      child: Row(
        children: [
          PetAvatar(species: p.species, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                Text('${p.species} · ${p.breed}', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: C.muted)),
                Text('${p.code} · ${p.age}', style: const TextStyle(fontSize: 11.5, color: C.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: C.muted),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final List<Pet> pets = state.clientPets;
    final List<Widget> groups = <Widget>[];
    for (final PetCategory c in PetCategory.values) {
      final List<Pet> inCat = pets.where((Pet p) => p.category == c).toList();
      if (inCat.isEmpty) continue;
      groups.add(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(c.label),
          const SizedBox(height: 8),
          ...spaced(inCat.map(_petCard).toList(), 10),
        ],
      ));
    }
    return TabPage(
      header: RootBar(
        title: 'Mis mascotas',
        trailing: _adding ? null : IconBtn(icon: Icons.add, onTap: () => setState(() => _adding = true), tooltip: 'Agregar'),
      ),
      children: [
        if (_adding) _form(),
        if (pets.isEmpty && !_adding)
          const AppCard(
            child: Text('Aún no tienes mascotas registradas. Toca + para agregar la primera.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: C.muted)),
          ),
        ...groups,
      ],
    );
  }
}
