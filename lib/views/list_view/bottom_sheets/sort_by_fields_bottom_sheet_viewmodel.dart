import 'package:webwire_app/model/doctype_response.dart';
import 'package:webwire_app/views/base_viewmodel.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SortByFieldsBottomSheetViewModel extends BaseViewModel {
  late DoctypeField selectedField;
  late String sortOrder = "desc";

  selectField(DoctypeField field) {
    if (selectedField.fieldname == field.fieldname) {
      toggleSort();
    } else {
      selectedField = field;
      notifyListeners();
    }
  }

  toggleSort() {
    sortOrder = sortOrder == "asc" ? "desc" : "asc";
    notifyListeners();
  }
}
