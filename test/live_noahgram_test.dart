import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/deep_links.dart';
import 'package:noah_frontend_flutter/data/live_noahgram.dart';
import 'package:noah_frontend_flutter/data/open_target.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/noahgram/live/live_noahgram_screen.dart';
import 'package:noah_frontend_flutter/screens/noahgram/live/ng_pages.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

Map<String, dynamic> _post({
  String id = '500',
  String author = 'Ravi Kumar',
  bool reel = false,
  int likes = 3,
  int comments = 2,
  bool liked = false,
  bool mine = false,
}) => {
  'id': id,
  'author': {'id': '77', 'name': author, 'photoFileId': '900'},
  'caption': 'Sunday service',
  'isReel': reel,
  'media': {'type': reel ? 'video' : 'image', 'fileId': '901', 'url': null},
  'thumbnail': null,
  'createdAt': '2026-11-11T09:00:00.000Z',
  'likes': likes,
  'comments': comments,
  'views': 12,
  'likedByMe': liked,
  'savedByMe': false,
  'mine': mine,
  'shareUrl': 'https://example.test/server/noah_api/share/post/$id',
};

Widget _app(Widget home) => AppLocale(
  controller: LocaleController(),
  child: MaterialApp(theme: buildTheme(), home: home),
);

void main() {
  setUp(liveNoahgram.clear);

  test('a post keeps its author\'s own name and photo, and the share link', () {
    final p = liveNoahgram.canon(_post());
    expect(p.author.name, 'Ravi Kumar');
    expect(p.author.photoFileId, '900');
    expect(p.author.initials, 'RK');
    expect(p.caption, 'Sunday service');
    expect(p.likes, 3);
    expect(p.comments, 2);
    expect(p.views, 12);
    expect(p.isReel, isFalse);
    expect(p.mediaFileId, '901');
    expect(p.shareUrl, endsWith('/share/post/500'));

    // The same post from another list is the same object, so a like shows everywhere.
    final again = liveNoahgram.canon(_post(likes: 9, liked: true));
    expect(identical(again, p), isTrue);
    expect(p.likes, 9);
    expect(p.liked, isTrue);

    final reel = liveNoahgram.canon(_post(id: '501', reel: true));
    expect(reel.isReel, isTrue);
    expect(
      reel.stillSrc,
      isNull,
      reason: 'a reel without a still picture has none',
    );
  });

  test('a shared link opens that post, and nothing else does', () {
    expect(postIdOfLink(Uri.parse('noah://post/12345')), '12345');
    expect(postIdOfLink(Uri.parse('noah://post/12345?x=1')), '12345');
    expect(postIdOfLink(Uri.parse('noah://post/abc')), isNull);
    expect(postIdOfLink(Uri.parse('noah://post/')), isNull);
    expect(postIdOfLink(Uri.parse('noah://other/12345')), isNull);
    expect(postIdOfLink(Uri.parse('https://example.com/post/12345')), isNull);
  });

  test('a notification about Noahgram names the post or the member', () {
    final like = OpenTarget.fromData({
      'type': 'noahgram_like',
      'postId': '500',
    });
    expect(like.isNoahgram, isTrue);
    expect(like.postId, '500');
    final follow = OpenTarget.fromData({
      'type': 'noahgram_follow',
      'memberId': '77',
    });
    expect(follow.isNoahgram, isTrue);
    expect(follow.memberId, '77');
    expect(
      OpenTarget.fromData({'type': 'event_published'}).isNoahgram,
      isFalse,
    );
  });

  testWidgets(
    'the feed shows each post with its author, counts, comments and a share link, and no chat',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      liveNoahgram
        ..posts.add(liveNoahgram.canon(_post()))
        ..postsLoaded = true;
      await tester.pumpWidget(_app(const LiveNoahgramScreen()));
      await tester.pump();

      expect(find.text('Noahgram'), findsOneWidget);
      // The author's own name, in the header and in front of the caption.
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(
        find.textContaining('Sunday service', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('3 likes'), findsOneWidget);
      expect(find.text('View all 2 comments'), findsOneWidget);
      // Share is a link, not a message to a person: no paper-plane (send) icon anywhere.
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      expect(find.byIcon(Icons.send_outlined), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
      expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'a like shows at once, and is taken back when the server does not accept it',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final post = liveNoahgram.canon(_post(likes: 3));
      liveNoahgram
        ..posts.add(post)
        ..postsLoaded = true;
      await tester.pumpWidget(_app(const NgFeedView()));
      await tester.pump();
      expect(find.text('3 likes'), findsOneWidget);

      // The tap changes the count at once, before the server has answered.
      final pending = liveNoahgram.toggleLike(post);
      expect(post.liked, isTrue);
      expect(post.likes, 4);

      // No server in a test: the like is refused and goes back, and the screen is told why.
      await tester.runAsync(() => pending);
      await tester.pump();
      expect(post.liked, isFalse);
      expect(find.text('3 likes'), findsOneWidget);
      expect(liveNoahgram.lastError, isNotNull);
    },
  );

  testWidgets(
    'a post that cannot be loaded offers Try again instead of crashing',
    (tester) async {
      liveNoahgram.clear();
      await tester.pumpWidget(_app(const NgPostScreen(postId: '999')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      // There is no server in a test, so the page says so and lets the member retry.
      expect(find.text('Try again'), findsOneWidget);
    },
  );
}
