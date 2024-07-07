import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = FlipCardController();

  List<Muscle> frontMuscles = [];
  List<Muscle> backMuscles = [];

  Color getColor(String tag, List<Muscle> muscles) {
    if (tag == 'body') {
      return Color.fromRGBO(224, 224, 224, 1);
    }
    for (var muscle in muscles) {
      if (muscle.tag == tag) {
        return muscle.isSelected
            ? Color.fromRGBO(0, 102, 249, 1)
            : Colors.transparent;
      }
    }
    return Colors.transparent;
  }

  @override
  initState() {
    super.initState();
    loadSvgImage(svgImage: 'assets/body_front.svg').then((value) {
      setState(() {
        frontMuscles = value;
      });
    });
    loadSvgImage(svgImage: 'assets/body_back.svg').then((value) {
      setState(() {
        backMuscles = value;
      });
    });
  }

  Widget _getClippedImage({
    required Clipper clipper,
    required Color color,
    required Muscle muscle,
    final Function(Muscle country)? onMuscleSelected,
  }) {
    return ClipPath(
      clipper: clipper,
      key: ValueKey(muscle.id),
      child: GestureDetector(
        onTap: () => onMuscleSelected?.call(muscle),
        child: Container(
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.state?.flipCard();
        },
        child: Icon(Icons.flip),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => FlipCard(
                  rotateSide: RotateSide.left,
                  onTapFlipping: false,

                  //When enabled, the card will flip automatically when touched.
                  axis: FlipAxis.vertical,
                  disableSplashEffect: false,
                  controller: controller,
                  frontWidget: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var muscle in frontMuscles)
                        _getClippedImage(
                          clipper: Clipper(
                            svgPath: muscle.path,
                            offsetX: constraints.maxWidth / 2,
                            offsetY: constraints.maxHeight / 3,
                          ),
                          color: getColor(muscle.tag, frontMuscles),
                          muscle: muscle,
                          onMuscleSelected: (muscle) {
                            if (muscle.tag == 'body') {
                              return;
                            }
                            setState(() {
                              for (var element in frontMuscles) {
                                if (element.tag == muscle.tag) {
                                  element.isSelected = !element.isSelected;
                                }
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  backWidget: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var muscle in backMuscles)
                        _getClippedImage(
                          clipper: Clipper(
                            svgPath: muscle.path,
                            offsetX: constraints.maxWidth / 2,
                            offsetY: constraints.maxHeight / 3,
                          ),
                          color: getColor(muscle.tag, backMuscles),
                          muscle: muscle,
                          onMuscleSelected: (muscle) {
                            if (muscle.tag == 'body') {
                              return;
                            }
                            setState(() {
                              for (var element in backMuscles) {
                                if (element.tag == muscle.tag) {
                                  element.isSelected = !element.isSelected;
                                }
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              "Selected front muscles : [${frontMuscles.where((element) => element.isSelected).map(
                    (e) => e.tag,
                  ).toSet().join(", ")}]",
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "Selected back muscles : [${backMuscles.where((element) => element.isSelected).map(
                    (e) => e.tag,
                  ).toSet().join(", ")}]",
            ),
            SizedBox(
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
}

class Clipper extends CustomClipper<Path> {
  Clipper({
    required this.svgPath,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  String svgPath;
  final double offsetX;
  final double offsetY;

  @override
  Path getClip(Size size) {
    var path = parseSvgPathData(svgPath);
    final Matrix4 matrix4 = Matrix4.identity();
    return path.transform(matrix4.storage).shift(Offset(offsetX / 2, offsetY / 2));
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return false;
  }
}

class Muscle {
  final String id;
  final String path;
  final String tag;
  bool isSelected = false;

  Muscle({required this.id, required this.path, required this.tag});
}

Future<List<Muscle>> loadSvgImage({required String svgImage}) async {
  List<Muscle> muscles = [];
  String generalString = await rootBundle.loadString(svgImage);

  XmlDocument document = XmlDocument.parse(generalString);

  final paths = document.findAllElements('path');

  for (var element in paths) {
    String partId = element.getAttribute('id').toString();
    String partPath = element.getAttribute('d').toString();
    String tag = element.getAttribute('class').toString();
    muscles.add(Muscle(id: partId, path: partPath, tag: tag));
  }

  return muscles;
}
