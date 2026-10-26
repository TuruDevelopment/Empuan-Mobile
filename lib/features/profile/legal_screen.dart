import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';

enum LegalDoc { terms, privacy, guidelines }

const supportEmail = 'support@empuan.com';

class _Section {
  const _Section(this.title, this.body);

  final String title;
  final String body;
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  static const _updated = 'Last updated 23 October 2026';

  @override
  Widget build(BuildContext context) {
    final (title, intro, sections) = switch (doc) {
      LegalDoc.terms => ('Terms of Service', _termsIntro, _terms),
      LegalDoc.privacy => ('Privacy Policy', _privacyIntro, _privacy),
      LegalDoc.guidelines => ('Community guidelines', _guidelinesIntro, _guidelines),
    };
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: EmTopBar(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (doc != LegalDoc.guidelines) ...[
            Text(_updated, style: text.bodySmall),
            const SizedBox(height: 12),
          ],
          Text(intro, style: text.bodyMedium),
          for (final s in sections) ...[
            const SizedBox(height: 20),
            Text(s.title, style: text.titleMedium),
            const SizedBox(height: 6),
            Text(s.body, style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}

const _termsIntro =
    'These terms cover your use of the Empuan app. By creating an account you agree to them. If you don’t agree, please don’t use the app.';

const _terms = [
  _Section('Who can use Empuan', 'You must be 18 or older to create an account and use Empuan.'),
  _Section('Your account',
      'Give accurate details when you sign up and keep your password private. You are responsible for what happens under your account. Tell us at $supportEmail if you think someone else has used it.'),
  _Section('Using the app',
      'Use Empuan lawfully and respectfully. Don’t harass anyone, post hateful, sexual or violent content, share other people’s private information, or try to break the app.'),
  _Section('Safety features',
      'SOS opens your phone’s messages app with a text and, if you allow it, your location. Empuan does not send the message, contact emergency services or monitor your situation. Fake call plays a ringtone on your phone; nobody is called. These features depend on your phone, signal and settings and may not work every time. In an emergency, call 112.'),
  _Section('Courses, articles and Empuan AI',
      'Learning content and answers from Empuan AI are general information. They are not legal, financial or other professional advice, and AI answers can be wrong. Use your own judgement and ask a qualified professional when a decision matters.'),
  _Section('Posts and comments',
      'You own what you post in Her Space and in comments. You let Empuan show it inside the app. Follow the community guidelines. We may remove content or suspend accounts that break these terms. You can report a post, comment or AI answer, and block other members, from the menu next to it.'),
  _Section('Ending your account',
      'You can delete your account at any time in Me › Delete account. We may suspend or close accounts that break these terms.'),
  _Section('Liability',
      'To the extent the law allows, Empuan is not liable for indirect or consequential losses from using or being unable to use the app.'),
  _Section('Changes', 'We may update these terms. We’ll change the date above and tell you in the app about important changes.'),
  _Section('Law', 'These terms are governed by the laws of the Republic of Indonesia.'),
  _Section('Contact', 'Questions about these terms: $supportEmail'),
];

const _privacyIntro =
    'This policy explains what Empuan collects, why, and the choices you have. We don’t sell your personal information.';

const _privacy = [
  _Section('What we collect',
      '• Account details: name, username, email, date of birth and password (stored hashed).\n'
          '• Your interests from sign-up, used to suggest courses and articles.\n'
          '• Trusted contacts and fake-call callers you add: names, phone numbers and relationship.\n'
          '• What you post: Her Space posts, replies, comments and likes.\n'
          '• Learning progress, quiz results and certificates.\n'
          '• Conversations with Empuan AI.\n'
          '• Reports you send and members you block.'),
  _Section('Location',
      'Empuan reads your location only when you send SOS, and only if you allow it. It is added to the text in your messages app. We don’t store it on our servers and never track you in the background.'),
  _Section('Contacts on your phone',
      'When you choose “Choose from phone contacts”, your phone’s own picker opens and shares only the one contact you pick. Empuan can’t see the rest of your address book.'),
  _Section('How we use it',
      'To run your account and the app’s features, keep Her Space safe (including reviewing reports), suggest content, and fix problems.'),
  _Section('Empuan AI',
      'Your messages are sent to our AI provider to generate answers. Don’t share passwords, ID numbers or other sensitive details in chats. You can delete a conversation at any time.'),
  _Section('Sharing',
      'We share data only with service providers that host and run Empuan for us, when the law requires it, or to protect someone’s safety.'),
  _Section('Security', 'Data is encrypted in transit and your login is stored securely on your phone. No system is perfectly secure.'),
  _Section('Your choices',
      'Edit your details in Me › Personal details. Delete chats in Empuan AI. Delete your account in Me › Delete account; we remove your data within 30 days unless the law requires us to keep it.'),
  _Section('Age', 'Empuan is for adults 18 and over. We don’t knowingly collect data from anyone younger.'),
  _Section('Changes', 'We’ll update the date above when this policy changes and tell you in the app about important changes.'),
  _Section('Contact', 'Privacy questions or requests: $supportEmail'),
];

const _guidelinesIntro =
    'Her Space is for women to ask, share and support each other. These guidelines keep it safe. Breaking them can get posts removed or accounts suspended.';

const _guidelines = [
  _Section('Be kind', 'Disagree with ideas, not people. No insults, bullying or pile-ons.'),
  _Section('Keep it safe',
      'No harassment, threats, hate speech, or sexual or violent content. Don’t encourage anyone to hurt themselves or others.'),
  _Section('Protect privacy',
      'Don’t post anyone’s phone number, address, ID or photos without their permission, including your own contact details.'),
  _Section('No scams or spam', 'No selling, loan offers, referral codes or repeated posts.'),
  _Section('Get help when it matters',
      'Her Space isn’t an emergency service. If you or someone else is in danger, call 112 or hold SOS.'),
  _Section('Report and block',
      'Use the ⋯ menu on any post or comment to report it or block the member. Reports are anonymous.'),
];
