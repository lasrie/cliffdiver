import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:cliffdiver/shared/ratingbar.dart';

class SpotDetail extends StatefulWidget {
  final DocumentSnapshot spot;
  final String spotID;

  SpotDetail({this.spot, this.spotID});

  @override
  _SpotDetailState createState() {
    return new _SpotDetailState(this.spotID);
  }
}

// this class seems to deep, but its mostly ui stuff(?) so maybe just some cleanup/extract functions here and there

class _SpotDetailState extends State<SpotDetail> {
  var spotData;
  String _spotID;
  List<DocumentSnapshot> commentDocs = List<DocumentSnapshot>.empty();
  List<_CommentModel> comments;
  bool commentsReceived = false;
  double _commentRating = 3;
  // ignore: unused_field
  bool _ratingSet = false;
  double _rating = 0;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    comments = [
      new _CommentModel(userComment: "No Comments yet!", userRating: null)
    ];
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference fireSpots = firestore.collection('Spots');
    if (_spotID.isNotEmpty) {
      fireSpots.doc(_spotID).collection("comments").get().then((docList) {
        if (docList.docs.isNotEmpty) {
          setState(() {
            commentsReceived = true;
            commentDocs = docList.docs;
          });
        } else {
          setState(() {
            commentsReceived = false;
          });
        }
      });
    }
  }

  void addComment(String val, double rating) {
    int ratingINT = rating.toInt();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference fireSpots = firestore.collection('Spots');
    Map<String, dynamic> data = {'userComment': val, 'userRating': ratingINT};
    fireSpots.doc(_spotID).collection("comments").doc().set(data);

    fireSpots.doc(_spotID).collection("comments").get().then((docList) {
      setState(() {
        commentDocs = docList.docs;
      });
    });
  }

  _SpotDetailState(String spotID) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference fireSpots = firestore.collection('Spots');
    _spotID = spotID;
    if (spotID.isNotEmpty) {
      fireSpots.doc(_spotID).collection("comments").get().then((docList) {
        setState(() {
          _rating = _calculateRatings(docList.docs);
        });

        if (docList.docs.isEmpty) {
          setState(() {
            commentsReceived = false;
          });
        }

        if (docList.docs.isNotEmpty) {
          setState(() {
            commentDocs = docList.docs;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: (MediaQuery.of(context).size.height / 2),
          floating: true,
          pinned: true,
          snap: false,
          actionsIconTheme: IconThemeData(opacity: 0.0),
          flexibleSpace: Stack(
            children: <Widget>[
              Positioned.fill(
                  child: Image.network(
                widget.spot['imageUrl'],
                fit: BoxFit.cover,
              )),
              Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black12, Colors.black54], // whitish to gray
                  tileMode: TileMode.repeated,
                )),
              ),
              FlexibleSpaceBar(
                  title: Text(
                widget.spot['title'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25.0,
                  fontWeight: FontWeight.w600,
                ),
              )),
            ],
          ),
        ),
        SliverList(
            //Description of Spot and Warning section
            delegate:
                SliverChildBuilderDelegate((BuildContext context, int index) {
          switch (index) {
            case 0:
              return _buildDescription();
              break;
            case 1:
              return _buildWarning();
              break;
            default:
              return null;
          }
        }, childCount: 2)),
        SliverList(
          //New Comment Input Field
          delegate:
              SliverChildBuilderDelegate((BuildContext context, int index) {
            return _buildNewCommentForm(index, context);
          }, childCount: 2),
        ),
        SliverList(
            //Existing Comments to be displayed
            delegate:
                SliverChildBuilderDelegate((BuildContext context, int index) {
          return _buildComment(index);
        }, childCount: commentDocs.length)),
      ],
    ));
  }

  Widget _buildDescription() {
    return Stack(
      children: [
        Container(
            margin: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5.0),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20.0)),
            child: Padding(
                padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: Text(
                              widget.spot['address'],
                              maxLines: 2,
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.0),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StarRating(
                              rating: _rating,
                              color: Colors.amber,
                              onRatingChanged: (rating) => print(rating),
                            ),
                          ]),
                      SizedBox(height: 10.0),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 90.0,
                              height: 30.0,
                              decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: Text(widget.spot['level']),
                              alignment: Alignment.center,
                            ),
                            SizedBox(width: 10.0),
                            Container(
                              width: 90.0,
                              height: 30.0,
                              decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: Text(_getCliffText(widget.spot['cliff'])),
                              alignment: Alignment.center,
                            )
                          ]),
                      SizedBox(height: 10.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: MediaQuery.of(context).size.width - 80.0,
                              child: Text(widget.spot['description']),
                              alignment: Alignment.topCenter)
                        ],
                      )
                    ])))
      ],
    );
  }

  Widget _buildWarning() {
    return Container(
        margin: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5.0),
        decoration: BoxDecoration(
            color: Colors.deepOrange[50],
            borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
            padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 1.5,
                      child: Text(
                        'Important notes',
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: Text('Only jump from as high as you dare.'),
                  )
                ]),
                SizedBox(height: 10.0),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: Text('Never jump from high cliffs on your own.'),
                  )
                ]),
                SizedBox(height: 10.0),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: Text(
                        '''We cannot guarantee that the app only shows spots with enough water depth, so please ALWAYS CHECK BEFORE JUMPING! Even at spots you already know the water level can vary.'''),
                  )
                ]),
                SizedBox(height: 10.0),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: Text(
                        '''Check the jump-off point and make sure that you cannot slip or fall uncontrolled.'''),
                  )
                ]),
                SizedBox(height: 10.0),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: Text(
                        '''Find out where to exit the water before jumping.'''),
                  )
                ]),
                SizedBox(height: 10.0),
              ],
            )));
  }

  Widget _buildComment(int commentindex) {
    if (commentsReceived) {
      if (commentindex < commentDocs.length) {
        return Container(
            child: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: Card(
                  child: ListTile(
                      leading: Icon(Icons.comment),
                      title: Text(commentDocs[commentindex]["userComment"]),
                      subtitle: StarRating(
                        color: Colors.amber,
                        rating: commentDocs[commentindex]["userRating"] ?? 0,
                        starCount: 5,
                      )),
                )));
      } else if (commentDocs.length == 0) {
        setState(() {
          _rating = 0;
        });
        return Container(
            child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Card(
              child: ListTile(
                  leading: Icon(Icons.comment),
                  title: Text("No Comments yet."))),
        ));
      }
      return null;
    } else {
      return Container(
          child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        child: Card(
            child: ListTile(
                leading: Icon(Icons.comment), title: Text("No Comments yet."))),
      ));
    }
  }

  Widget _buildNewCommentForm(int index, context) {
    switch (index) {
      case 0:
        return Container(
            margin: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5.0),
            width: MediaQuery.of(context).size.width / 1.5,
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                'Reviews',
                maxLines: 2,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
              ),
            ));
      case 1:
        return Container(
            height: 150.0,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Card(
                  child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10.0),
                    SmoothStarRating(
                        isReadOnly: false,
                        size: 30,
                        rating: _commentRating,
                        filledIconData: Icons.star,
                        halfFilledIconData: Icons.star_border,
                        defaultIconData: Icons.star_border,
                        starCount: 5,
                        allowHalfRating: false,
                        spacing: 2.0,
                        color: Colors.amber,
                        onRated: (value) {
                          setState(() {
                            _ratingSet = true;
                            _commentRating = value;
                          });
                        }),
                    SizedBox(height: 10.0),
                    ListTile(
                        leading: Icon(Icons.add_comment),
                        trailing: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              _formKey.currentState.save();
                              _formKey.currentState.reset();
                            }
                          },
                          child: Text("Submit"),
                        ),
                        title: TextFormField(
                          onSaved: (value) {
                            addComment(value, _commentRating);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Processing your entry...")));
                          },
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter some text';
                            } else if (_ratingSet = false) {
                              return 'Please enter a value using the rating stars';
                            } else {
                              return null;
                            }
                          },
                        )),
                    SizedBox(height: 20.0),
                  ],
                ),
              )),
            ));
        break;
      default:
        return null;
    }
  }
}

String _getCliffText(bool cliff) {
  if (cliff) {
    return "Cliff";
  } else {
    return "Platform";
  }
}

double _calculateRatings(List<DocumentSnapshot> comments) {
  double rating = 0;
  double ratingSum = 0;
  int ratingCount = 0;
  var ratingStr;

  for (int i = 0; i < comments.length; i++) {
    ratingStr = comments[i]["userRating"] != null
        ? comments[i]["userRating"]
        : comments[i]["rating"];
    ratingSum = ratingSum + ratingStr;
    ratingCount = ratingCount + 1;
  }
  if (ratingCount > 0) {
    rating = ratingSum / ratingCount;
  } else {
    rating = 0;
  }

  return rating;
}

class _CommentModel {
  final String userComment;
  final int userRating;

  const _CommentModel({this.userComment, this.userRating});
}
