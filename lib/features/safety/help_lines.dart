import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';
import 'sos_controller.dart';

class HelpLine {
  const HelpLine(this.number, this.name, this.description, {this.urgent = false});

  final String number;
  final String name;
  final String description;

  /// Shown in red: the one to call when in danger right now.
  final bool urgent;
}

/// National numbers, built into the app so they show without a connection.
/// Calls go over the phone network, not the internet.
const helpLines = [
  HelpLine('112', '112', 'Emergency: police, fire, ambulance', urgent: true),
  HelpLine('110', '110', 'Police'),
  HelpLine('119', '119', 'Ambulance and medical emergencies'),
  HelpLine('129', 'SAPA 129', 'Violence against women and children'),
];

/// The help lines as a group of rows; tapping one opens the dialer.
class HelpLinesGroup extends StatelessWidget {
  const HelpLinesGroup({super.key, this.lines = helpLines});

  final List<HelpLine> lines;

  Future<void> _call(BuildContext context, HelpLine line) async {
    if (!await SosController.dial(line.number) && context.mounted) {
      showEmToast(context, 'Couldn’t open your phone app. Dial ${line.number} directly.', icon: Icons.phone_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmGroup(
      children: [
        for (final line in lines)
          Semantics(
            button: true,
            label: 'Call ${line.name}, ${line.description}',
            excludeSemantics: true,
            child: EmRow(
              leading: EmIconTile(Icons.call_rounded, tone: line.urgent ? EmTileTone.danger : EmTileTone.normal),
              title: line.name,
              subtitle: line.description,
              trailing: EmTag('Call', tone: line.urgent ? EmTileTone.danger : EmTileTone.normal),
              onTap: () => _call(context, line),
            ),
          ),
      ],
    );
  }
}
