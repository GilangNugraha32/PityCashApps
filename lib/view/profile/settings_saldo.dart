import 'package:flutter/material.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/view/home/home.dart';

class SettingsSaldo extends StatefulWidget {
  @override
  _SettingsSaldoState createState() => _SettingsSaldoState();
}

class _SettingsSaldoState extends State<SettingsSaldo>
    with SingleTickerProviderStateMixin {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final ApiService _apiService = ApiService();
  final TextEditingController _minSaldoController = TextEditingController();

  double currentSaldo = 0.0;
  double minSaldo = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadCurrentSaldo();
    _loadMinSaldo();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
    _minSaldoController.addListener(_formatCurrency);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _minSaldoController.removeListener(_formatCurrency);
    _minSaldoController.dispose();
    super.dispose();
  }

  void _formatCurrency() {
    String text = _minSaldoController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isNotEmpty) {
      double value = double.parse(text);
      String formattedValue = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      ).format(value);
      _minSaldoController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  }

  Future<void> _loadCurrentSaldo() async {
    try {
      final saldo = await _apiService.fetchSaldo();
      setState(() {
        currentSaldo = saldo;
      });
    } catch (e) {
      print('Error fetching saldo: $e');
      _showSnackBar('Gagal memuat saldo saat ini');
    }
  }

  Future<void> _loadMinSaldo() async {
    try {
      final minSaldo = await _apiService.fetchMinimalSaldo();
      setState(() {
        this.minSaldo = minSaldo;
        _minSaldoController.text = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp',
          decimalDigits: 0,
        ).format(minSaldo);
      });
    } catch (e) {
      print('Error fetching minimal saldo: $e');
      _showSnackBar('Gagal memuat saldo minimal');
    }
  }

  Future<void> _updateMinSaldo() async {
    try {
      String minSaldoText =
          _minSaldoController.text.replaceAll(RegExp(r'[^0-9]'), '');
      double newMinSaldo = double.parse(minSaldoText);
      await _apiService.updateMinimalSaldo(newMinSaldo);
      setState(() {
        minSaldo = newMinSaldo;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo minimal berhasil diperbarui'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      // Kembali ke halaman sebelumnya
      Navigator.pop(context, true);

      // Refresh halaman PengeluaranSection dengan mempertahankan bottom navigation bar
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: 4),
        ),
      );
    } catch (e) {
      print('Error updating minimal saldo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui saldo minimal: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEB8153), Color(0xFFFF9D6C)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCurrentSaldoCard(),
                          SizedBox(height: 24),
                          _buildMinSaldoInput(),
                          SizedBox(height: 24),
                          _buildSaveButton(),
                          SizedBox(height: 24),
                          _buildInfoCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Pengaturan Saldo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCurrentSaldoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo Saat Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp',
                    decimalDigits: 0,
                  ).format(currentSaldo * _animation.value),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEB8153),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinSaldoInput() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Color(0xFFEB8153), size: 24),
                SizedBox(width: 10),
                Text(
                  'Atur Minimal Saldo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEB8153),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Minimal Saldo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _minSaldoController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Masukkan minimal saldo',
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Masukkan jumlah minimal saldo yang Anda inginkan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _updateMinSaldo,
      style: ElevatedButton.styleFrom(
        primary: Color(0xFFEB8153),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: Text(
        'Simpan Pengaturan',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                SizedBox(width: 10),
                Text(
                  'Informasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Anda akan menerima peringatan ketika saldo Anda mencapai batas minimal yang telah diatur.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
