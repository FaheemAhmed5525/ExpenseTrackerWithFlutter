import 'package:expences_tracker_with_flutter/datebase_controller.dart';
import 'package:expences_tracker_with_flutter/financial_entries_list.dart';
import 'package:expences_tracker_with_flutter/financial_entry.dart';
import 'package:uuid/uuid.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

class UsersListManager {
  UsersListManager();

  DatabaseController? databaseController;
  
  Future<bool> initDatabase() async {
    databaseController = DatabaseController.controller;
    if (databaseController == null ) return false;
    loadUsers();
    return true;
  }

  Future<void> loadUsers() async{
    _userList.addAll(
      await databaseController!.getUserList()
    ); 
      // bool tableCheck = await databaseController!.isTableExist("FinancialEntries");
      // if (tableCheck) {print("table exits");}
      // else {print("table don't exits");}
    _userList.remove(_userList.first);
    if(_userList.isEmpty) {
      _userList.add(
        User(name: "Mohib"),
      );
      databaseController!.addUser(_userList.first);
    }
    _userList.first.loadFinancialEntries(databaseController!);
    selectedUser = _userList.first;

    ///adding customized categories:
    User.incomeCategories.addAll(
      await databaseController!.getCagetoriesWithType(EntryType.income)
    );
    User.expenceCategories.addAll(
      await databaseController!.getCagetoriesWithType(EntryType.expense)
    );
  }


  static final List<User> _userList = [
    User(name: "Mohib"),
  ];
  static User selectedUser = _userList.first;

  Future<void> addUser(User user) async {
    _userList.add(user);
    await databaseController?.addUser(user);
    //print("User added: ${user.Name}");
  }

  void switchUser(String id) {
    for (User user in _userList) {
      if (user.id == id) {
        print("Switched to user with id $id");
        selectedUser = user;
        //if(user.financialEntries.financialEntries.isEmpty) {
          user.loadFinancialEntries(databaseController!);
        //}
        return;
      }
    }
  }

  int get length => _userList.length;

  User getUserWithId(String id) {
    for (User user in _userList) {
      if (user.id == id) {
        return user;
      }
    }

    return User(name: "NewUser");
  }

  Future<void> deleteUserWithId(String id) async {
    await databaseController?.deleteUser(id);
    print("User with id $id deleted");
    if (_userList.length > 1) {
      for (User user in _userList) {
        if (user.id == id) {
          if (user.id == selectedUser.id) {
            if (selectedUser.id == _userList.first.id) {
              selectedUser = _userList.last;
            } else {
              selectedUser = _userList.first;
            }
          }
          _userList.remove(user);
          //removing next line may cause runtime errors
          return;
        }
      }
    }
  }


  //custom mam fuction
  List<R> map<R>(R Function(User) transform) {
    List<R> resultList = [];
    for (User user in _userList) {
      resultList.add(transform(user));
    }
    return resultList;
  }

  Future<void> changeUserNameforId(String id, String newName) async {
    for (User user in _userList) {
      if (user.id == id) {
        user.changeName(newName);
        break;
      }
    }
    databaseController?.updateUser(User.loadUser(name: newName, id: id));
    print("user updated with name $newName");
  }

  void addFinancialEntry(FinancialEntry entry) {
    for (User user in _userList) {
      if (user.id == selectedUser.id) {
        user.addFinancialEntry(entry, databaseController!);
        return;
      }
    }
  }

  void addCategory(EntryType categoryFor, String categoryName) {
    User.addCategory(categoryFor, categoryName, databaseController!);
  }
}



class User {
  User({
    required this.name,
  }) : id = idObject.v4().toString();

  User.loadUser({
    required this.name,
    required this.id,
  });

  FinancialEntriesList financialEntries = FinancialEntriesList(financialEntries: [
    FinancialEntry(
      title: "Clothes",
      amount: 250,
      type: EntryType.expense,
      category: "Shopping",
      date: DateTime(2024, 5, 6, 0, 0, 0, 0, 0),
      details: "This is an expense for shopping some clothes",
      userId: '',
    ),
    FinancialEntry(
      title: "Fuel",
      amount: 400,
      type: EntryType.expense,
      category: "Travel",
      date: DateTime(2024, 4, 5, 0, 0, 0, 0, 0),
      details: "This is an expense for fuel consumed on travel to city.",
      userId: '',
    ),
    FinancialEntry(
      title: "Earning",
      amount: 2000,
      type: EntryType.income,
      category: "Business",
      date: DateTime(2024, 2, 5, 0, 0, 0, 0, 0),
      details: "This is an income generated from business.",
      userId: '',
    ),
  ]);

  static List<String> incomeCategories = [
    'Salary',
    'Business',
    'Scholarship',
    'Freelancing',
  ];

  static List<String> expenceCategories = [
    'Food',
    'Travel',
    'Shoping',
    'Sports',
    'Education',
    'Gifts',
    'Kids',
    'Entertainment',
    'Residential Rent',
    'Maintainance',
  ];

  Future<void> addFinancialEntry(
      FinancialEntry entry, DatabaseController database) async {
    entry.userId = id;
    financialEntries.add(entry);
    await database.addFinancialEntry(entry);
  }

  Future<void> loadFinancialEntries(DatabaseController database) async {
    financialEntries.removeAll();
    financialEntries.financialEntries =  await database.fetchFinancialEntries(id);
  }

  static void addCategory(EntryType categoryFor, String categoryName, DatabaseController database,) {
    if (categoryFor == EntryType.income) {
      incomeCategories.add(categoryName);
    } else if (categoryFor == EntryType.expense) {
      expenceCategories.add(categoryName);
    } else {
      //Do nothing
    }
    database.addCategory(categoryName, categoryFor);
  }

  void changeName(String newName) {
    name = newName;
  }

  //For database interection
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User.loadUser(
      name: map['name'],
      id: map['id'],
    );
  }

  String get Name => name;

  String name;
  String id;

  static Uuid idObject = const Uuid();
}
