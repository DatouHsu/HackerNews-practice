import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'webview.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List widgets = [];
  Map post = Map();
  Map loadingState = Map();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: ListView.builder(
            itemCount: widgets.length,
            itemBuilder: (BuildContext context, int position) {
              return getRow(context, position);
            }));
  }

  Widget getRow(BuildContext context, int i) {
    var postId = widgets[i];
    var postData = post[postId];
    String title = postData == null ? "Loading" : postData["title"];
    int score = postData == null ? 0 : postData["score"];
    if (postData == null) {
      loadPost(postId);
    }
    var tapPosition;
    return GestureDetector(
        onTapDown: (TapDownDetails details) {
          tapPosition = details.globalPosition;
        },
        onLongPress: () {
          showMenu(
              context: context,
              position: RelativeRect.fromRect(
                  tapPosition & Size(40, 40),
                  Offset.zero &
                  (Overlay.of(context).context.findRenderObject()
                  as RenderBox)
                      .size),
              items: <PopupMenuEntry>[
                PopupMenuItem(
                  value: "open",
                  child: Row(
                    children: <Widget>[
                      Text("Open in browser"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "share",
                  child: Row(
                    children: <Widget>[
                      Text("Share"),
                    ],
                  ),
                )
              ]).then<void>((value) {
            if (value == null) return;
            onPopupMenuSelect(value, postData);
          });
        },
        child: ListTile(
          title: Text("$title",
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold)),
          subtitle: Text("Score: $score"),
          onTap: () => onTapped(postData),
        ));
  }

  onPopupMenuSelect(value, post) {
    if (value == "open")
      _launchURL(post["url"]);
  }

  _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  onTapped(post) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => WebViewScreen(post["title"], post["url"])));
  }

  loadData() async {
    String dataURL =
        "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty";
    http.Response response = await http.get(dataURL);
    setState(() {
      widgets = json.decode(response.body).take(25).toList();
    });
  }

  loadPost(int item) async {
    if (loadingState[item] == true) {
      return;
    }
    loadingState[item] = true;
    String dataURL =
        "https://hacker-news.firebaseio.com/v0/item/$item.json?print=pretty";
    http.Response response = await http.get(dataURL);
    setState(() {
      post[item] = json.decode(response.body);
    });
    loadingState[item] = false;
  }
}