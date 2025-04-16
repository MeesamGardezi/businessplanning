import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

class NewProjectDialog extends StatefulWidget {
  @override
  _NewProjectDialogState createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  final ProjectService _projectService = ProjectService();

  void _createProject() async {
    if (_formKey.currentState!.validate()) {
      Project newProject = Project(
        documentId: '', // This will be updated after creation
        title: _title,
        description: _description,
        createdAt: DateTime.now(), // Set the createdAt field to the current time
      );

      // Call the project creation method
      Project? createdProject = await _projectService.createProject(newProject);
      if (createdProject != null) {
        // Optionally, show a success message or update the UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project created successfully!')),
        );
        Navigator.of(context).pop(); // Close the dialog
      } else {
        // Handle the error (e.g., show a snackbar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create project')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Project Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _title = value;
                });
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Project Description'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createProject,
          child: Text('Create'),
        ),
      ],
    );
  }
}