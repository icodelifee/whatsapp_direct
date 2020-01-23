import 'package:easy_contact_picker/easy_contact_picker.dart';
import 'package:flutter/material.dart';
import 'package:groovin_widgets/outline_dropdown_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:search_page/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intent/intent.dart' as intent;
import 'package:intent/action.dart' as act;
import 'package:intent/extra.dart' as ext;
import 'package:whatsappdirect/sharedprefs.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whatsapp Direct',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF128C7E)),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int dropDown;
  TextEditingController name;
  TextEditingController phoneNo;
  TextEditingController custmMsg;
  TextEditingController newMsg;
  final String baseURL = "https://api.whatsapp.com/send?phone=91";
  @override
  void initState() {
    name = TextEditingController();
    phoneNo = TextEditingController();
    custmMsg = TextEditingController();
    newMsg = TextEditingController();
    super.initState();
  }

  final _tcBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(
        const Radius.circular(10.0),
      ),
      borderSide: BorderSide(color: Colors.transparent));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECE5DD),
      appBar: new AppBar(
        title: Text("Whatsapp Direct"),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                nameField(),
                phoneNoField(),
                dropDownMenu(),
                customMsgField(),
                submitButton()
              ],
            ),
          ),
        ),
      ),
    );
  }

  FlatButton submitButton() {
    return FlatButton(
      onPressed: () {
        if (name.text.isNotEmpty) {
          String editedMsg = custmMsg.text.replaceAll("<name>", name.text);
          intent.Intent()
            ..setAction(act.Action.ACTION_VIEW)
            ..setData(Uri.parse("$baseURL${phoneNo.text}&text=$editedMsg"))
            ..putExtra(ext.Extra.EXTRA_PACKAGE_NAME, "com.whatsapp.w4b")
            ..startActivity().catchError((e) => print(e));
        } else
          intent.Intent()
            ..setAction(act.Action.ACTION_VIEW)
            ..setData(
                Uri.parse("$baseURL${phoneNo.text}?text=${custmMsg.text}"))
            ..putExtra(ext.Extra.EXTRA_PACKAGE_NAME, "com.whatsapp.w4b")
            ..startActivity().catchError((e) => print(e));
      },
      color: Theme.of(context).primaryColor,
      child: SizedBox(
          width: 350,
          height: 40,
          child: Center(
              child: Text(
            "SEND",
            style: TextStyle(color: Colors.white),
          ))),
    );
  }

  Padding customMsgField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: custmMsg,
        textCapitalization: TextCapitalization.sentences,
        minLines: 1,
        maxLines: 40,
        decoration:
            InputDecoration(labelText: "Custom Message", border: _tcBorder),
      ),
    );
  }

  dropDownMenu() {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return LinearProgressIndicator();
            break;
          default:
            List<String> dropList = snapshot.data.getStringList("dropDownOpt");
            if (dropList != null)
              return dropDownField(dropList, context);
            else
              return dropDownField(['Custom Message'], context);
        }
      },
    );
  }

  Padding dropDownField(List<String> dropList, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: OutlineDropdownButton(
        value: dropDown,
        onChanged: (val) {
          setState(() {
            dropDown = val;
            if (val != 0)
              custmMsg.text = dropList[val].replaceAll("<name>", name.text);
          });
        },
        items: dropList.asMap().entries.map((entry) {
          return DropdownMenuItem(
            child: ListTile(
              title: Text(entry.value),
              subtitle: Divider(color: Colors.black),
              trailing: InkWell(
                child: entry.key != 0 ? Icon(Icons.delete) : SizedBox(),
                onTap: () {
                  removeMsg(dropList, entry.key);
                  setState(() {
                    dropDown = 0;
                    custmMsg.text = "";
                  });
                },
              ),
            ),
            value: entry.key,
          );
        }).toList(),
        hint: Text("Select message"),
        inputDecoration: InputDecoration(
            suffixIcon: InkWell(
                onTap: () async {
                  await addNewMessageDialog(context);
                  setState(() {});
                },
                child: Icon(Icons.add)),
            contentPadding: EdgeInsets.all(15),
            border: _tcBorder),
      ),
    );
  }

  addNewMessageDialog(BuildContext context) async {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return SimpleDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Text("Add New Message"),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new TextField(
                  controller: newMsg,
                  decoration: InputDecoration(border: _tcBorder),
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 40,
                ),
              ),
              FlatButton(
                onPressed: () async {
                  await writeNewMessage(newMsg.text);
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("CANCEL"),
              )
            ],
          );
        });
  }

  Padding phoneNoField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: phoneNo,
        decoration: InputDecoration(
            suffixIcon: InkWell(
                child: Icon(Icons.person_add,
                    color: Theme.of(context).primaryColor),
                onTap: () async {
                  Map<PermissionGroup, PermissionStatus> permissions =
                      await PermissionHandler()
                          .requestPermissions([PermissionGroup.contacts]);
                  PermissionStatus permission = await PermissionHandler()
                      .checkPermissionStatus(PermissionGroup.contacts);
                  if (permission == PermissionStatus.granted) {
                    List<Contact> contacts =
                        await EasyContactPicker().selectContacts();
                    showSearchPage(contacts);
                  }
                }),
            prefix:
                Padding(padding: EdgeInsets.only(right: 5), child: Text("+91")),
            labelText: "Phone Number",
            contentPadding: EdgeInsets.all(15),
            border: _tcBorder),
      ),
    );
  }

  Future<Contact> showSearchPage(List<Contact> contacts) {
    return showSearch(
      context: context,
      delegate: SearchPage<Contact>(
        items: contacts,
        searchLabel: 'Searceh Contacts',
        suggestion: Center(
          child: Text('Filter people by name'),
        ),
        failure: Center(
          child: Text('No person found :('),
        ),
        filter: (contact) => [contact.fullName, contact.phoneNumber],
        builder: (contact) => ListTile(
          title: Text(contact.fullName),
          subtitle: Text(contact.phoneNumber),
          onTap: () {
            phoneNo.text = contact.phoneNumber.replaceAll("+91 ", "");
            phoneNo.text = phoneNo.text.replaceAll(" ", "");
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Padding nameField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        controller: name,
        decoration: InputDecoration(labelText: "Name", border: _tcBorder),
      ),
    );
  }
}

