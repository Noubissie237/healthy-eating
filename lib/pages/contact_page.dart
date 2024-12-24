import 'package:flutter/material.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/models/users.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ContactPageState();
  }
}

class _ContactPageState extends State<ContactPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Future<List<Users>> _students;

  @override
  void initState() {
    super.initState();
    _students = _databaseHelper.getStudent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select contact",
            style:
                TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04)),
        elevation: 8,
      ),
      body: FutureBuilder(
          future: _students,
          builder: (context, snapshop) {
            if (snapshop.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshop.hasError) {
              return Center(
                child: Text('Error : ${snapshop.error}'),
              );
            } else if (!snapshop.hasData || snapshop.data!.isEmpty) {
              return const Center(child: Text('No user found !'));
            }
            final users = snapshop.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.nom),
                  subtitle: Text(user.telephone),
                );
              },
            );
          }),
    );
  }
}
