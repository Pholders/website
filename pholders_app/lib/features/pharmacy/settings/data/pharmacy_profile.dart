import '../../../../core/network/api_client.dart';

/// The pharmacy's own record, as `/users/pharmacy/profile` returns it.
///
/// Kept as the raw map: each settings page reads and writes a few of its
/// columns, and anything a page does not touch goes back unchanged.
class PharmacyProfile {
  const PharmacyProfile(this.fields);

  final Map<String, dynamic> fields;

  String text(String key) {
    final value = fields[key];
    if (value == null) return '';
    return value.toString();
  }

  bool flag(String key) => fields[key] == true;

  /// `{monday: ["08:00-18:00"], ..., sunday: []}`. An empty day is closed.
  Map<String, List<String>> get operatingHours {
    final raw = fields['operating_hours'];
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value is List
            ? (entry.value as List).map((e) => e.toString()).toList()
            : const <String>[],
    };
  }
}

/// Reads and saves the signed-in pharmacy's profile.
class PharmacyProfileRepository {
  const PharmacyProfileRepository(this._api);

  final ApiClient _api;

  Future<PharmacyProfile> fetch() async {
    return PharmacyProfile(await _api.get('/users/pharmacy/profile'));
  }

  /// Sends only [changes]; the server keeps every other column as it was.
  Future<PharmacyProfile> save(Map<String, dynamic> changes) async {
    return PharmacyProfile(
      await _api.put('/users/pharmacy/profile', body: changes),
    );
  }
}

const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];

/// "08:00-18:00", "08:00-13:00, 14:00-18:00" or "Closed" for one day.
String hoursToText(List<String>? slots) {
  if (slots == null || slots.isEmpty) return 'Closed';
  return slots.join(', ');
}

final _slot = RegExp(r'^([01]\d|2[0-3]):[0-5]\d-([01]\d|2[0-3]):[0-5]\d$');

/// The day's slots from what was typed, or null when it cannot be read.
/// Blank or "closed" means closed.
List<String>? hoursFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'closed') return const [];
  final slots = trimmed
      .split(',')
      .map((s) => s.replaceAll(RegExp(r'\s+'), '').replaceAll('–', '-'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (slots.isEmpty || !slots.every(_slot.hasMatch)) return null;
  return slots;
}
