import 'package:shared_preferences/shared_preferences.dart';

writeNewMessage(String val) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> currentList = prefs.getStringList("dropDownOpt");
  if (currentList == null) {
    currentList = [];
    currentList.add("Custom Message");
  }
  currentList.add(val);
  prefs.setStringList("dropDownOpt", currentList);
  return;
}

removeMsg(List<String> data, int index) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  data.removeAt(index);
  prefs.setStringList("dropDownOpt", data);
  return;
}
