// Demo content for the Home tabs (Prayers, Confessions, Bible commentary).
// The server will supply these already translated, like the Daily Manna.

class DailyPrayer {
  const DailyPrayer({
    required this.title,
    required this.ref,
    required this.body,
    required this.daysAgo,
  });

  final String title;
  final String ref;
  final String body;

  /// 0 is today's prayer.
  final int daysAgo;
}

/// Newest first. The first entry is today's prayer.
const kPrayers = [
  DailyPrayer(
    title: 'For the household',
    ref: 'Joshua 24:15',
    body:
        'Father, we set our house under your name. Let every person under '
        'this roof walk in your peace and return to you at the end of the day.',
    daysAgo: 0,
  ),
  DailyPrayer(
    title: 'For the city',
    ref: 'Jeremiah 29:7',
    body:
        'Lord, we seek the good of our city. Bless its streets, its leaders '
        'and its people, and let your peace rest on every home.',
    daysAgo: 1,
  ),
  DailyPrayer(
    title: 'For those who serve',
    ref: 'Colossians 3:23',
    body:
        'God, strengthen everyone who serves in your house. Let their work '
        'be done as for you, and keep their hearts glad.',
    daysAgo: 2,
  ),
  DailyPrayer(
    title: 'For the sick',
    ref: 'James 5:14',
    body:
        'Healer of all, lay your hand on those who are unwell. Bring comfort '
        'to their bodies and rest to their families.',
    daysAgo: 3,
  ),
];

class Confession {
  const Confession({
    required this.title,
    required this.ref,
    required this.body,
    required this.theme,
  });

  final String title;
  final String ref;
  final String body;

  /// One of [kConfessionThemes].
  final String theme;
}

/// Theme id and its translation key.
const kConfessionThemes = [
  ('healing', 'th_healing'),
  ('provision', 'th_provision'),
  ('family', 'th_family'),
  ('peace', 'th_peace'),
  ('protection', 'th_protection'),
];

/// The first entry is the confession of the day.
const kConfessions = [
  Confession(
    title: 'I am kept in perfect peace',
    ref: 'Isaiah 26:3',
    body:
        'My mind is stayed on him, and he keeps me in perfect peace. I will '
        'not be shaken by what I see today.',
    theme: 'peace',
  ),
  Confession(
    title: 'My needs are met',
    ref: 'Philippians 4:19',
    body:
        'My God supplies every need of mine according to his riches in glory.',
    theme: 'provision',
  ),
  Confession(
    title: 'I am healed',
    ref: 'Isaiah 53:5',
    body:
        'By his stripes I am healed. Health and strength are working in my '
        'body today.',
    theme: 'healing',
  ),
  Confession(
    title: 'My family serves the Lord',
    ref: 'Joshua 24:15',
    body:
        'As for me and my house, we will serve the Lord. Peace and faith '
        'fill our home.',
    theme: 'family',
  ),
  Confession(
    title: 'The Lord is my refuge',
    ref: 'Psalm 91:2',
    body:
        'He is my refuge and my fortress, my God, in whom I trust. No '
        'harm will come near my home.',
    theme: 'protection',
  ),
];

class CommentaryEntry {
  const CommentaryEntry({required this.ref, required this.title});

  final String ref;
  final String title;
}

/// The chapter being studied.
const kCommentaryBook = 'Joel';
const kCommentaryChapter = 2;

const kCommentary = [
  CommentaryEntry(ref: 'Joel 2:1–11', title: 'The day of the Lord'),
  CommentaryEntry(ref: 'Joel 2:12–17', title: 'Return to me'),
  CommentaryEntry(ref: 'Joel 2:18–27', title: 'The years restored'),
  CommentaryEntry(ref: 'Joel 2:28–32', title: 'The Spirit poured out'),
];

class Ebook {
  const Ebook({required this.title, required this.author, required this.pages});

  final String title;
  final String author;
  final int pages;
}

const kEbooks = [
  Ebook(
    title: 'Walking in Compassion',
    author: 'Pastor Michael Fernandes',
    pages: 142,
  ),
  Ebook(
    title: 'The Power of Prayer',
    author: 'Pastor Anita Fernandes',
    pages: 96,
  ),
  Ebook(
    title: 'Restored: Joel for Today',
    author: 'Pastor Samuel Thomas',
    pages: 120,
  ),
  Ebook(
    title: 'Faith in Hard Seasons',
    author: 'Karuna Sadan Ministries',
    pages: 78,
  ),
  Ebook(
    title: 'A Family at the Altar',
    author: 'Pastor Anita Fernandes',
    pages: 64,
  ),
];

class Praise {
  const Praise({
    required this.title,
    required this.body,
    required this.author,
    required this.place,
    required this.daysAgo,
  });

  final String title;
  final String body;
  final String author;
  final String place;
  final int daysAgo;
}

/// Testimonies shared by members. The server will supply these.
const kPraises = [
  Praise(
    title: 'Healing after eight months',
    body: 'The scan came back clear on Tuesday. We had prayed since February with Cell 4 and the pastoral team.',
    author: 'Anil Thomas',
    place: 'Pune Camp',
    daysAgo: 2,
  ),
  Praise(
    title: 'A job after redundancy',
    body: 'After five months without work, an offer arrived the very week our cell fasted together. God is faithful.',
    author: 'Grace Fernandes',
    place: 'Andheri West',
    daysAgo: 3,
  ),
  Praise(
    title: 'Safe delivery',
    body: 'Our baby girl arrived safely after a difficult pregnancy. Thank you to everyone who stood with us in prayer.',
    author: 'Sharon Ninan',
    place: 'Kochi',
    daysAgo: 4,
  ),
  Praise(
    title: 'Reconciled with my brother',
    body: 'We had not spoken for six years. After the Night of Worship he called me, and we wept together.',
    author: 'Joel Mathew',
    place: 'Thane',
    daysAgo: 6,
  ),
  Praise(
    title: 'Freedom from fear',
    body: 'I slept through the night for the first time in years after the pastor prayed with me. Praise God.',
    author: 'Neha Pinto',
    place: 'Bandra',
    daysAgo: 8,
  ),
  Praise(
    title: 'Exam results',
    body: 'I had failed twice. This time I passed with distinction. Thank you for praying for my studies.',
    author: 'Rohan D\'Souza',
    place: 'Vasai',
    daysAgo: 9,
  ),
];
