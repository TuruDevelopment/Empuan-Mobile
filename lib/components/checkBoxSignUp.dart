import 'package:flutter/material.dart';
import 'package:tumpuan/styles/style.dart';

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    super.key,
    required this.label,
    required this.padding,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final EdgeInsets padding;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Padding(
        padding: padding,
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.bg1, borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Text(
                  label,
                  style: const TextStyle(fontFamily: 'Satoshi'),
                )),
                Checkbox(
                  activeColor: const Color.fromRGBO(251, 111, 146, 1),
                  value: value,
                  shape: const CircleBorder(),
                  onChanged: (bool? newValue) {
                    onChanged(newValue!);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LabeledCheckboxExample extends StatefulWidget {
  String sentences;
  LabeledCheckboxExample({super.key, required this.sentences});

  @override
  State<LabeledCheckboxExample> createState() =>
      _LabeledCheckboxExampleState(sentences);
}

class _LabeledCheckboxExampleState extends State<LabeledCheckboxExample> {
  bool _isSelected = false;
  String sentenceLagi;
  _LabeledCheckboxExampleState(this.sentenceLagi);

  // _LabeledCheckboxExampleState(String sentences);

  // get sentence => sentences;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LabeledCheckbox(
        label: sentenceLagi,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        value: _isSelected,
        onChanged: (bool newValue) {
          setState(() {
            _isSelected = newValue;
          });
        },
      ),
    );
  }
}
