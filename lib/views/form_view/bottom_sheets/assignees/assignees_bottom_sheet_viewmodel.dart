import 'package:webwire_app/app/locator.dart';
import 'package:webwire_app/services/api/api.dart';
import 'package:webwire_app/views/base_viewmodel.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AssigneesBottomSheetViewModel extends BaseViewModel {
  List<String> selectedUsers = [];
  List<String> assignedUsers = [];

  onUserSelected(String user) {
    selectedUsers.add(user);
    notifyListeners();
  }

  addAssignees({
    required String doctype,
    required String name,
  }) async {
    await locator<Api>().addAssignees(
      doctype,
      name,
      selectedUsers,
    );
  }

  removeUser(int index) {
    selectedUsers.removeAt(index);
    notifyListeners();
  }

  removeAssignedUser({
    required String doctype,
    required String name,
    required String user,
  }) async {
    try {
      await locator<Api>().removeAssignee(doctype, name, user);
      assignedUsers.remove(user);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}
