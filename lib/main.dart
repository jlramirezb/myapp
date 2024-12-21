import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

class PriceData {
  final String product;
  final String price;
  final String quantity;
  final String currency;
  final String priceInBolivares;
  final String priceInDollars;
  final String type;

  const PriceData({required this.product, required this.price, required this.quantity, required this.currency, required this.priceInBolivares, required this.priceInDollars, required this.type});
}

void main() { 
  WidgetsFlutterBinding.ensureInitialized(); // Asegúrate de inicializar los plugins
  runApp(MyApp());
}

class MyApp extends StatelessWidget { 
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Compras',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DollarPriceScreen(),
    );
  }
}

class DollarPriceScreen extends StatefulWidget {
  const DollarPriceScreen({super.key});
  @override
  DollarPriceScreenState createState() => DollarPriceScreenState();
}

class DollarPriceScreenState extends State<DollarPriceScreen> {
  final TextEditingController _dollarPriceController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); 
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _newProductController = TextEditingController();
  final TextEditingController _selectedProductController = TextEditingController();
  final List<PriceData> _products = [];
  String _selectedType = 'Unidad';
  String _selectedCurrency = 'Dólar';
  String _selectedProduct = 'Producto 1';
  double _totalInBolivares = 0.0;
  double _totalInDollars = 0.0;
  bool _isDollarPriceEntered = false;

  List<String> _productList = ['Producto 1', 'Producto 2', 'Producto 3'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/products.json';
    return path;
  }

  Future<void> _loadProducts() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final jsonData = json.decode(contents); 
        setState(() {
          _productList = jsonData.cast<String>();
        });
      } else {
        // Create the file with initial products if it doesn't exist
        await _saveProducts();
      }
    } catch (e) {
      // Handle error loading products
    }
  }

  Future<void> _saveProducts() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      final jsonData = json.encode(_productList);
      await file.writeAsString(jsonData);
    } catch (e) {
      // Handle error saving products
    }
  }

  void _addProduct() {
    setState(() {
      String product = _selectedProduct;
      String price = _priceController.text;
      String quantity = _quantityController.text;
      double dollarPrice = double.tryParse(_dollarPriceController.text) ?? 1.0;
      double priceValue = double.tryParse(price) ?? 0.0;
      double quantityValue = double.tryParse(quantity) ?? 1.0;
      double priceInBolivares;
      double priceInDollars;
      if (_selectedCurrency == 'Dólar') {
        priceInDollars = priceValue * quantityValue;
        priceInBolivares = priceInDollars * dollarPrice;
      } else {
        priceInBolivares = priceValue * quantityValue;
        priceInDollars = priceInBolivares / dollarPrice;
    }

    _products.add(PriceData(
      product: product,
      price: price,
      quantity: quantity,
      currency: _selectedCurrency,
      priceInBolivares: priceInBolivares.toStringAsFixed(2),
      priceInDollars: priceInDollars.toStringAsFixed(2),
      type: _selectedType,
    ));

      _totalInBolivares += priceInBolivares;
      _totalInDollars += priceInDollars;

      _priceController.clear();
      _quantityController.clear();
    });
  }

  void _removeProduct(int index) {
    setState(() {
      double priceInBolivares = double.parse(_products[index].priceInBolivares);
      double priceInDollars = double.parse(_products[index].priceInDollars);

      _totalInBolivares -= priceInBolivares;
      _totalInDollars -= priceInDollars;

      _products.removeAt(index);
    });
  }

  void _addNewProduct() {
    setState(() {
      String newProduct = _newProductController.text;
      if (newProduct.isNotEmpty && !_productList.contains(newProduct)) {
        _productList.add(newProduct);
        _saveProducts();
        _newProductController.clear();
      }
    });
  }

  void _editProduct(int index) {
    setState(() {
      _newProductController.text = _productList[index];
      _productList.removeAt(index);
      _saveProducts();
    });
  }

  void _deleteProduct(int index) {
    setState(() {
      _productList.removeAt(index);
      _saveProducts();
    });
  }

  Future<void> _showEditDialog(int index) async {
    final editPriceController = TextEditingController(text: _products[index].price);
    final editQuantityController = TextEditingController(text: _products[index].quantity);

    await showDialog<void>(
      context: context, 
      builder: (BuildContext context) { 
        return AlertDialog(
          title: const Text('Editar Producto'),
          content: Column( 
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: editPriceController, 
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
              ), 
              const SizedBox(height: 16.0),
              TextField(
                controller: editQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad/Peso',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ], 
          ), // Add missing closing parenthesis
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                setState(() {
                  String price = editPriceController.text;
                  String quantity = editQuantityController.text;
                  double dollarPrice = double.tryParse(_dollarPriceController.text) ?? 1.0;
                  double priceValue = double.tryParse(price) ?? 0.0;
                  double quantityValue = double.tryParse(quantity) ?? 1.0;
                  double priceInBolivares;
                  double priceInDollars;

                  if (_products[index].currency == 'Dólar') {
                    priceInDollars = priceValue * quantityValue;
                    priceInBolivares = priceInDollars * dollarPrice;
                  } else {
                    priceInBolivares = priceValue * quantityValue;
                    priceInDollars = priceInBolivares / dollarPrice;
                  }                  
                  // Create a new PriceData object with updated values
                  final updatedProduct = PriceData(
                    product: _products[index].product,
                    price: price,
                    quantity: quantity,
                    currency: _products[index].currency,
                    priceInBolivares: priceInBolivares.toStringAsFixed(2),
                    priceInDollars: priceInDollars.toStringAsFixed(2),
                    type: _products[index].type,
                  );

                  // Update totals
                  _totalInBolivares = _totalInBolivares -
                      double.parse(_products[index].priceInBolivares) +
                      priceInBolivares;
                  _totalInDollars = _totalInDollars -
                      double.parse(_products[index].priceInDollars) +
                      priceInDollars;
                  _products[index] = updatedProduct;                  
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Compras'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _dollarPriceController,
                decoration: const InputDecoration(
                  labelText: "Precio del Dólar",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() { 
                    _isDollarPriceEntered = value.isNotEmpty;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _newProductController,
                decoration: const InputDecoration(
                  labelText: "Nuevo Producto",
                  border: OutlineInputBorder(),
                ), 
                enabled: _isDollarPriceEntered, 
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(                onPressed: _isDollarPriceEntered ? _addNewProduct : null, 
                child: const Text('Agregar Nuevo Producto'),
              ), 
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedProduct,
                onChanged: _isDollarPriceEntered
                    ? (String? newValue) {
                        setState(() {
                          _selectedProduct = newValue!;
                          _selectedProductController.text = newValue;
                        });
                      }
                    : null,
                items: _productList.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value, 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [ 
                        Text(value),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                final int index = _productList.indexOf(value);
                                _editProduct(index); 
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                int index = _productList.indexOf(value);
                                _deleteProduct(index);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(), 
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Producto',
                  border: OutlineInputBorder(),
                ),
                disabledHint: const Text('Seleccionar Producto'),
              ), 
              const SizedBox(height: 16.0),
              TextField(
                controller: _selectedProductController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),              
              const SizedBox(height: 16.0),
              Row(
                children: <Widget>[ 
                  Expanded( 
                    child: TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Precio en $_selectedCurrency',
                        border: const OutlineInputBorder(),
                      ), 
                      keyboardType: TextInputType.number,
                      enabled: _isDollarPriceEntered,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded( 
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      onChanged: _isDollarPriceEntered
                          ? (String? newValue) {
                              setState(() {
                                _selectedCurrency = newValue!;
                              });
                            }
                          : null,
                      items: <String>['Dólar', 'Bolívares']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Moneda', 
                        border: OutlineInputBorder(),
                      ),
                      disabledHint: const Text('Moneda'),
                    ),
                  ),
                ],
              ), 
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(                    
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      onChanged: _isDollarPriceEntered
                          ? (String? newValue) {
                              setState(() {
                                _selectedType = newValue!;
                              });
                            }
                          : null,
                      items: <String>['Unidad', 'Peso']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>( 
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      disabledHint: const Text('Tipo'),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextField( 
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: _selectedType == 'Unidad'
                            ? 'Cantidad'
                            : 'Peso (kg)', 
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: _selectedType == 'Peso'),
                      enabled: _isDollarPriceEntered,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isDollarPriceEntered ? _addProduct : null, 
                child: const Text('Agregar Producto'),
              ), 
              const SizedBox(height: 16.0),
              Text( 
                'Total en Bolívares: ${_totalInBolivares.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text( 
                'Total en Dólares: ${_totalInDollars.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),              
              const SizedBox(height: 16.0), 
              const Divider(),
              const SizedBox(height: 16.0), 
              const Text(
                'Lista de Productos', 
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ), 
              const SizedBox(height: 16.0),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ListTile(
                    title: Text('${product.product} - ${product.currency == 'Dólar' ? '\$' : 'Bs.'}${product.price} - ${product.type == 'Unidad' ? 'Cantidad: ${product.quantity}' : 'Peso: ${product.quantity} kg'}'),
                    subtitle: Text('Precio en Bs: ${product.priceInBolivares} - Precio en \$: ${product.priceInDollars}'),
                    trailing: Row( 
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[ 
                        IconButton( 
                          icon: const Icon(Icons.edit), 
                          onPressed: () => _showEditDialog(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeProduct(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}