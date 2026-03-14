// ─────────────────────────────────────────────────────────────────────────────
// BOOK ALIAS RESOLVER
// Resolves abbreviations, typos, and alternate names to canonical book names.
// ─────────────────────────────────────────────────────────────────────────────

class BookAliasResolver {
  static const Map<String, String> _aliases = {
    'gen': 'Genesis', 'ge': 'Genesis', 'gn': 'Genesis',
    'exo': 'Exodus', 'ex': 'Exodus', 'exod': 'Exodus',
    'lev': 'Leviticus', 'le': 'Leviticus', 'lv': 'Leviticus',
    'num': 'Numbers', 'nu': 'Numbers', 'nm': 'Numbers', 'nb': 'Numbers',
    'deu': 'Deuteronomy', 'deut': 'Deuteronomy', 'dt': 'Deuteronomy', 'de': 'Deuteronomy',
    'jos': 'Joshua', 'josh': 'Joshua', 'jsh': 'Joshua',
    'jdg': 'Judges', 'judg': 'Judges', 'jg': 'Judges', 'jgs': 'Judges',
    'rut': 'Ruth', 'ru': 'Ruth',
    '1sa': '1 Samuel', '1sam': '1 Samuel', '1s': '1 Samuel',
    'i sam': '1 Samuel', 'i samuel': '1 Samuel', '1samuel': '1 Samuel',
    '2sa': '2 Samuel', '2sam': '2 Samuel', '2s': '2 Samuel',
    'ii sam': '2 Samuel', 'ii samuel': '2 Samuel', '2samuel': '2 Samuel',
    '1ki': '1 Kings', '1kgs': '1 Kings', '1k': '1 Kings',
    'i kings': '1 Kings', 'i ki': '1 Kings', '1kings': '1 Kings',
    '2ki': '2 Kings', '2kgs': '2 Kings', '2k': '2 Kings',
    'ii kings': '2 Kings', '2kings': '2 Kings',
    '1ch': '1 Chronicles', '1chr': '1 Chronicles', '1chron': '1 Chronicles',
    'i chron': '1 Chronicles', '1chronicles': '1 Chronicles',
    '2ch': '2 Chronicles', '2chr': '2 Chronicles', '2chron': '2 Chronicles',
    'ii chron': '2 Chronicles', '2chronicles': '2 Chronicles',
    'ezr': 'Ezra', 'ez': 'Ezra',
    'neh': 'Nehemiah', 'ne': 'Nehemiah',
    'est': 'Esther', 'esth': 'Esther', 'es': 'Esther',
    'jb': 'Job',
    'psa': 'Psalms', 'ps': 'Psalms', 'psalm': 'Psalms', 'pss': 'Psalms',
    'pro': 'Proverbs', 'prov': 'Proverbs', 'prv': 'Proverbs', 'pr': 'Proverbs',
    'ecc': 'Ecclesiastes', 'eccl': 'Ecclesiastes', 'qoh': 'Ecclesiastes', 'ec': 'Ecclesiastes',
    'sos': 'Song of Solomon', 'sol': 'Song of Solomon', 'song': 'Song of Solomon',
    'ss': 'Song of Solomon', 'sng': 'Song of Solomon', 'sg': 'Song of Solomon',
    'song of songs': 'Song of Solomon', 'canticles': 'Song of Solomon',
    'isa': 'Isaiah', 'is': 'Isaiah',
    'jer': 'Jeremiah', 'je': 'Jeremiah', 'jr': 'Jeremiah',
    'lam': 'Lamentations', 'la': 'Lamentations',
    'eze': 'Ezekiel', 'ezek': 'Ezekiel', 'ezk': 'Ezekiel',
    'dan': 'Daniel', 'da': 'Daniel', 'dn': 'Daniel',
    'hos': 'Hosea', 'ho': 'Hosea',
    'joe': 'Joel', 'jl': 'Joel',
    'amo': 'Amos', 'am': 'Amos',
    'oba': 'Obadiah', 'ob': 'Obadiah', 'obad': 'Obadiah',
    'jon': 'Jonah', 'jnh': 'Jonah',
    'mic': 'Micah', 'mc': 'Micah',
    'nah': 'Nahum', 'na': 'Nahum',
    'hab': 'Habakkuk', 'hb': 'Habakkuk',
    'zep': 'Zephaniah', 'zeph': 'Zephaniah', 'zp': 'Zephaniah',
    'hag': 'Haggai', 'hg': 'Haggai',
    'zec': 'Zechariah', 'zech': 'Zechariah', 'zc': 'Zechariah',
    'mal': 'Malachi', 'ml': 'Malachi',
    'mat': 'Matthew', 'matt': 'Matthew', 'mt': 'Matthew',
    'mar': 'Mark', 'mrk': 'Mark', 'mk': 'Mark',
    'luk': 'Luke', 'lk': 'Luke',
    'joh': 'John', 'jn': 'John', 'jhn': 'John',
    'act': 'Acts', 'ac': 'Acts',
    'rom': 'Romans', 'ro': 'Romans', 'rm': 'Romans',
    '1co': '1 Corinthians', '1cor': '1 Corinthians',
    'i cor': '1 Corinthians', '1corinthians': '1 Corinthians',
    '2co': '2 Corinthians', '2cor': '2 Corinthians',
    'ii cor': '2 Corinthians', '2corinthians': '2 Corinthians',
    'gal': 'Galatians', 'ga': 'Galatians',
    'eph': 'Ephesians', 'ep': 'Ephesians',
    'php': 'Philippians', 'phil': 'Philippians', 'pp': 'Philippians', 'phl': 'Philippians',
    'col': 'Colossians', 'co': 'Colossians',
    '1th': '1 Thessalonians', '1thes': '1 Thessalonians', '1thess': '1 Thessalonians',
    'i thess': '1 Thessalonians', '1thessalonians': '1 Thessalonians',
    '2th': '2 Thessalonians', '2thes': '2 Thessalonians', '2thess': '2 Thessalonians',
    'ii thess': '2 Thessalonians', '2thessalonians': '2 Thessalonians',
    '1ti': '1 Timothy', '1tim': '1 Timothy', 'i tim': '1 Timothy', '1timothy': '1 Timothy',
    '2ti': '2 Timothy', '2tim': '2 Timothy', 'ii tim': '2 Timothy', '2timothy': '2 Timothy',
    'tit': 'Titus', 'ti': 'Titus',
    'phm': 'Philemon', 'phlm': 'Philemon', 'phile': 'Philemon',
    'heb': 'Hebrews', 'he': 'Hebrews',
    'jas': 'James', 'jm': 'James',
    '1pe': '1 Peter', '1pet': '1 Peter', '1pt': '1 Peter',
    'i pet': '1 Peter', '1peter': '1 Peter',
    '2pe': '2 Peter', '2pet': '2 Peter', '2pt': '2 Peter',
    'ii pet': '2 Peter', '2peter': '2 Peter',
    '1jo': '1 John', '1jn': '1 John', '1joh': '1 John',
    'i john': '1 John', '1john': '1 John',
    '2jo': '2 John', '2jn': '2 John', '2joh': '2 John',
    'ii john': '2 John', '2john': '2 John',
    '3jo': '3 John', '3jn': '3 John', '3joh': '3 John',
    'iii john': '3 John', '3john': '3 John',
    'jud': 'Jude', 'jude': 'Jude',
    'rev': 'Revelation', 're': 'Revelation', 'rv': 'Revelation',
    'apoc': 'Revelation', 'apocalypse': 'Revelation',
  };

  static int _lev(String a, String b) {
    a = a.toLowerCase(); b = b.toLowerCase();
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (int i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = [curr[j] + 1, prev[j + 1] + 1, prev[j] + cost]
            .reduce((x, y) => x < y ? x : y);
      }
      prev.setAll(0, curr);
    }
    return prev[b.length];
  }

  static String resolve(String input, List<String> canonicalBooks) {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) return '';

    for (final b in canonicalBooks) {
      if (b.toLowerCase() == q) return b;
    }

    final aliasHit = _aliases[q];
    if (aliasHit != null) {
      final found = canonicalBooks.firstWhere(
        (b) => b.toLowerCase() == aliasHit.toLowerCase(),
        orElse: () => '',
      );
      if (found.isNotEmpty) return found;
    }

    if (q.length >= 2) {
      final prefixMatches =
          canonicalBooks.where((b) => b.toLowerCase().startsWith(q)).toList();
      if (prefixMatches.length == 1) return prefixMatches.first;
    }

    final threshold = q.length <= 4 ? 2 : 3;
    String bestBook = '';
    int bestDist = threshold + 1;

    for (final b in canonicalBooks) {
      final d = _lev(q, b.toLowerCase());
      if (d < bestDist) { bestDist = d; bestBook = b; }
    }
    for (final entry in _aliases.entries) {
      final d = _lev(q, entry.key);
      if (d < bestDist) {
        final found = canonicalBooks.firstWhere(
          (b) => b.toLowerCase() == entry.value.toLowerCase(),
          orElse: () => '',
        );
        if (found.isNotEmpty) { bestDist = d; bestBook = found; }
      }
    }
    return bestBook;
  }
}
