import 'package:flutter/material.dart';

class SaveOverlay extends StatelessWidget {
  /// Callback function triggered when the save is confirmed
  final VoidCallback onSave;

  /// Callback function triggered when the save is cancelled
  final VoidCallback onCancel;

  const SaveOverlay({super.key, required this.onSave, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.1,
      left: MediaQuery.of(context).size.width * 0.1,
      right: MediaQuery.of(context).size.width * 0.1,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Save Changes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Do you want to save the current changes?',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Save'),
                  ),
                  SizedBox(width: 16),
                  TextButton(onPressed: onCancel, child: Text('Cancel')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
