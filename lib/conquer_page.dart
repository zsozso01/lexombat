import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lexombat/globals.dart';

// ignore: must_be_immutable
class MapGridPage extends StatefulWidget {
  MapGridPage({super.key, required this.currentEmpire});
  Empire currentEmpire;

  @override
  MapGridPageState createState() => MapGridPageState();
}

class Tile {
  String? conqueredBy;
  Map<String, int> resourcesInvested;
  bool isCapital;

  Tile({required this.conqueredBy, this.resourcesInvested = const {"Wood": 0, "Stone": 0, "Gold": 0, "Iron": 0}, this.isCapital = false});

  double soldiersRequiredToConquer() {
    double requiredSoldiers = 0;

    maxStorableResources.forEach((resource, maxAmount) {
      if (resourcesInvested.containsKey(resource)) {
        requiredSoldiers += resourcesInvested[resource]! / (maxAmount);
      }
    });

    return requiredSoldiers;
  }

  Map<String, dynamic> toJson() {
    return {
      'isCapital': isCapital,
      'conqueredBy': conqueredBy,
      'resourcesInvested': resourcesInvested,
    };
  }

  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      isCapital: json['isCapital'] ?? false,
      conqueredBy: json['conqueredBy'],
      resourcesInvested: Map<String, int>.from(json['resourcesInvested']),
    );
  }
}

class MapGridPageState extends State<MapGridPage> {
  List<List<Tile>> tiles = List.generate(5, (index) => List.generate(5, (index) => Tile(conqueredBy: null)));
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  bool hasBeenBuilt = false;
  int? capitalRow;
  int? capitalColumn;
  @override
  void initState() {
    super.initState();
    loadMapData();
  }

  void createInitialSetup() async {
    setState(() {
      tiles[2][2].conqueredBy = userProfile!.username;
      tiles[2][2].isCapital = true;
      capitalColumn = 2;
      capitalRow = 2;
    });
    _scrollToConqueredTile(capitalColumn!, capitalRow!);
    saveMapData(tiles);
  }

  Future<void> saveMapData(List<List<Tile>> tiles) async {
    final CollectionReference mapCollection = FirebaseFirestore.instance.collection('maps');

    // Flatten the tiles into a linear list
    List<Map<String, dynamic>> flattenedTiles = tiles.expand((row) => row).map((tile) => tile.toJson()).toList();

    await mapCollection.doc(widget.currentEmpire.id).set({'tiles': flattenedTiles});
  }

  // ignore: prefer_typing_uninitialized_variables
  var loadingListener;

  @override
  void dispose() {
    super.dispose();
    if (loadingListener != null) loadingListener.cancel();
  }

  bool initialLoad = false;
  Future<void> loadMapData() async {
    var query = FirebaseFirestore.instance.collection('maps').doc(widget.currentEmpire.id);

    if ((await query.get()).exists) {
      loadingListener = query.snapshots().listen((event) async {
        // Convert Firestore data back to tiles
        List<Map<String, dynamic>> flattenedTiles = (event.data()?['tiles'] as List<dynamic>).cast<Map<String, dynamic>>();

        // Convert the flattened list back into a square
        tiles = List.generate(
            sqrt(flattenedTiles.length).toInt(),
            (c) => List.generate(
                sqrt(flattenedTiles.length).toInt(), (r) => Tile.fromJson(flattenedTiles[(c * sqrt(flattenedTiles.length) + r).toInt()])));

        for (int c = 0; c < tiles.length; c++) {
          for (int r = 0; r < tiles[c].length; r++) {
            if (tiles[c][r].conqueredBy == userProfile!.username && tiles[c][r].isCapital) {
              capitalColumn = c;
              capitalRow = r;
            }
          }
        }
        if (mounted) {
          setState(() {});
        }
        if (capitalColumn != null) {
          if (mounted) {
            if (!initialLoad) {
              _scrollToConqueredTile(capitalRow!, capitalColumn!);
              initialLoad = true;
            }
          }
        } else {
          if (tiles.expand((element) => element).where((element) => element.isCapital && element.conqueredBy == null).isEmpty) {
            expandMap();
          }
          bool hasFoundCapital = false;
          for (int c = 0; c < tiles.length; c++) {
            for (int r = 0; r < tiles.length; r++) {
              if (!hasFoundCapital && tiles[c][r].isCapital && tiles[c][r].conqueredBy == null) {
                tiles[c][r].conqueredBy = userProfile!.username;
                capitalColumn = c;
                capitalRow = r;
                hasFoundCapital = true;
                saveMapData(tiles);
              }
            }
          }
        }
      });
    } else {
      createInitialSetup();
    }
  }

  void expandMap() {
    tiles = expandGrid(tiles, tiles.length + 5, 5);
    if (mounted) {
      setState(() {});
    }
  }

  List<List<Tile>> expandGrid(List<List<Tile>> currentTiles, int newSize, int scarcity) {
    // Ensure the new size is greater than the current size
    assert(newSize >= currentTiles.length && newSize >= currentTiles[0].length);

    // Create a new grid with the expanded size
    List<List<Tile>> newTiles = List.generate(newSize, (row) {
      return List.generate(newSize, (column) {
        if (row < currentTiles.length && column < currentTiles[0].length) {
          // Copy existing tiles to the corresponding positions
          return currentTiles[row][column];
        } else {
          // Fill the new positions with default tiles (conqueredBy: null)
          return Tile(conqueredBy: null, isCapital: row % scarcity == scarcity ~/ 2 && column % scarcity == scarcity ~/ 2);
        }
      });
    });

    return newTiles;
  }

  void _scrollToConqueredTile(int row, int column) async {
    while (!hasBeenBuilt) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    // ignore: use_build_context_synchronously
    double itemSize = MediaQuery.of(context).size.width / 3; // Adjust based on your grid

    double scrollX = itemSize * (column - 1);
    double scrollY = itemSize * (row - 1);

    _horizontalScrollController.animateTo(
      scrollX,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _verticalScrollController.animateTo(
      scrollY,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    hasBeenBuilt = true;
    return Scaffold(
      floatingActionButton: (capitalColumn != null && capitalRow != null)
          ? FloatingActionButton(
              child: const Icon(Icons.location_on),
              onPressed: () {
                _scrollToConqueredTile(capitalRow!, capitalColumn!);
              },
            )
          : null,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                resources.length,
                (index) {
                  return resourceTile(
                      resource: resources[index],
                      icon: 'assets/resource-icons/${resources[index]}.png',
                      size: min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) / (resources.length * 1.6),
                      textSize: 100 / (resources.length * 1.6),
                      context: context);
                },
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: buildMapGrid(),
      ),
    );
  }

  Widget buildMapGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 5)),
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * tiles.length / 3,
            child: Center(
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                scrollDirection: Axis.vertical,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: tiles.length,
                  ),
                  itemBuilder: (context, index) {
                    // Customize the appearance of each grid tile
                    return buildMapTile(index % tiles.length, index ~/ tiles.length);
                  },
                  itemCount: tiles.length * tiles.length,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool isConqueredBy(int row, int column, String by) {
    return tiles[row][column].conqueredBy == by;
  }

  bool isConquered(int row, int column) {
    return tiles[row][column].conqueredBy != null;
  }

  Widget buildMapTile(int rowIndex, int columnIndex) {
    Tile tile = tiles[rowIndex][columnIndex];
    bool conquered = isConqueredBy(rowIndex, columnIndex, userProfile!.username);
    bool canConquer = isTileConquerable(rowIndex, columnIndex, userProfile!.username) && tile.conqueredBy != userProfile!.username && !tile.isCapital;

    // Check neighboring tiles
    bool conqueredTop = rowIndex > 0 && isConqueredBy(rowIndex - 1, columnIndex, tile.conqueredBy ?? "");
    bool conqueredBottom = rowIndex < tiles.length - 1 && isConqueredBy(rowIndex + 1, columnIndex, tile.conqueredBy ?? "");
    bool conqueredLeft = columnIndex > 0 && isConqueredBy(rowIndex, columnIndex - 1, tile.conqueredBy ?? "");
    bool conqueredRight = columnIndex < tiles[0].length - 1 && isConqueredBy(rowIndex, columnIndex + 1, tile.conqueredBy ?? "");

    return GestureDetector(
      onTap: () {
        if (canConquer || conquered || tile.isCapital) {
          _showTileInfoDialog(context, tile, canConquer, rowIndex, columnIndex);
        }
      },
      child: canConquer || conquered || isTileConquerable(rowIndex, columnIndex, userProfile!.username)
          ? Container(
              margin: EdgeInsets.fromLTRB(conqueredTop ? 0 : 5, conqueredLeft ? 0 : 5, conqueredBottom ? 0 : 5, conqueredRight ? 0 : 5),
              decoration: BoxDecoration(
                color: tile.isCapital ? stringToColor(tile.conqueredBy ?? "grey") : stringToColor(tile.conqueredBy ?? "grey").withOpacity(0.9),
                border: tile.isCapital ? Border.all(width: 5, color: tile.conqueredBy == userProfile!.username ? Colors.green : Colors.red) : null,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (tile.conqueredBy != null) ...[
                      Icon(
                        tile.isCapital ? Icons.castle : Icons.flag,
                        color: Colors.white,
                        size: 40,
                      ),
                      Text(
                        "$rowIndex - $columnIndex",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      if (!tile.isCapital && tile.soldiersRequiredToConquer().toInt() > 0)
                        Text(
                          "${translations["level"]}: ${tile.soldiersRequiredToConquer().toInt()}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 25),
                        ),
                    ],
                    Text(
                      tile.conqueredBy ?? "+",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            )
          : Container(margin: const EdgeInsets.all(2), color: Colors.blueGrey),
    );
  }

  bool isTileConquerable(int rowIndex, int columnIndex, String by) {
    // Check if any bordering tile is already conquered
    for (int i = max(0, rowIndex - 1); i <= min(rowIndex + 1, tiles.length - 1); i++) {
      for (int j = max(0, columnIndex - 1); j <= min(columnIndex + 1, tiles[0].length - 1); j++) {
        if (isConqueredBy(i, j, by)) {
          return true;
        }
      }
    }
    return false;
  }

  Map<String, int> orderResources(Map<String, int> originalMap, List<String> order) {
    Map<String, int> orderedMap = {};
    order.forEach((key) {
      if (originalMap.containsKey(key)) {
        orderedMap[key] = originalMap[key]!;
      }
    });
    return orderedMap;
  }

  void _showTileInfoDialog(BuildContext context, Tile tile, bool canConquer, int row, int column) {
    TextEditingController woodController = TextEditingController(text: "0");
    TextEditingController stoneController = TextEditingController(text: "0");
    TextEditingController goldController = TextEditingController(text: "0");
    TextEditingController ironController = TextEditingController(text: "0");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tile.isCapital
                        ? Icons.castle
                        : tile.conqueredBy == null
                            ? Icons.close
                            : Icons.flag,
                    size: 40,
                  ),
                  ListTile(
                    title: Text(tile.conqueredBy ?? translations["empty"]),
                    subtitle: Text(translations["conqueredBy"]),
                  ),
                  ListTile(
                    title: Text("$row - $column"),
                    subtitle: Text(translations["location"]),
                  ),
                  if (!tile.isCapital) ...[
                    const Divider(
                      thickness: 2,
                    ),
                    Text(
                      translations["defense"],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 27),
                    ),
                    Text(
                      "${translations["level"]}: ${tile.soldiersRequiredToConquer().toInt()}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    if (tile.soldiersRequiredToConquer() % 1 > 0)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LinearProgressIndicator(
                          value: tile.soldiersRequiredToConquer() % 1,
                          minHeight: 30,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: getResourceTiles(orderResources(tile.resourcesInvested, ["Wood", "Stone", "Gold", "Iron"]), 1, 1),
                    ),
                    if (tile.conqueredBy == userProfile!.username) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildResourceInput(woodController, storedResources["Wood"] ?? 0, state),
                          buildResourceInput(stoneController, storedResources["Stone"] ?? 0, state),
                          buildResourceInput(goldController, storedResources["Gold"] ?? 0, state),
                          buildResourceInput(ironController, storedResources["Iron"] ?? 0, state),
                        ],
                      ),
                      ElevatedButton(
                          onPressed: ((int.tryParse(woodController.text) ?? 0) +
                                      (int.tryParse(ironController.text) ?? 0) +
                                      (int.tryParse(stoneController.text) ?? 0) +
                                      (int.tryParse(goldController.text) ?? 0) >
                                  0)
                              ? () {
                                  // Add the manually entered resources to the tile
                                  state(
                                    () {
                                      tiles[row][column].resourcesInvested.update("Wood", (value) => value + int.parse(woodController.text));
                                      tiles[row][column].resourcesInvested.update("Stone", (value) => value + int.parse(stoneController.text));
                                      tiles[row][column].resourcesInvested.update("Gold", (value) => value + int.parse(goldController.text));
                                      tiles[row][column].resourcesInvested.update("Iron", (value) => value + int.parse(ironController.text));
                                      storedResources.update("Wood", (value) => value - int.parse(woodController.text));
                                      storedResources.update("Stone", (value) => value - int.parse(stoneController.text));
                                      storedResources.update("Gold", (value) => value - int.parse(goldController.text));
                                      storedResources.update("Iron", (value) => value - int.parse(ironController.text));
                                      woodController.text = "0";
                                      stoneController.text = "0";
                                      goldController.text = "0";
                                      ironController.text = "0";
                                      saveMapData(tiles);
                                    },
                                  );
                                  Navigator.pop(context);
                                  saveResources(widget.currentEmpire.id!);
                                }
                              : null,
                          child: Text(translations["upgrade"])),
                      const Divider(),
                    ]
                  ] else if (tile.conqueredBy != null)
                    ListTile(
                      subtitle: Text(translations["tilesOwned"]),
                      title: Text(tiles.expand((element) => element).where((element) => element.conqueredBy == tile.conqueredBy).length.toString()),
                    )
                  // Manual resource input section
                ],
              ),
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {});
              },
              child: Text(translations['close']),
            ),
            if (canConquer)
              ElevatedButton(
                onPressed: ((storedResources["Soldier"] ?? 0) > tile.soldiersRequiredToConquer().toInt())
                    ? () {
                        Navigator.pop(context);
                        setState(() {
                          storedResources.update("Soldier", (value) => value - tile.soldiersRequiredToConquer().toInt() - 1);
                          tiles[row][column].conqueredBy = userProfile!.username;
                          tiles[row][column].resourcesInvested = {"Wood": 0, "Stone": 0, "Gold": 0, "Iron": 0};
                        });
                        _scrollToConqueredTile(column, row);
                        saveResources(widget.currentEmpire.id!);
                        saveMapData(tiles);
                      }
                    : null,
                child: Text(translations["conquer"]),
              )
          ],
        );
      },
    );
  }

  Widget buildResourceInput(TextEditingController controller, int maxResourceCount, Function update) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 10,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (int.tryParse(value) == null || (int.tryParse(value) ?? 0) > maxResourceCount) {
                  controller.text = min(int.tryParse(controller.text) ?? 0, maxResourceCount).toString();
                }
                update(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
