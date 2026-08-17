import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../shared/widgets/settings_shell.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return initialTab == 1
        ? const _ProfessionalDetails()
        : const _ProfileDetails();
  }
}

class _ProfileDetails extends StatefulWidget {
  const _ProfileDetails();

  @override
  State<_ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<_ProfileDetails> {
  @override
  Widget build(BuildContext context) {
    return SettingsContentCard(
      title: 'Profile Details',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 9,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(110),
                    child: Image.asset(
                      'assets/icons/DrSam.png',
                      width: 190,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SettingsButton(
  'Upload photo',
  onTap: () async {
    await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
  },
),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 22),
                      child: Text('About', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 154,
                    margin: const EdgeInsets.only(right: 18),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    decoration: BoxDecoration(
                      color: SettingsShell.panelMint,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCFECEE)),
                    ),
                    child: const Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Write a Bio about yourself for patients\nto know your background',
                            style: TextStyle(
                                fontSize: 12, color: SettingsShell.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 26),
            const Expanded(
              flex: 12,
              child: _ProfileForm(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm();

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('Personal Information', muted: true),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(child: _Field(label: 'First Name')),
            SizedBox(width: 22),
            Expanded(child: _Field(label: 'Last Name')),
          ],
        ),
        const SizedBox(height: 24),
        const SettingsSectionTitle('Contact Information', muted: true),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: _Field(label: 'Email Address')),
            const SizedBox(width: 22),
            Expanded(child: _Field(label: 'Phone Number', hint: '0123456789',
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],)),
          ],
        ),
        const SizedBox(height: 26),
        const SettingsSectionTitle('Additional Information', muted: true),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
                child: _Field(
                    label: 'Date of Birth',
                    hint: 'Select Date',
                    icon: Icons.calendar_month)),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gender', 
                    style: TextStyle(fontSize: 16)
                    ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFEAF8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide (
                          color: Color(0xFFCFECEE)),
                      ),
                    ),
                  hint: const Text('Select Gender'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male'),),
                    DropdownMenuItem(value: 'female', child: Text('Female'),),
                    DropdownMenuItem(value: 'other', child: Text('Other'),),
                    DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say'),),
                  ],
                  onChanged: (value) {},
              ),
            ],
          ),
        ),
          ]),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Nationality',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEAF8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        hint: const Text('South African'),
        items: const [
          DropdownMenuItem(value: 'South African',child: Text('South African'),),
          DropdownMenuItem(value: 'Zimbabwean',child: Text('Zimbabwean'),),
          DropdownMenuItem(value: 'Botswanan',child: Text('Botswanan'),),
          DropdownMenuItem(value: 'Namibian',child: Text('Namibian'),),
          DropdownMenuItem(value: 'Mozambican',child: Text('Mozambican'),),
          DropdownMenuItem(value: 'Lesotho',child: Text('Lesotho'),),
          DropdownMenuItem(value: 'Eswatini',child: Text('Eswatini'),),
          DropdownMenuItem(value: 'Other',child: Text('Other'),),
        ],
        onChanged: (value) {},
      ),
    ],
  ),
),
            const SizedBox(width: 22),
            Expanded(child: _Field(label: 'ID Number', hint: '0123456789012', inputFormatters: [FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(13)],)),
          ],
        ),
        const SizedBox(height: 26),
        Align(
  alignment: Alignment.centerRight,
  child: SettingsButton(
    isEditing ? 'Save Changes' : 'Edit',
    icon: isEditing
        ? Icons.save_outlined
        : Icons.edit_outlined,
    width: 140,
    height: 34,
    onTap: () {
      setState(() {
        isEditing = !isEditing;
      });
    },
  ),
),
      ],
    );
  }
}

class _ProfessionalDetails extends StatelessWidget {
  const _ProfessionalDetails();

  @override
  Widget build(BuildContext context) {
    return SettingsContentCard(
      title: 'Professional Details',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSectionTitle('Medical Credentials', muted: true),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(child: _Field(label: 'Medical License Number')),
                  SizedBox(width: 48),
                  Expanded(child: _Field(label: 'HPCSA Number')),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Specialization',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEAF8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        hint: const Text('Select Specialization'),
        items: const [
          DropdownMenuItem(
            value: 'General Practitioner',
            child: Text('General Practitioner'),
          ),
          DropdownMenuItem(
            value: 'Cardiologist',
            child: Text('Cardiologist'),
          ),
          DropdownMenuItem(
            value: 'Dermatologist',
            child: Text('Dermatologist'),
          ),
          DropdownMenuItem(
            value: 'Neurologist',
            child: Text('Neurologist'),
          ),
          DropdownMenuItem(
            value: 'Paediatrician',
            child: Text('Paediatrician'),
          ),
          DropdownMenuItem(
            value: 'Psychiatrist',
            child: Text('Psychiatrist'),
          ),
        ],
        onChanged: (value) {},
      ),
    ],
  ),
),
                  const SizedBox(width: 48),
                  const Expanded(child: _Field(label: 'Years of Experience')),
                ],
              ),
              const SizedBox(height: 28),
              const SettingsSectionTitle('Practice Information', muted: true),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(child: _Field(label: 'Practice Name')),
                  SizedBox(width: 48),
                  Expanded(child: _Field(label: 'Practice Address')),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: _Field(
                      label: 'City',
                      hint: 'Johannesburg',
                      trailing: Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF748486)),
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Province',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEAF8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        hint: const Text('Gauteng'),
        items: const [
          DropdownMenuItem(
            value: 'Eastern Cape',
            child: Text('Eastern Cape'),
          ),
          DropdownMenuItem(
            value: 'Free State',
            child: Text('Free State'),
          ),
          DropdownMenuItem(
            value: 'Gauteng',
            child: Text('Gauteng'),
          ),
          DropdownMenuItem(
            value: 'KwaZulu-Natal',
            child: Text('KwaZulu-Natal'),
          ),
          DropdownMenuItem(
            value: 'Limpopo',
            child: Text('Limpopo'),
          ),
          DropdownMenuItem(
            value: 'Mpumalanga',
            child: Text('Mpumalanga'),
          ),
          DropdownMenuItem(
            value: 'Northern Cape',
            child: Text('Northern Cape'),
          ),
          DropdownMenuItem(
            value: 'North West',
            child: Text('North West'),
          ),
          DropdownMenuItem(
            value: 'Western Cape',
            child: Text('Western Cape'),
          ),
        ],
        onChanged: (value) {},
      ),
    ],
  ),
),
                ],
              ),
              const SizedBox(height: 22),
              const SizedBox(
                  width: 210,
                  child: _Field(label: 'Postal Code', hint: '2001')),
            ],
          ),
        ),
        const SizedBox(height: 44),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _SignatureArea(),
        ),
      ],
    );
  }
}

class _SignatureArea extends StatelessWidget {
  const _SignatureArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('Digital Signature', muted: true),
        const SizedBox(height: 12),
        Row(
          children: [
            const SettingsButton('Draw your signature',
                icon: Icons.draw_outlined, width: 190, filled: false),
            const SizedBox(width: 42),
            SettingsButton(
              'Upload Signature',
              onTap: () async {
                await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        const SettingsSectionTitle('Digital Preview', muted: true),
        const SizedBox(height: 16),
        const SizedBox(
          width: 110,
          height: 86,
          child: CustomPaint(painter: _SignaturePainter()),
        ),
        const SizedBox(height: 18),
        const SettingsSectionTitle('Verification Status', muted: true),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6F72),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Not Verified',
            style: TextStyle(fontSize: 11, color: Color(0xFFCC1111)),
          ),
        ),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerRight,
          child: SettingsButton('Save Changes',
              width: 150, filled: false, height: 30),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    this.hint,
    this.icon,
    this.trailing,
    this.inputFormatters,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? trailing;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        SettingsInput(hint: hint, icon: icon, trailing: trailing, inputFormatters: inputFormatters),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF12C7C8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final corner = Paint()
      ..color = const Color(0xFF12C7C8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(4, 4), const Offset(26, 4), corner);
    canvas.drawLine(const Offset(4, 4), const Offset(4, 26), corner);
    canvas.drawLine(
        Offset(size.width - 4, 4), Offset(size.width - 26, 4), corner);
    canvas.drawLine(
        Offset(size.width - 4, 4), Offset(size.width - 4, 26), corner);
    canvas.drawLine(
        Offset(4, size.height - 4), Offset(26, size.height - 4), corner);
    canvas.drawLine(
        Offset(4, size.height - 4), Offset(4, size.height - 26), corner);
    canvas.drawLine(Offset(size.width - 4, size.height - 4),
        Offset(size.width - 26, size.height - 4), corner);
    canvas.drawLine(Offset(size.width - 4, size.height - 4),
        Offset(size.width - 4, size.height - 26), corner);

    final path = Path()
      ..moveTo(28, 60)
      ..cubicTo(40, 20, 40, 20, 46, 62)
      ..cubicTo(54, 45, 55, 45, 58, 65)
      ..cubicTo(66, 48, 70, 48, 78, 59)
      ..cubicTo(86, 68, 94, 54, 100, 57);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
