import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/service/api_service.dart'; // Import API service
import 'package:pity_cash/view/pemasukan/detail_pemasukan.dart';
import 'package:pity_cash/view/pemasukan/tambah_pemasukan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PemasukanSection extends StatefulWidget {
  @override
  _PemasukanSectionState createState() => _PemasukanSectionState();
}

class _PemasukanSectionState extends State<PemasukanSection> {
  double saldo = 0.0;
  List<Pemasukan> incomes = [];
  List<Pemasukan> filteredIncomes = [];
  DateTimeRange? selectedDateRange; // Daftar yang sudah difilter

  bool isIncomeSelected = true;
  String? token;
  String? name;
  bool isLoggedIn = false;
  TextEditingController _searchController = TextEditingController();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final ApiService _apiService = ApiService(); // Instantiate ApiService

  bool isLoadingMore = false;
  int currentPage = 1;
  bool isLoading = true;

  @override
  @override
  void initState() {
    super.initState();
    _getSaldo();
    _checkLoginStatus();
    _fetchIncomes(currentPage); // Initial fetch
    _searchController
        .addListener(_filterIncomes); // Listen for changes in the search field
  }

  Future<void> _getSaldo() async {
    try {
      final fetchedSaldo =
          await _apiService.fetchSaldo(); // Panggil fungsi fetchSaldo
      setState(() {
        saldo = fetchedSaldo; // Update saldo dengan hasil dari API
        isLoading = false; // Matikan loading setelah saldo berhasil diambil
      });
    } catch (e) {
      print('Failed to load saldo: $e');
      setState(() {
        saldo = 0.0; // Atur saldo ke 0 jika gagal
        isLoading = false; // Matikan loading jika gagal mengambil saldo
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    token = await _prefsService.getToken();
    name = await _prefsService.getUserName();
    setState(() {
      isLoggedIn = token != null;
    });
  }

  Future<void> _fetchIncomes(int page) async {
    if (isLoadingMore) return; // Prevent fetching if already loading more data

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      // Add debug print to verify the API call
      print('Fetching incomes for page: $page');
      final fetchedIncomes = await _apiService.fetchIncomes(page: page);

      // Debug print the response from the API
      print('Fetched incomes: ${fetchedIncomes.toString()}');

      setState(() {
        if (page == 1) {
          incomes = fetchedIncomes; // Replace list for first page
        } else {
          incomes.addAll(fetchedIncomes); // Append for subsequent pages
        }
        currentPage++; // Increment current page for pagination

        // Apply filter if date range is selected
        if (selectedDateRange != null) {
          _filterIncomesByDateRange(); // Filter fetched data by date range
        } else {
          _filterIncomes(); // Filter by search query if no date range is selected
        }
      });
    } catch (e) {
      print('Error fetching incomes: $e'); // Log error message
      _showErrorSnackbar('Error fetching incomes. Please try again.');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
        isLoadingMore = false; // Reset loadingMore state
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: selectedDateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFFEB8153), // Warna oranye khusus
            accentColor:
                Color(0xFFEB8153), // Warna aksen untuk range yang dipilih
            colorScheme: ColorScheme.light(
              primary: Color(0xFFEB8153), // Warna header background picker
              onPrimary: Colors.white, // Warna teks di header (Putih)
              onSurface:
                  Color(0xFFEB8153), // Warna teks tanggal yang bisa dipilih
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary, // Warna teks tombol
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        _filterIncomesByDateRange(); // Filter incomes by the selected date range
      });
    }
  }

  void _filterIncomesByDateRange() {
    if (selectedDateRange != null) {
      // Filter the incomes based on the selected date range
      filteredIncomes = incomes.where((pemasukan) {
        // Parse pemasukan.date into DateTime
        final pemasukanDate = DateTime.parse(pemasukan.date);
        // Check if pemasukanDate is within the selected range
        return pemasukanDate.isAfter(
                selectedDateRange!.start.subtract(Duration(days: 1))) &&
            pemasukanDate
                .isBefore(selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    } else {
      filteredIncomes =
          List.from(incomes); // Show all incomes if no range is selected
    }
  }

  void _filterIncomes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredIncomes =
            List.from(incomes); // Show all incomes if query is empty
      } else {
        // Filter incomes based on name or date
        filteredIncomes = incomes.where((pemasukan) {
          return pemasukan.name.toLowerCase().contains(query) ||
              pemasukan.date
                  .toLowerCase()
                  .contains(query); // Filtering by name or date
        }).toList();
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSectionClick(bool isIncome) {
    setState(() {
      isIncomeSelected = isIncome;
      if (isIncome) {
        currentPage = 1; // Reset current page for incomes
        incomes.clear(); // Clear current income list
        _fetchIncomes(currentPage); // Fetch incomes again
      } else {
        // Implement expense fetching if needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Fixed orange background section
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Color(0xFFEB8153),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(16.0),
                    bottomLeft: Radius.circular(16.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLoggedIn ? 'Hi, $name!' : 'Hi, Guest!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      Center(
                        child: Text(
                          'Saldo Pity Cash',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Center(
                        child: isLoading
                            ? CircularProgressIndicator() // Tampilkan loading saat data sedang diambil
                            : Text(
                                NumberFormat.currency(
                                  locale: 'id_ID', // Format untuk IDR
                                  symbol: 'Rp ', // Simbol mata uang
                                  decimalDigits: 2, // Jumlah desimal
                                ).format(saldo), // Tampilkan saldo dari API
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      SizedBox(height: 12),
                      // Custom Toggle button for Income and Expense
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 60),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(6),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _handleSectionClick(true),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isIncomeSelected
                                        ? Color(0xFFEB8153)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Income',
                                      style: TextStyle(
                                        color: isIncomeSelected
                                            ? Colors.white
                                            : Color(0xFFB8B8B8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _handleSectionClick(false),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: !isIncomeSelected
                                        ? Color(0xFFEB8153)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Expense',
                                      style: TextStyle(
                                        color: !isIncomeSelected
                                            ? Colors.white
                                            : Color(0xFFB8B8B8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Search Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // White background color
                    borderRadius:
                        BorderRadius.circular(12.0), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3), // Shadow color
                        spreadRadius: 1, // Spread radius
                        blurRadius: 5, // Blur radius
                        offset: Offset(0, 6), // Shadow offset
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14.0), // Rounded corners
                        borderSide: BorderSide.none, // Remove border
                      ),
                    ),
                    onChanged: (value) {
                      // Implement the search functionality
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              // Categories List
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Row to hold buttons on the right
                      Row(
                        children: [
                          // Date Range Picker TextField
                          SizedBox(
                            width: 225, // Adjust width as needed
                            child: GestureDetector(
                              onTap: () => _selectDateRange(
                                  context), // Open date range picker on tap
                              child: AbsorbPointer(
                                // Prevents text editing
                                child: TextField(
                                  enabled: false, // Disable text editing
                                  decoration: InputDecoration(
                                    hintText: selectedDateRange == null
                                        ? 'Pilih Tanggal'
                                        : '${DateFormat.yMMMd().format(selectedDateRange!.start)} - ${DateFormat.yMMMd().format(selectedDateRange!.end)}',
                                    hintStyle: TextStyle(
                                      color: Colors.black54,
                                      fontSize:
                                          13, // Ukuran font yang lebih kecil
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(
                                          right:
                                              8.0), // Space between icon and text
                                      child: Container(
                                        height:
                                            48, // Adjust height for TextField
                                        width:
                                            48, // Adjust width to be circular
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(
                                              0xFFEB8153), // Background color of circle
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors
                                                  .black26, // Shadow color
                                              blurRadius: 4.0, // Blur radius
                                              spreadRadius:
                                                  1.0, // Spread radius
                                              offset: Offset(
                                                  0, 5), // Shadow position
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.calendar_today,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                    filled:
                                        true, // Enables the background color
                                    fillColor: Colors.grey[
                                        200], // Sets the background color to light grey
                                    border: OutlineInputBorder(
                                      borderSide:
                                          BorderSide.none, // Removes the border
                                      borderRadius: BorderRadius.circular(
                                          24.0), // Adds rounded corners
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical:
                                          15, // Vertical padding inside TextField
                                      horizontal:
                                          20, // Horizontal padding for text
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Spacer(), // Mengisi ruang di antara tombol Select Date Range dan tombol Print dan Download

                          // Tombol Print
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircleAvatar(
                              backgroundColor: Color(0xFF51A6F5),
                              child: IconButton(
                                icon: Icon(Icons.print_outlined),
                                color: Colors.white,
                                iconSize: 28,
                                onPressed: () {
                                  // Add your print action here
                                },
                              ),
                            ),
                          ),

                          SizedBox(
                              width:
                                  8), // Space between Print and Download buttons

                          // Tombol Download
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircleAvatar(
                              backgroundColor: Color(0xFF68CF29),
                              child: IconButton(
                                icon: Icon(Icons.arrow_circle_down_sharp),
                                color: Colors.white,
                                iconSize: 28,
                                onPressed: () {
                                  // Add your download action here
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                          height: 16), // Spacing between the rows if needed
                      Expanded(
                        child: LazyLoadScrollView(
                          onEndOfPage: () {
                            if (!isLoading && !isLoadingMore) {
                              _fetchIncomes(currentPage); // Load more incomes
                            }
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.all(0),
                            itemCount: filteredIncomes.length +
                                (isLoadingMore ? 1 : 0),
                            separatorBuilder: (context, index) => Divider(),
                            itemBuilder: (context, index) {
                              // Show loading indicator if it's the last item
                              if (index == filteredIncomes.length) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final Pemasukan pemasukan = filteredIncomes[
                                  index]; // Access filtered income item

                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                leading: CircleAvatar(
                                  backgroundColor: Color(0xFFEB8153),
                                  child: Icon(Icons.monetization_on_outlined,
                                      color: Colors.white70),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pemasukan.name,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMMM yyyy').format(
                                          DateTime.parse(pemasukan.date)),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '+ Rp.' +
                                      NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: '',
                                        decimalDigits: 0,
                                      ).format(
                                          double.tryParse(pemasukan.jumlah) ??
                                              0), // Convert to double
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .green, // Mengubah warna teks menjadi hijau
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailPemasukan(pemasukan: pemasukan),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (isLoading)
            Center(
                child:
                    CircularProgressIndicator()), // Show loading indicator for the entire screen
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahPemasukan(),
            ),
          );

          // Implement the action for adding a new income
        },
        backgroundColor: Color(0xFFE51A6F5),
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose of the controller
    super.dispose();
  }
}
