import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/service/api_service.dart'; // Import API service
import 'package:pity_cash/view/pemasukan/detail_pemasukan.dart';
import 'package:pity_cash/view/pemasukan/tambah_pemasukan.dart';
import 'package:pity_cash/view/pengeluaran/detail_pengeluaran.dart';
import 'package:pity_cash/view/pengeluaran/tambah_pengeluaran.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengeluaranSection extends StatefulWidget {
  @override
  _PengeluaranSectionState createState() => _PengeluaranSectionState();
}

class _PengeluaranSectionState extends State<PengeluaranSection> {
  List<Pengeluaran> expenses = []; // Updated to use Pengeluaran
  List<Pengeluaran> filteredExpenses = [];
  Map<int, List<Pengeluaran>> groupedFilteredExpenses = {};
// Updated to use Pengeluaran

  // Other variables remain unchanged
  bool isOutcomeSelected = true;
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
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchExpenses(currentPage); // Ambil data awal
    _searchController
        .addListener(_filterExpenses); // Dengarkan perubahan di search field
  }

  Future<void> _checkLoginStatus() async {
    token = await _prefsService.getToken();
    name = await _prefsService.getUserName();
    setState(() {
      isLoggedIn = token != null;
    });
  }

  Future<void> _fetchExpenses(int page) async {
    if (isLoadingMore) return; // Prevent fetching if already loading more data

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      // Add debug print to verify the API call
      print('Fetching expenses for page: $page');
      final fetchedExpenses = await _apiService.fetchExpenses(page: page);

      // Debug print the response from the API
      print('Fetched expenses: ${fetchedExpenses.toString()}');

      setState(() {
        if (page == 1) {
          expenses = fetchedExpenses; // Replace list for first page
        } else {
          expenses.addAll(fetchedExpenses); // Append for subsequent pages
        }
        currentPage++; // Increment current page for pagination
        _filterExpenses(); // Update filtered expenses after fetching
      });
    } catch (e) {
      print('Error fetching expenses: $e'); // Log error message
      _showErrorSnackbar('Error fetching expenses. Please try again.');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
        isLoadingMore = false; // Reset loadingMore state
      });
    }
  }

  void _filterExpenses() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      // Jika query kosong, tampilkan semua pengeluaran
      if (query.isEmpty) {
        filteredExpenses = List.from(expenses); // Tampilkan semua pengeluaran
      } else {
        // Filter pengeluaran berdasarkan nama atau tanggal
        filteredExpenses = expenses.where((pengeluaran) {
          bool matchesName = pengeluaran.name.toLowerCase().contains(query);
          bool matchesDate = DateFormat('dd MMMM yyyy')
              .format(pengeluaran.createdAt)
              .toLowerCase()
              .contains(query);

          return matchesName ||
              matchesDate; // Kembalikan true jika salah satu cocok
        }).toList();
      }

      // Kelompokkan filtered expenses setelah memfilter
      groupedFilteredExpenses = {};
      for (var pengeluaran in filteredExpenses) {
        int parentId =
            pengeluaran.idParent; // Gunakan default jika idParent null
        if (!groupedFilteredExpenses.containsKey(parentId)) {
          groupedFilteredExpenses[parentId] = [];
        }
        groupedFilteredExpenses[parentId]!.add(pengeluaran);
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSectionClick(bool isOutcome) {
    setState(() {
      isOutcomeSelected = isOutcome;
      if (isOutcome) {
        currentPage = 1; // Reset current page for expenses
        expenses.clear(); // Clear current expense list
        _fetchExpenses(currentPage); // Fetch expenses again
      } else {
        // Implement income fetching if needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<int, List<Pengeluaran>> groupedExpenses = {};
    for (var expense in expenses) {
      if (!groupedExpenses.containsKey(expense.idParent)) {
        groupedExpenses[expense.idParent] = [];
      }
      groupedExpenses[expense.idParent]!.add(expense);
    }
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
                        child: Text(
                          isLoggedIn ? '\Rp 90.000,00' : '\Rp 0,00',
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
                                onTap: () => _handleSectionClick(false),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color:
                                        !isOutcomeSelected // ! karena Income adalah kebalikan dari Expense
                                            ? Color(
                                                0xFFEB8153) // Warna oranye untuk Income jika dipilih
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Income',
                                      style: TextStyle(
                                        color: !isOutcomeSelected
                                            ? Colors.white
                                            : Color(
                                                0xFFB8B8B8), // Warna teks abu-abu jika tidak dipilih
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
                                onTap: () => _handleSectionClick(true),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color:
                                        isOutcomeSelected // Menampilkan warna oranye saat Expense dipilih
                                            ? Color(0xFFEB8153)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Outcome',
                                      style: TextStyle(
                                        color: isOutcomeSelected
                                            ? Colors.white
                                            : Color(
                                                0xFFB8B8B8), // Warna teks abu-abu jika tidak dipilih
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
                      // Panggil fungsi pencarian setiap kali nilai berubah
                      _filterExpenses();
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
                          SizedBox(width: 8),
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
                      Expanded(
                        child: LazyLoadScrollView(
                          onEndOfPage: () {
                            if (!isLoading && !isLoadingMore) {
                              _fetchExpenses(currentPage); // Load more expenses
                            }
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: groupedFilteredExpenses.length,
                            itemBuilder: (context, groupIndex) {
                              int parentId = groupedFilteredExpenses.keys
                                  .elementAt(groupIndex);
                              List<Pengeluaran> groupItems =
                                  groupedFilteredExpenses[parentId]!;
                              double totalJumlah = groupItems.fold(
                                  0, (sum, item) => sum + item.jumlah);

                              return GestureDetector(
                                onTap: () {
                                  if (groupItems.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailPengeluaran(
                                          pengeluaranList:
                                              groupItems, // Pass the entire groupItems list
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8.0),
                                      // Display date
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            groupItems.isNotEmpty
                                                ? DateFormat('dd MMMM yyyy')
                                                    .format(groupItems
                                                        .first.createdAt)
                                                : 'Tidak ada tanggal',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color: Colors.grey[400],
                                        thickness: 1,
                                        height: 15,
                                      ),
                                      // Display all expenses in this group
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: groupItems.length,
                                        itemBuilder: (context, transIndex) {
                                          final pengeluaran =
                                              groupItems[transIndex];
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      Color(0xFFEB8153),
                                                  child: Icon(
                                                    Icons
                                                        .monetization_on_outlined,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                SizedBox(width: 16.0),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        pengeluaran
                                                                .name.isNotEmpty
                                                            ? pengeluaran.name
                                                            : 'Tidak ada nama',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        pengeluaran.category
                                                                ?.name ??
                                                            'Tidak ada kategori',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  NumberFormat.currency(
                                                    locale: 'id_ID',
                                                    symbol: 'Rp ',
                                                    decimalDigits: 0,
                                                  ).format(pengeluaran.jumlah),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 8.0),
                                      Divider(
                                        color: Colors.grey[400],
                                        thickness: 1,
                                        height: 15,
                                      ),
                                      // Display the total amount
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total: ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            NumberFormat.currency(
                                              locale: 'id_ID',
                                              symbol: 'Rp ',
                                              decimalDigits: 0,
                                            ).format(totalJumlah),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                          height:
                                              20.0), // Add space between groups
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
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
              builder: (context) => TambahPengeluaran(),
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
