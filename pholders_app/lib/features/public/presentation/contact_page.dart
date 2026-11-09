import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/constants/contact_emails.dart';
import '../../../shared/theme/app_theme.dart';
import 'widgets/public_page_kit.dart';

/// Contact — opened from the public navbar (and at /support).
///
/// The message form up front, beside the headline; then the support address
/// on its own tile, with links to the pages that may answer the question
/// first. One address for now, the support inbox. In the Features page's
/// look ([PublicPageFrame] and its kit).
///
/// There is no contact endpoint on the server, so nothing is sent from this
/// page: the form opens the visitor's email app with the message filled in,
/// and says so.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key, this.openEmail = _openInEmailApp});

  /// Opens a mailto link; replaced in tests.
  final Future<bool> Function(Uri uri) openEmail;

  @override
  Widget build(BuildContext context) {
    return PublicPageFrame(
      children: [
        HeroBackdrop(
          child: PublicContentWidth(child: _Hero(openEmail: openEmail)),
        ),
        PublicContentWidth(
          child: Reveal(child: _Bento(openEmail: openEmail)),
        ),
        const PublicGap(),
        const PublicContentWidth(child: Reveal(child: PublicCallToAction())),
        const SizedBox(height: 48),
        const PublicContentWidth(child: PublicFooter()),
        const SizedBox(height: 32),
      ],
    );
  }
}

Future<bool> _openInEmailApp(Uri uri) => launchUrl(uri);

/// A mailto link to [to], with a subject and body when given.
Uri mailtoUri(String to, {String? subject, String? body}) {
  final query = <String, String>{
    if (subject != null && subject.isNotEmpty) 'subject': subject,
    if (body != null && body.isNotEmpty) 'body': body,
  };
  return Uri(
    scheme: 'mailto',
    path: to,
    // Spaces as %20, not +: some email apps show a + literally.
    query: query.isEmpty
        ? null
        : query.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&'),
  );
}

/// Opens [uri] (by default a plain email to support), or, when no email app
/// answers, says where to write.
Future<void> _email(
  BuildContext context,
  Future<bool> Function(Uri uri) open, {
  Uri? uri,
}) async {
  const to = ContactEmails.support;
  var opened = false;
  try {
    opened = await open(uri ?? mailtoUri(to));
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('No email app opened. Write to $to'),
      action: SnackBarAction(
        label: 'Copy',
        onPressed: () => Clipboard.setData(const ClipboardData(text: to)),
      ),
    ));
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

/// The headline on the left, the form floating on the right.
class _Hero extends StatelessWidget {
  const _Hero({required this.openEmail});
  final Future<bool> Function(Uri uri) openEmail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final split = c.maxWidth >= 980;
      final small = c.maxWidth < 600;
      final align =
          split ? CrossAxisAlignment.start : CrossAxisAlignment.center;
      final textAlign = split ? TextAlign.start : TextAlign.center;
      final headline = TextStyle(
        fontSize: small ? 46 : 80,
        fontWeight: FontWeight.w800,
        letterSpacing: small ? -1.4 : -3.2,
        height: 1.0,
        color: PublicColors.ink,
      );

      final copy = Column(
        crossAxisAlignment: align,
        children: [
          Reveal(
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: PublicColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      gradient: publicBrandGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mail_outline_rounded,
                        size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('Contact',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PublicColors.body)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            delay: 0.1,
            child: Column(
              crossAxisAlignment: align,
              children: [
                Text('Let\'s talk.', textAlign: textAlign, style: headline),
                GradientText('We\'re here', align: textAlign, style: headline),
                GradientText('to help.', align: textAlign, style: headline),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            delay: 0.2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                'Questions about PHolders, help signing in, or something not '
                'working: tell us here and our support team will answer.',
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: small ? 16 : 19,
                  height: 1.65,
                  color: PublicColors.body,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Reveal(
            delay: 0.3,
            child: Wrap(
              alignment: split ? WrapAlignment.start : WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: const [
                _Chip(Icons.alternate_email_rounded, 'From your own email'),
                _Chip(Icons.support_agent_outlined, 'To our support team'),
                _Chip(Icons.lock_outline_rounded, 'Nothing stored here'),
              ],
            ),
          ),
        ],
      );

      final form = Reveal(delay: 0.25, child: _FormCard(openEmail: openEmail));

      return Padding(
        padding:
            EdgeInsets.only(top: small ? 130 : 170, bottom: small ? 64 : 104),
        child: split
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 10, child: copy),
                  const SizedBox(width: 56),
                  Expanded(flex: 9, child: form),
                ],
              )
            : Column(children: [copy, const SizedBox(height: 44), form]),
      );
    });
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: PublicColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: PublicColors.teal),
          const SizedBox(width: 7),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: PublicColors.ink)),
        ],
      ),
    );
  }
}

/// The form, on a white card with a gradient edge, floating over the
/// backdrop.
class _FormCard extends StatefulWidget {
  const _FormCard({required this.openEmail});
  final Future<bool> Function(Uri uri) openEmail;

  @override
  State<_FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<_FormCard> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _write() async {
    if (!_form.currentState!.validate()) return;
    final name = _name.text.trim();
    final uri = mailtoUri(
      ContactEmails.support,
      subject: 'Message from $name',
      body: '${_message.text.trim()}\n\n$name',
    );
    await _email(context, widget.openEmail, uri: uri);
  }

  InputDecoration _field(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, size: 20, color: PublicColors.teal),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        labelStyle: const TextStyle(color: PublicColors.body),
        hintStyle: const TextStyle(color: Color(0xFFA7B3B6)),
        filled: true,
        fillColor: const Color(0xFFF5F9FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PublicColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PublicColors.aqua, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5484D)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1.8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;
    const input = TextStyle(fontSize: 15.5, color: PublicColors.ink);

    // The gradient shows as a thin edge round the white card.
    return Container(
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FE0E6), Color(0xFFE6EEEF), Color(0xFF309CA3)],
        ),
        boxShadow: [
          BoxShadow(
            color: PublicColors.deep.withValues(alpha: 0.14),
            blurRadius: 60,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(small ? 22 : 34),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(30.4),
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: publicBrandGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send us a message',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: PublicColors.ink,
                            )),
                        SizedBox(height: 2),
                        Text('To ${ContactEmails.support}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13.5, color: PublicColors.body)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: _name,
                style: input,
                cursorColor: PublicColors.teal,
                decoration: _field('Your name', Icons.person_outline_rounded),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Tell us your name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _message,
                style: input,
                cursorColor: PublicColors.teal,
                minLines: 6,
                maxLines: 10,
                decoration: _field('Message', Icons.chat_bubble_outline_rounded,
                    hint: 'How can we help?'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Write your message'
                    : null,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: _WriteButton(onTap: _write),
              ),
              const SizedBox(height: 14),
              const Text(
                'Your email app opens with the message written, ready for '
                'you to send.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: PublicColors.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The form's send button: full width, dark, its arrow nudging on hover.
class _WriteButton extends StatefulWidget {
  const _WriteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_WriteButton> createState() => _WriteButtonState();
}

class _WriteButtonState extends State<_WriteButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: PublicColors.ink,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: PublicColors.ink.withValues(alpha: _hover ? 0.3 : 0.15),
                blurRadius: _hover ? 26 : 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Write the email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
              const SizedBox(width: 10),
              AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: Offset(_hover ? 0.25 : 0, 0),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 19, color: PublicColors.aqua),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Below the hero ───────────────────────────────────────────────────────────

/// The support address on a wide dark tile, beside tiles for the pages that
/// may answer the question first.
class _Bento extends StatelessWidget {
  const _Bento({required this.openEmail});
  final Future<bool> Function(Uri uri) openEmail;

  @override
  Widget build(BuildContext context) {
    const helps = [
      (
        Icons.route_rounded,
        'How it works',
        'A prescription, step by step.',
        AppRoutes.howItWorks
      ),
      (
        Icons.grid_view_rounded,
        'Services',
        'What PHolders runs, and for whom.',
        AppRoutes.services
      ),
      (
        Icons.auto_awesome_outlined,
        'Features',
        'Everything the platform does.',
        AppRoutes.features
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 980;
      const gap = 20.0;
      final address = _AddressTile(onOpen: () => _email(context, openEmail));
      final tiles = [
        for (final (icon, title, line, route) in helps)
          _HelpTile(icon: icon, title: title, line: line, route: route),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BEFORE YOU WRITE',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: PublicColors.teal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The answer may already be here',
            style: TextStyle(
              fontSize: wide ? 40 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: wide ? -1.2 : -0.6,
              height: 1.15,
              color: PublicColors.ink,
            ),
          ),
          const SizedBox(height: 32),
          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: address),
                  const SizedBox(width: gap),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          if (i > 0) const SizedBox(height: gap),
                          Expanded(child: tiles[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                address,
                for (final t in tiles) ...[const SizedBox(height: gap), t],
              ],
            ),
        ],
      );
    });
  }
}

/// The support address, large, on a dark tile: a click writes to it, the
/// button copies it.
class _AddressTile extends StatefulWidget {
  const _AddressTile({required this.onOpen});
  final VoidCallback onOpen;

  @override
  State<_AddressTile> createState() => _AddressTileState();
}

class _AddressTileState extends State<_AddressTile> {
  bool _hover = false;
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(const ClipboardData(text: ContactEmails.support));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
          constraints: const BoxConstraints(minHeight: 340),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B2427), PublicColors.deep, Color(0xFF14464A)],
            ),
            boxShadow: [
              BoxShadow(
                color: PublicColors.deep.withValues(alpha: _hover ? 0.32 : 0.2),
                blurRadius: _hover ? 56 : 40,
                offset: Offset(0, _hover ? 26 : 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -100,
                bottom: -120,
                child: IgnorePointer(
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        PublicColors.aqua.withValues(alpha: 0.4),
                        PublicColors.aqua.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
              ),
              // A large faint @ behind the words.
              Positioned(
                right: 24,
                top: -20,
                child: IgnorePointer(
                  child: Icon(Icons.alternate_email_rounded,
                      size: small ? 140 : 200,
                      color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(small ? 24 : 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: publicBrandGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.support_agent_outlined,
                              size: 27, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email support',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )),
                              SizedBox(height: 2),
                              Text('For every question, for now',
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xFFB7CDD0))),
                            ],
                          ),
                        ),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 200),
                          offset: Offset(_hover ? 0.15 : 0, 0),
                          child: const Icon(Icons.north_east_rounded,
                              size: 24, color: PublicColors.aqua),
                        ),
                      ],
                    ),
                    SizedBox(height: small ? 40 : 64),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: GradientText(
                        ContactEmails.support,
                        style: TextStyle(
                          fontSize: small ? 28 : 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: small ? -0.6 : -1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: small ? 20 : 26),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _TileButton(
                          icon: Icons.edit_outlined,
                          label: 'Write an email',
                          filled: true,
                          onTap: widget.onOpen,
                        ),
                        _TileButton(
                          icon: _copied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          label: _copied ? 'Copied' : 'Copy address',
                          onTap: _copy,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(30),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17, color: filled ? PublicColors.teal : Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: filled ? PublicColors.ink : Colors.white,
                )),
          ],
        ),
      ),
    );
  }
}

/// A page that may answer the question first.
class _HelpTile extends StatefulWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.line,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String line;
  final String route;

  @override
  State<_HelpTile> createState() => _HelpTileState();
}

class _HelpTileState extends State<_HelpTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFF3FAFB) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hover
                  ? PublicColors.aqua.withValues(alpha: 0.7)
                  : PublicColors.hairline,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PublicColors.aqua.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(widget.icon, size: 24, color: PublicColors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: PublicColors.ink,
                        )),
                    const SizedBox(height: 3),
                    Text(widget.line,
                        style: const TextStyle(
                            fontSize: 14, color: PublicColors.body)),
                  ],
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: Offset(_hover ? 0.2 : 0, 0),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 20, color: PublicColors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
