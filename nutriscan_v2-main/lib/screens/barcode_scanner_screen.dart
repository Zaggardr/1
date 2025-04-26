import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/product_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final TextEditingController _barcodeController = TextEditingController();
  final ProductService _productService = ProductService();
  bool _isLoading = false;
  bool _isScanning = false;
  late MobileScannerController _scannerController;
  int _currentIndex = 0;

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.barcode_reader),
      label: 'Scan',
      backgroundColor: Colors.green, // Updated to match theme
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'History',
      backgroundColor: Colors.green,
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Profile',
      backgroundColor: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isScanning) {
      _scannerController.start();
    } else if (state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _startBarcodeScan() async {
    setState(() {
      _isScanning = true;
      _currentIndex = 0;
      _scannerController.dispose();
      _scannerController = MobileScannerController();
    });
    await _scannerController.start();
  }

  Future<void> _fetchProductInfo(String barcode) async {
    setState(() => _isLoading = true);
    _isScanning = false;

    try {
      // Use ProductService to fetch product data
      final product = await _productService.fetchProduct(barcode);

      if (product != null) {
        // Log product data for debugging KPI discrepancy
        print(
          'Product Data: Energy=${product.getEnergy()}, Sugars=${product.getSugar()}, '
          'Fat=${product.getFat()}, Salt=${product.getSalt()}, '
          'Ingredients=${product.ingredientsText}, Allergens=${product.allergens}',
        );

        // Navigate to ProductDetailsScreen
        Navigator.pushNamed(context, '/product', arguments: product);

        // Save product to Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scans')
              .add({
                'productName': product.productName ?? 'Unknown Product',
                'brands': product.brands ?? 'N/A',
                'ingredientsText': product.ingredientsText ?? 'N/A',
                'timestamp': FieldValue.serverTimestamp(),
              });
          print('Product saved to Firestore: ${product.productName}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found for barcode: $barcode')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _isScanning
              ? null
              : AppBar(
                title: const Text('Nutrition Scanner'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                ],
              ),
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[100]!, Colors.white],
          ),
        ),
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: _buildSnapchatBottomBar(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _isScanning ? _buildScannerView() : _buildInputView();
      case 1:
        return _buildHistoryView();
      case 2:
        return _buildProfileView();
      default:
        return _buildInputView();
    }
  }

  Widget _buildHistoryView() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, '/login');
      });
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scans')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading history: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No scan history available',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        final scans = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: scans.length,
          itemBuilder: (context, index) {
            final scanData = scans[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              shadowColor: Colors.green.withOpacity(0.4),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  scanData['productName'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Brand: ${scanData['brands'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      'Scanned: ${scanData['timestamp'] != null ? (scanData['timestamp'] as Timestamp).toDate().toString() : 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('scans')
                        .doc(scans[index].id)
                        .delete();
                  },
                ),
                onTap: () {
                  final product = Product(
                    productName: scanData['productName'],
                    brands: scanData['brands'],
                    ingredientsText: scanData['ingredientsText'],
                  );
                  Navigator.pushNamed(context, '/product', arguments: product);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSnapchatBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[600],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _isScanning = (index == 0 && _isScanning);
          });
        },
        items: _bottomNavItems,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (!_isLoading) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String barcode = barcodes.first.rawValue ?? '';
                print('Barcode detected: $barcode');
                if (barcode.isNotEmpty) {
                  _barcodeController.text = barcode;
                  _fetchProductInfo(barcode);
                }
              }
            }
          },
        ),
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              await _scannerController.stop();
              setState(() => _isScanning = false);
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 70),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Point your camera at a barcode',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputView() {
    return ListView(
      padding: const EdgeInsets.all(38.0),
      children: [
        const SizedBox(height: 16),
        const Icon(
          Icons.qr_code_scanner,
          size: 200,
          color: Colors.green, // Updated to match theme
        ),
        const SizedBox(height: 16),
        const Text(
          'Scanner un produit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scanner le code-barres du produit',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        MaterialButton(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.green[600],
          onPressed: _isLoading ? null : _startBarcodeScan,
          child: const Text(
            'Démarrer le scan',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Code-barres',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Entrez manuellement le code-barre:',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _barcodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Entrez le code-barres ici',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        MaterialButton(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.green[600],
          onPressed:
              _isLoading
                  ? null
                  : () {
                    if (_barcodeController.text.isNotEmpty) {
                      _fetchProductInfo(_barcodeController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer un code-barres'),
                        ),
                      );
                    }
                  },
          child: const Text(
            'Analyser le produit',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (user != null) ...[
            Text('Email : ${user.email ?? 'Non disponible'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ] else
            const Text('Veuillez vous connecter'),
        ],
      ),
    );
  }
}
