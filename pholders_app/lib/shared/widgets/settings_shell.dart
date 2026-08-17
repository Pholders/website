import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsShell extends StatelessWidget {
  const SettingsShell({super.key, required this.child});

  final Widget child;

  static const Color pageMint = Color(0xFFE5F8F9);
  static const Color panelMint = Color(0xFFE2F7F8);
  static const Color accent = Color(0xFF66CBD2);
  static const Color text = Color(0xFF111111);
  static const Color muted = Color(0xFFA8A8A8);
  static const Color divider = Color(0xFFEDEDED);
  static const Color success = Color(0xFF5DBB63);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pageMint,
      child: child,
    );
  }
}

class SettingsContentCard extends StatelessWidget {
  const SettingsContentCard({
    super.key,
    required this.title,
    required this.children,
    this.showEdit = true,
    this.padding = const EdgeInsets.fromLTRB(28, 24, 28, 24),
  });

  final String title;
  final List<Widget> children;
  final bool showEdit;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border(
          left: BorderSide(color: SettingsShell.accent, width: 1),
          bottom: BorderSide(color: SettingsShell.accent, width: 6),
        ),
      ),
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsCardHeader(title: title, showEdit: showEdit),
            const SettingsDivider(),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SettingsCardHeader extends StatelessWidget {
  const SettingsCardHeader({
    super.key,
    required this.title,
    this.showEdit = true,
  });

  final String title;
  final bool showEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleIconButton(icon: Icons.arrow_back, size: 28),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: SettingsShell.text,
          ),
        ),
        const Spacer(),
        if (showEdit)
          const Icon(
            Icons.edit_outlined,
            size: 22,
            color: Colors.black,
          ),
      ],
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.size = 26,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFBFEFEB),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: const Color(0xFF25A8A9),
        size: size * .72,
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: Divider(color: SettingsShell.divider, thickness: 2, height: 2),
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: muted ? 12 : 16,
        fontWeight: muted ? FontWeight.w400 : FontWeight.w700,
        color: muted ? SettingsShell.muted : SettingsShell.text,
      ),
    );
  }
}

class SettingsInput extends StatefulWidget {
  const SettingsInput({
    super.key,
    this.text = '',
    this.hint,
    this.icon,
    this.trailing,
    this.width,
    this.height = 27,
    this.controller,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines,
    this.inputFormatters,
  });

  final String text;
  final String? hint;
  final IconData? icon;
  final Widget? trailing;
  final double? width;
  final double height;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<SettingsInput> createState() => _SettingsInputState();
}

class _SettingsInputState extends State<SettingsInput> {
  late final TextEditingController _localcontroller;

  TextEditingController get _controller => widget.controller ?? _localcontroller;

  @override
  void initState() {
    super.initState();
    _localcontroller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant SettingsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.text != widget.text) {
      _localcontroller.text = widget.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: SettingsShell.panelMint,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFCFECEE)),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 15, color: const Color(0xFF7B8A8C)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              enabled: widget.enabled,
              controller: _controller,
              readOnly: widget.readOnly || widget.onTap != null,
              onTap: widget.onTap,
              maxLines: widget.maxLines ?? (widget.height > 60 ? null : 1),
              expands: widget.height > 60 && widget.maxLines == null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFB8B8B8),
                ),
              ),
              inputFormatters: widget.inputFormatters,
              style: const TextStyle(
                fontSize: 15,
                color:Color(0xFF7F8A8A)
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );

    if (widget.width == null) return child;
    return SizedBox(width: widget.width, child: child);
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton(
    this.label, {
    super.key,
    this.width,
    this.icon,
    this.filled = true,
    this.height = 28,
    this.onTap,
  });

  final String label;
  final double? width;
  final IconData? icon;
  final bool filled;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap ??
            () {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(content: Text('$label tapped')),
              );
            },
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: filled ? SettingsShell.panelMint : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SettingsShell.accent),
            boxShadow: filled
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: filled ? FontWeight.w500 : FontWeight.w400,
                    color: const Color(0xFF1598A5),
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 10),
                Icon(icon, size: 16, color: const Color(0xFF1598A5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TinySwitch extends StatefulWidget {
  const TinySwitch({super.key, this.value = true, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<TinySwitch> createState() => _TinySwitchState();
}

class _TinySwitchState extends State<TinySwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _value = !_value);
        widget.onChanged?.call(_value);
      },
      child: Container(
        width: 22,
        height: 12,
        alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _value ? SettingsShell.success : const Color(0xFFD8D8D8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class SmallCheck extends StatefulWidget {
  const SmallCheck({super.key, this.checked = true, this.onChanged});

  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  State<SmallCheck> createState() => _SmallCheckState();
}

class _SmallCheckState extends State<SmallCheck> {
  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.checked;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _checked = !_checked);
        widget.onChanged?.call(_checked);
      },
      child: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.4),
          borderRadius: BorderRadius.circular(2),
        ),
        child: _checked ? const Icon(Icons.check, size: 11) : null,
      ),
    );
  }
}

class SettingsFullWidthAction extends StatelessWidget {
  const SettingsFullWidthAction(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap ??
            () {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(content: Text('$label tapped')),
              );
            },
        child: Container(
          height: 28,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SettingsShell.panelMint,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCFECEE)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
