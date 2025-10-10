import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thực hành 02',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto', // Đảm bảo sử dụng font hỗ trợ Unicode
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  List<int> _numberList = [];
  String? _errorMessage;

  void _createNumberList() {
    setState(() {
      _errorMessage = null;

      // Kiểm tra input có rỗng không
      if (_textController.text.trim().isEmpty) {
        _errorMessage = "Dữ liệu bạn nhập không hợp lệ";
        _numberList = []; // Xóa danh sách số khi có lỗi
        return;
      }

      // Thử parse thành số
      int? number = int.tryParse(_textController.text.trim());

      if (number == null || number <= 0) {
        _errorMessage = "Dữ liệu bạn nhập không hợp lệ";
        _numberList = []; // Xóa danh sách số khi có lỗi
        return;
      }

      // Tạo danh sách số từ 1 đến number
      _numberList = List.generate(number, (index) => index + 1);
    });
  }

  void _navigateToEmailCheck() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailCheckScreen()),
    );
  }

  void _navigateToCheckInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Thực hành 02',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          // Hai nút ở góc trên
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Nút Check Email ở góc trái
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _navigateToEmailCheck,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Check Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Nút Check Info ở góc phải
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _navigateToCheckInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Check Info',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Phần giữa màn hình - khung nhập số
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text field để nhập số
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _textController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (value) {
                              // Khi nhấn Enter, tự động gọi hàm tạo danh sách
                              _createNumberList();
                            },
                            decoration: const InputDecoration(
                              hintText: 'Nhập vào số lượng (nhấn Enter để tạo)',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Nút Tạo
                      ElevatedButton(
                        onPressed: _createNumberList,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Tạo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hiển thị thông báo lỗi nếu có
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Danh sách các nút số
                  Expanded(
                    child: ListView.builder(
                      itemCount: _numberList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // Có thể thêm logic xử lý khi nhấn nút
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Bạn đã nhấn nút ${_numberList[index]}',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                '${_numberList[index]}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

// Màn hình kiểm tra thông tin
class CheckInfoScreen extends StatefulWidget {
  const CheckInfoScreen({super.key});

  @override
  State<CheckInfoScreen> createState() => _CheckInfoScreenState();
}

class _CheckInfoScreenState extends State<CheckInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _result;

  void _checkInfo() {
    setState(() {
      _result = null;

      String name = _nameController.text.trim();
      String ageText = _ageController.text.trim();

      // Kiểm tra các trường có rỗng không
      if (name.isEmpty || ageText.isEmpty) {
        _result = "Vui lòng nhập đầy đủ thông tin";
        return;
      }

      // Thử parse tuổi thành số
      int? age = int.tryParse(ageText);

      if (age == null || age < 0) {
        _result = "Tuổi phải là số nguyên dương";
        return;
      }

      // Phân loại theo tuổi
      String category;
      if (age > 65) {
        category = "Người già (>65)";
      } else if (age >= 6 && age <= 65) {
        category = "Người lớn (6-65)";
      } else if (age >= 2 && age <= 6) {
        category = "Trẻ em (2-6)";
      } else {
        category = "Em bé (≤2)";
      }

      _result = "Họ và tên: $name\nTuổi: $age\nPhân loại: $category";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'THỰC HÀNH 01',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Container với background xám chứa form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // Row cho Họ và tên
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text(
                            'Họ và tên',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.next,
                              // Bỏ inputFormatters để cho phép nhập đầy đủ tiếng Việt
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Roboto',
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                hintText: 'Nhập họ và tên',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Row cho Tuổi
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text(
                            'Tuổi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Roboto',
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                hintText: 'Nhập tuổi',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Nút Kiểm tra
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _checkInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Kiểm tra',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Hiển thị kết quả
              if (_result != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        _result!.contains("Vui lòng") ||
                            _result!.contains("Tuổi phải")
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          _result!.contains("Vui lòng") ||
                              _result!.contains("Tuổi phải")
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    _result!,
                    style: TextStyle(
                      color:
                          _result!.contains("Vui lòng") ||
                              _result!.contains("Tuổi phải")
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto', // Đảm bảo font hỗ trợ Unicode
                      height: 1.4, // Tăng line height cho dễ đọc
                    ),
                    textAlign: TextAlign.center,
                    // Đảm bảo encoding UTF-8
                    textDirection: TextDirection.ltr,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}

// Màn hình kiểm tra email
class EmailCheckScreen extends StatefulWidget {
  const EmailCheckScreen({super.key});

  @override
  State<EmailCheckScreen> createState() => _EmailCheckScreenState();
}

class _EmailCheckScreenState extends State<EmailCheckScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;

  void _checkEmail() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;

      String email = _emailController.text.trim();

      // Kiểm tra email có rỗng không
      if (email.isEmpty) {
        _errorMessage = "Email không hợp lệ";
        return;
      }

      // Kiểm tra email có chứa @ không
      if (!email.contains('@')) {
        _errorMessage = "Email không đúng định dạng";
        return;
      }

      // Validation đơn giản cho email
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        _errorMessage = "Email không đúng định dạng";
        return;
      }

      // Email hợp lệ
      _successMessage = "Bạn đã nhập email hợp lệ";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Thực hành 02',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text field để nhập email
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Hiển thị thông báo lỗi nếu có
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              // Hiển thị thông báo thành công nếu có
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _successMessage!,
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              // Nút Kiểm tra
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _checkEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Kiểm tra',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
