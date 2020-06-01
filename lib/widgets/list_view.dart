import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frappe_app/config/palette.dart';
import 'package:frappe_app/main.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../utils/helpers.dart';
import '../utils/http.dart';
import '../utils/response_models.dart';

import '../constants.dart';

Future<DioGetReportViewResponse> fetchList(
    {@required List fieldnames,
    @required String doctype,
    List filters,
    int page = 1}) async {
  int pageLength = 20;

  var queryParams = {
    'doctype': doctype,
    'fields': jsonEncode(fieldnames),
    'page_length': pageLength,
    'with_comment_count': true
  };

  queryParams['limit_start'] = (page * pageLength - pageLength).toString();

  if (filters != null && filters.length != 0) {
    queryParams['filters'] = jsonEncode(filters);
  }

  final response2 = await dio.get('/method/frappe.desk.reportview.get',
      queryParameters: queryParams);
  if (response2.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return DioGetReportViewResponse.fromJson(response2.data);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class CustomListView extends StatefulWidget {
  final String doctype;
  final List fieldnames;
  final List filters;
  final Function filterCallback;
  final Function detailCallback;
  final String appBarTitle;
  final wireframe;

  CustomListView(
      {@required this.doctype,
      this.wireframe,
      @required this.fieldnames,
      this.filters,
      this.filterCallback,
      @required this.appBarTitle,
      this.detailCallback});

  @override
  _CustomListViewState createState() => _CustomListViewState();
}

class _CustomListViewState extends State<CustomListView> {
  Future<DioGetReportViewResponse> futureList;

  @override
  void initState() {
    super.initState();
    futureList = fetchList(
        filters: widget.filters,
        doctype: widget.doctype,
        fieldnames: widget.fieldnames);
  }

  void choiceAction(String choice) {
    if (choice == Constants.Logout) {
      logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          widget.filterCallback(widget.filters);
        },
        child: Icon(
          Icons.filter_list,
          size: 50,
        ),
      ),
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: choiceAction,
            itemBuilder: (BuildContext context) {
              return Constants.choices.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: FutureBuilder<DioGetReportViewResponse>(
          future: futureList,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(children: [
                Container(
                  height: 60,
                  color: Color.fromRGBO(237, 242, 247, 1),
                  padding: EdgeInsets.only(left: 16, right: 6),
                  child: Row(
                    children: <Widget>[
                      widget.filters.length > 0
                          ? Text('Filters Applied')
                          : Text('No Filters'),
                      // Text(widget.filters.toString()),
                      widget.filters.length > 0
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  widget.filters.clear();
                                  localStorage.setString('IssueFilter', null);
                                  futureList = fetchList(
                                    filters: widget.filters,
                                    fieldnames: widget.fieldnames,
                                    doctype: widget.doctype,
                                  );
                                });
                              },
                            )
                          : Container(),
                      // Spacer(),
                      // Text('20 of 99')
                    ],
                  ),
                ),
                Expanded(
                  child: ListBuilder(
                    list: snapshot.data,
                    filters: widget.filters,
                    fieldnames: widget.fieldnames,
                    doctype: widget.doctype,
                    detailCallback: widget.detailCallback,
                    wireframe: widget.wireframe,
                  ),
                ),
              ]);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            // By default, show a loading spinner.
            return Center(child: CircularProgressIndicator());
          }),
    );
  }
}

class ListBuilder extends StatefulWidget {
  final list;
  final List filters;
  final List fieldnames;
  final String doctype;
  final Function detailCallback;
  final wireframe;

  ListBuilder(
      {this.list,
      this.filters,
      this.fieldnames,
      this.doctype,
      this.detailCallback,
      this.wireframe});

  @override
  _ListBuilderState createState() => _ListBuilderState();
}

class _ListBuilderState extends State<ListBuilder> {
  ScrollController _scrollController = ScrollController();

  int page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        page = page + 1;
        fetchList(
                filters: widget.filters,
                page: page,
                fieldnames: widget.fieldnames,
                doctype: widget.doctype)
            .then((onValue) {
          widget.list.values.values.addAll(onValue.values.values);
          setState(() {});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int subjectFieldIndex =
        widget.list.values.keys.indexOf(widget.wireframe["subject_field"]);

    return Column(children: [
      Expanded(
        child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.list.values.values.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Card(
                      child: ListTile(
                        title: Text(
                          '${widget.list.values.values[index][subjectFieldIndex]}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        subtitle: Container(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      widget.list.values.values[index][1],
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                child: Text(
                                  "${timeago.format(DateTime.parse(
                                        widget.list.values.values[index][5],
                                      ), locale: 'en_short')}",
                                  textAlign: TextAlign.end,
                                ),
                              ),
                              Spacer(),
                              Container(
                                height: 20,
                                width: 20,
                                decoration: new BoxDecoration(
                                  // color: Colors.grey[400],
                                  border: Border.all(),
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(5),
                                    right: Radius.circular(5),
                                  ),
                                ),
                                child: Text(
                                  '${widget.list.values.values[index][6]}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    // color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          widget.detailCallback(
                              widget.list.values.values[index][0],
                              widget.list.values.values[index]
                                  [subjectFieldIndex]);
                        },
                      ),
                    ),
                    Divider(
                      height: 10.0,
                      thickness: 2,
                    ),
                  ],
                ),
              );
            }),
      ),
    ]);
  }
}