import 'dart:ui' as ui;

/// Страна для выбора кода телефона на экране входа.
class Country {
  const Country(this.iso, this.name, this.dialCode);

  /// ISO 3166-1 alpha-2, например 'RU'.
  final String iso;

  /// Отображаемое название.
  final String name;

  /// Телефонный код без «+», например '7'.
  final String dialCode;

  /// Флаг-эмодзи из ISO-кода (региональные индикаторы), рисуется без ассетов.
  String get flag {
    if (iso.length != 2) return '🏳️';
    final a = iso.codeUnitAt(0);
    final b = iso.codeUnitAt(1);
    if (a < 0x41 || a > 0x5A || b < 0x41 || b > 0x5A) return '🏳️';
    return String.fromCharCode(0x1F1E6 + (a - 0x41)) +
        String.fromCharCode(0x1F1E6 + (b - 0x41));
  }
}

/// Список стран с телефонными кодами. Приоритет — СНГ и Европа (реальные
/// пользователи), плюс крупные страны мира. Флаг вычисляется из ISO.
const List<Country> kCountries = [
  Country('RU', 'Россия', '7'),
  Country('KZ', 'Казахстан', '7'),
  Country('BY', 'Беларусь', '375'),
  Country('UA', 'Украина', '380'),
  Country('UZ', 'Узбекистан', '998'),
  Country('KG', 'Кыргызстан', '996'),
  Country('TJ', 'Таджикистан', '992'),
  Country('TM', 'Туркменистан', '993'),
  Country('AZ', 'Азербайджан', '994'),
  Country('AM', 'Армения', '374'),
  Country('GE', 'Грузия', '995'),
  Country('MD', 'Молдова', '373'),
  Country('EE', 'Эстония', '372'),
  Country('LV', 'Латвия', '371'),
  Country('LT', 'Литва', '370'),
  Country('AB', 'Абхазия', '7'),
  // Европа
  Country('DE', 'Германия', '49'),
  Country('FR', 'Франция', '33'),
  Country('GB', 'Великобритания', '44'),
  Country('IT', 'Италия', '39'),
  Country('ES', 'Испания', '34'),
  Country('PL', 'Польша', '48'),
  Country('CZ', 'Чехия', '420'),
  Country('SK', 'Словакия', '421'),
  Country('AT', 'Австрия', '43'),
  Country('CH', 'Швейцария', '41'),
  Country('NL', 'Нидерланды', '31'),
  Country('BE', 'Бельгия', '32'),
  Country('SE', 'Швеция', '46'),
  Country('NO', 'Норвегия', '47'),
  Country('FI', 'Финляндия', '358'),
  Country('DK', 'Дания', '45'),
  Country('PT', 'Португалия', '351'),
  Country('GR', 'Греция', '30'),
  Country('IE', 'Ирландия', '353'),
  Country('HU', 'Венгрия', '36'),
  Country('RO', 'Румыния', '40'),
  Country('BG', 'Болгария', '359'),
  Country('RS', 'Сербия', '381'),
  Country('HR', 'Хорватия', '385'),
  Country('SI', 'Словения', '386'),
  Country('BA', 'Босния и Герцеговина', '387'),
  Country('MK', 'Северная Македония', '389'),
  Country('AL', 'Албания', '355'),
  Country('ME', 'Черногория', '382'),
  Country('IS', 'Исландия', '354'),
  Country('CY', 'Кипр', '357'),
  Country('MT', 'Мальта', '356'),
  Country('LU', 'Люксембург', '352'),
  // Ближний Восток
  Country('TR', 'Турция', '90'),
  Country('IL', 'Израиль', '972'),
  Country('AE', 'ОАЭ', '971'),
  Country('SA', 'Саудовская Аравия', '966'),
  Country('QA', 'Катар', '974'),
  Country('KW', 'Кувейт', '965'),
  Country('IR', 'Иран', '98'),
  Country('IQ', 'Ирак', '964'),
  Country('SY', 'Сирия', '963'),
  Country('JO', 'Иордания', '962'),
  Country('LB', 'Ливан', '961'),
  // Азия
  Country('CN', 'Китай', '86'),
  Country('IN', 'Индия', '91'),
  Country('JP', 'Япония', '81'),
  Country('KR', 'Республика Корея', '82'),
  Country('TH', 'Таиланд', '66'),
  Country('VN', 'Вьетнам', '84'),
  Country('ID', 'Индонезия', '62'),
  Country('MY', 'Малайзия', '60'),
  Country('SG', 'Сингапур', '65'),
  Country('PH', 'Филиппины', '63'),
  Country('PK', 'Пакистан', '92'),
  Country('BD', 'Бангладеш', '880'),
  Country('LK', 'Шри-Ланка', '94'),
  Country('MN', 'Монголия', '976'),
  // Америка
  Country('US', 'США', '1'),
  Country('CA', 'Канада', '1'),
  Country('MX', 'Мексика', '52'),
  Country('BR', 'Бразилия', '55'),
  Country('AR', 'Аргентина', '54'),
  Country('CL', 'Чили', '56'),
  Country('CO', 'Колумбия', '57'),
  Country('PE', 'Перу', '51'),
  Country('VE', 'Венесуэла', '58'),
  Country('CU', 'Куба', '53'),
  // Африка / Океания
  Country('EG', 'Египет', '20'),
  Country('ZA', 'ЮАР', '27'),
  Country('NG', 'Нигерия', '234'),
  Country('MA', 'Марокко', '212'),
  Country('DZ', 'Алжир', '213'),
  Country('TN', 'Тунис', '216'),
  Country('AU', 'Австралия', '61'),
  Country('NZ', 'Новая Зеландия', '64'),
];

/// Страна по умолчанию: как в официальном приложении (o2j.z) — сначала регион
/// SIM/сети, затем локаль устройства. Плагина SIM у нас нет, поэтому берём
/// код страны из локали устройства (это и есть fallback официалки).
Country defaultCountry() {
  final region = ui.PlatformDispatcher.instance.locale.countryCode;
  if (region != null) {
    final iso = region.toUpperCase();
    for (final c in kCountries) {
      if (c.iso == iso) return c;
    }
  }
  return kCountries.first; // Россия
}

/// Найти страну по ISO, либо Россия.
Country countryByIso(String iso) {
  final up = iso.toUpperCase();
  for (final c in kCountries) {
    if (c.iso == up) return c;
  }
  return kCountries.first;
}
