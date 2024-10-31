import 'package:biro_pos/components/quantity_increase.dart';
import 'package:biro_pos/controllers/klic.dart';
import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/screens/edit_item_screen.dart';
import 'package:biro_pos/screens/nacin_placila_screen.dart';
import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class NacinPlacila {
  final String kodaNacinaPlacila;
  final String nacinPlacila;

  NacinPlacila(this.kodaNacinaPlacila, this.nacinPlacila);

  @override
  String toString() {
    return 'NacinPlacila(kodaNacinaPlacila: $kodaNacinaPlacila, nacinPlacila: $nacinPlacila)';
  }
}

class RacunScreen extends StatefulWidget {
  final dynamic selectedItem;
  final double itemQuantity;
  final double finalSum;
  final List<dynamic> chosenItems;

  const RacunScreen({
    super.key,
    required this.selectedItem,
    required this.itemQuantity,
    required this.finalSum,
    required this.chosenItems,
  });

  @override
  State<RacunScreen> createState() => _RacunScreenState();
}

class _RacunScreenState extends State<RacunScreen> {
  late double finalSum;
  double _totalDiscount = 0.0;
  late List<dynamic> chosenItems;
  final TextEditingController discountController = TextEditingController();
  List<NacinPlacila> naciniPlacila = [];
  String itemOpis = '';

  @override
  void initState() {
    super.initState();
    finalSum = widget.finalSum;
    chosenItems = widget.chosenItems;
    _updateFinalSum();
    _handleData();
  }

  Future<void> _handleData() async {
    List<String> apiResponseList = await sendRequest("1", "Biropos.txt");

    _kategorizirajNacinePlacila(apiResponseList);
  }

  _kategorizirajNacinePlacila(List<String> items) {
    List<NacinPlacila> naciniPlacila2 = [];

    for (String item in items) {
      if (item.startsWith('7')) {
        String kodaNacinaPlacila = item.split('|')[1];
        String nacinPlacila = item.split('|')[2];

        NacinPlacila newNacinPlacila =
            NacinPlacila(kodaNacinaPlacila, nacinPlacila);
        naciniPlacila2.add(newNacinPlacila);
      }
    }

    setState(() {
      naciniPlacila = naciniPlacila2;
    });
    print(naciniPlacila.toString());
  }

  Future<void> _createOrder(String izbranNacinPlacila) async {
    String? userId = SessionManager().getLoggedInUserSifra();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in!")),
      );
      return;
    }

    List<String> narociloItems = chosenItems.map((item) {
      String artikelSifra = item['itemId']?.toString() ?? '';
      double kolicina = (item['quantity'] ?? 1.0).toDouble();
      String artikelSkupina = item['categoryID'].toString();

      double originalPrice =
          double.tryParse(item['price'].toString().replaceAll(',', '.')) ?? 0.0;
      double cena = originalPrice ?? 0.0;
      double itemDiscountedPrice = item['discountedPrice'] ?? cena;

      num popust = (cena != 0) ? ((1 - (itemDiscountedPrice / cena)) * 100) : 0;

      if (izbranNacinPlacila == "GOT") {
        String sifraGotovina = naciniPlacila[0].kodaNacinaPlacila;
        String narociloItem =
            '$userId\t#MIZA#\t$artikelSifra\t$kolicina\t$cena\t$popust\tDIREKTENRACUN;$sifraGotovina;;${item['opis'] ?? ''};\t$artikelSkupina';
        print("Narocilo item: $narociloItem");

        return narociloItem;
      } else if (izbranNacinPlacila == "KAR") {
        String sifraKartica = naciniPlacila[1].kodaNacinaPlacila;
        String narociloItem =
            '$userId\t#MIZA#\t$artikelSifra\t$kolicina\t$cena\t$popust\tDIREKTENRACUN;$sifraKartica;;${item['opis'] ?? ''};\t$artikelSkupina';
        return narociloItem;
      }
      return '';
    }).toList();

    List<String> posljiNaStreznik =
        await sendRequest("1", narociloItems.join('\r\n'));

    _showResponseDialog(posljiNaStreznik);
  }

// Function to show the response in a dialog
  void _showResponseDialog(List<String> response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Server Response"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(response.join('\n')), // Display the response line by line
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleQuantityChange(double newQuantity, int index) {
    setState(() {
      chosenItems[index]['quantity'] = newQuantity;
      _updateFinalSum();
    });
  }

  void _removeItem(int index) {
    setState(() {
      chosenItems.removeAt(index);
      _updateFinalSum();
    });
  }

  void _navigateToEdit(int index) async {
    var item = chosenItems[index];
    String itemName = item['name'] ?? 'Unknown';
    double itemPrice =
        double.tryParse(item['price'].toString().replaceAll(',', '.')) ?? 0;
    double itemDiscountedPrice = item['discountedPrice'] ?? itemPrice;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItemScreen(
          itemName: itemName,
          itemDiscountedPrice: itemDiscountedPrice,
        ),
      ),
    );

    if (result != null && result['opis'] != null) {
      setState(() {
        chosenItems[index]['opis'] = result['opis'];
        ;
      });
    }
  }

  double totalDiscount = 0;

  void _updateFinalSum() {
    double newFinalSum = 0;
    double totalDiscount = 0;

    for (var item in chosenItems) {
      double itemQuantity = item['quantity'] ?? 1;

      double itemPrice =
          double.tryParse(item['price'].toString().replaceAll(',', '.')) ?? 0.0;

      double itemDiscountedPrice = double.tryParse(
              item['discountedPrice'].toString().replaceAll(',', '.')) ??
          itemPrice;

      newFinalSum += itemDiscountedPrice * itemQuantity;

      double itemDiscountValue =
          (itemPrice - itemDiscountedPrice) * itemQuantity;

      totalDiscount += itemDiscountValue;
    }

    setState(() {
      finalSum = newFinalSum;
      _totalDiscount = totalDiscount;
    });
  }

  void _clearText() {
    discountController.clear();
  }

  void _submit(int? index, bool isFinalDiscount, [double? discount]) {
    if (isFinalDiscount) {
      double finalDiscount = discount ?? 0;
      double finalDiscountPercentage = finalDiscount / 100;

      setState(() {
        for (var item in chosenItems) {
          double itemPrice =
              double.tryParse(item['price'].toString().replaceAll(',', '.')) ??
                  0;
          item['discountedPrice'] = itemPrice * (1 - finalDiscountPercentage);
        }
        _updateFinalSum();
      });

      return;
    }

    // Item-specific discount logic
    double itemDiscount = 0;

    if (discountController.text.isNotEmpty) {
      try {
        itemDiscount = double.parse(discountController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vnesi popust")),
        );
        return;
      }
    }

    if (index != null) {
      var item = chosenItems[index];
      double itemPrice =
          double.tryParse(item['price'].toString().replaceAll(',', '.')) ?? 0;
      double itemQuantity = item['quantity'] ?? 1;

      double itemTotal = itemPrice * itemQuantity;
      double discountedPrice =
          itemTotal * (1 - (itemDiscount / 100)) / itemQuantity;

      setState(() {
        item['discountedPrice'] = discountedPrice;
        _updateFinalSum();
      });
    }

    // Close the dialog
  }

  Future openDialog(int? index, bool isFinalDiscount, [double? discount]) {
    discountController.clear();
    // če urejamo popust za posamezen izdelek
    if (index != null && !isFinalDiscount) {
      var item = chosenItems[index];

      // Če ima izdelek poseben popust
      if (item['discountedPrice'] != null) {
        double originalPrice =
            double.tryParse(item['price'].toString().replaceAll(',', '.')) ?? 0;
        double discountedPrice = item['discountedPrice'] ?? originalPrice;
        double discountPercentage =
            100 - ((discountedPrice / originalPrice) * 100);

        discountController.text = discountPercentage.toStringAsFixed(0);
      } else if (discount != null) {
        // Če ne, prikaži popust za celoten nakup (finalSUm)
        double globalDiscountPercentage =
            100 - (finalSum / (finalSum / (1 - discount / 100)));
        discountController.text = globalDiscountPercentage.toString();
      }
    }

    if (isFinalDiscount && discount != null) {
      discountController.text = discount.toString();
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.white,
        title: const Text(
          textAlign: TextAlign.center,
          "Popust",
          style: AppStyles.heading2,
        ),
        content: TextField(
          controller: discountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppStyles.silver.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearText,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _submit(index, isFinalDiscount,
                  double.tryParse(discountController.text));
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.blue,
            ),
            child: Text("OK",
                style: AppStyles.button1.copyWith(color: AppStyles.white)),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyles.black),
          onPressed: () => Navigator.pop(context, {
            'updatedQuantity':
                chosenItems.map((item) => item['quantity'] as double).toList(),
            'updatedFinalSum': finalSum,
            // Collect each item's description in a list
            'itemDescriptions':
                chosenItems.map((item) => item['opis'] ?? '').toList(),
          }),
        ),
        title: Text("Račun",
            style: AppStyles.heading3.copyWith(color: AppStyles.black)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: chosenItems.length,
              itemBuilder: (context, index) {
                final item = chosenItems[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'],
                                    style: AppStyles.boldanparagraph1),
                                Text(
                                  item['opis'] != null
                                      ? item['opis'].toString()
                                      : '',
                                  style: AppStyles.paragraph4
                                      .copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('${item['price'].toString()}€',
                                style: AppStyles.heading3),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                                backgroundColor: AppStyles.blue),
                            onPressed: () => _navigateToEdit(index),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                                backgroundColor: AppStyles.darkGreen),
                            onPressed: () {
                              openDialog(index, false);
                            },
                            icon: const Icon(Icons.percent),
                          ),
                          IconButton.filled(
                              style: IconButton.styleFrom(
                                  backgroundColor: AppStyles.red),
                              onPressed: () => _removeItem(index),
                              icon: const Icon(Icons.delete)),
                          const Spacer(),
                          QuantityIncrease(
                            quantity: item['quantity'],
                            onQuantityChanged: (newQuantity) {
                              _handleQuantityChange(newQuantity, index);
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            color: AppStyles.silver.withOpacity(0.1),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: Row(
                    children: [
                      Text(
                        "POPUST:",
                        style: AppStyles.heading3
                            .copyWith(fontWeight: FontWeight.normal),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          _submit(null, true, 5);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 50),
                        ),
                        child: Text("5%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () {
                          _submit(null, true, 10);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 50),
                        ),
                        child: Text("10%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _submit(null, true, 15);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 50),
                        ),
                        child: Text("15%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          openDialog(null, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.white,
                          elevation: 1,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 50),
                        ),
                        child: Text("?%",
                            style: AppStyles.button1
                                .copyWith(color: AppStyles.black)),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      IconButton.filled(
                        iconSize: 32,
                        style: IconButton.styleFrom(
                            backgroundColor: AppStyles.red),
                        onPressed: () {
                          _submit(null, true, 0);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text(
                        "Vrednost popusta: ",
                      ),
                      const Spacer(),
                      Text('${_totalDiscount.toStringAsFixed(2)} €')
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    children: [
                      const Text("SKUPAJ:", style: AppStyles.heading3),
                      const Spacer(),
                      Text(
                        '${finalSum.toStringAsFixed(2)} €',
                        style: AppStyles.cardItemName.copyWith(
                            color: AppStyles.black,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => _createOrder("GOT"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.darkOrange,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                        child: Text(
                          "GOTOVINA",
                          style: AppStyles.button2
                              .copyWith(color: AppStyles.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _createOrder("KAR"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.red,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                        child: Text("KARTICA",
                            style: AppStyles.button2
                                .copyWith(color: AppStyles.white)),
                      ),
                      ElevatedButton(
                        onPressed: _navigateToNacinPlacilaScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.blue,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(100, 50),
                        ),
                        child: Text("OSTALO",
                            style: AppStyles.button2
                                .copyWith(color: AppStyles.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToNacinPlacilaScreen() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NacinPlacilaScreen(finalSum: finalSum)));
  }
}

class NarociloItem {
  final String artikelSifra;
  final double kolicina;
  final double cena;
  final double popust;
  final String opis;
  final String kategorijaSifra;

  NarociloItem({
    required this.artikelSifra,
    required this.kolicina,
    required this.cena,
    required this.popust,
    required this.opis,
    required this.kategorijaSifra,
  });
}

class Narocilo {
  final String uporabnikSifra;
  final String oznakaMize;
  final double skupnaCena;
  final double skupniPopust;
  final List<NarociloItem> items;

  Narocilo({
    required this.uporabnikSifra,
    required this.oznakaMize,
    required this.skupnaCena,
    required this.skupniPopust,
    required this.items,
  });
}
