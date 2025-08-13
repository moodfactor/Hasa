import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:showcaseview/showcaseview.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});
  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? selectedPriority;
  String? userId;
  String? fullName;
  List<Map<String, dynamic>> attachments = [];
  bool _isSubmitting = false;
  final FocusNode _subjectFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();
  final FocusNode _priorityFocus = FocusNode();
  final GlobalKey _fileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _subjectFocus.addListener(() => setState(() {}));
    _messageFocus.addListener(() => setState(() {}));
    _priorityFocus.addListener(() => setState(() {}));
    _checkFirstTimeUser();
  }

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    nameController.dispose();
    emailController.dispose();
    _subjectFocus.dispose();
    _messageFocus.dispose();
    _priorityFocus.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase = prefs.getBool('hasSeenShowcase') ?? false;
    if (!hasSeenShowcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([_fileKey]);
      });
      await prefs.setBool('hasSeenShowcase', true);
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);
      setState(() {
        userId = userData['id']?.toString();
        nameController.text = userData['firstname'] ?? "";
        fullName =
            "${userData['firstname'] ?? ''} ${userData['secondname'] ?? ''} ${userData['lastname'] ?? ''}"
                .trim();
        emailController.text = userData['email'] ?? "غير معروف";
      });
    }
  }

  Future<void> submitTicket() async {
    if (subjectController.text.isEmpty ||
        messageController.text.isEmpty ||
        selectedPriority == null) {
      _showSnackBar("يرجى ملء جميع الحقول المطلوبة", isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    int priorityValue = _getPriorityValue(selectedPriority!);

    // Count valid attachments
    final validAttachments = attachments
        .where((a) => a['uploaded'] == true && a['url'] != null)
        .toList();
    final hasAttachments = validAttachments.isNotEmpty;

    try {
      var data = FormData.fromMap({
        "user_id": userId,
        "name": fullName,
        "subject": subjectController.text.trim(),
        "message": messageController.text.trim(),
        "priority": priorityValue.toString(),
      });

      var dio = Dio();
      print("Submitting ticket...");
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/ticket/add-ticket.php',
        data: data,
      );

      print("Ticket submission response: ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Get the message_id from the response for attachment uploads
        final String messageId = response.data['message_id']?.toString() ?? '';
        print("Received message_id: $messageId");

        // If we have valid message_id and attachments, send them to add-media.php
        if (messageId.isNotEmpty && hasAttachments) {
          await _sendAttachmentsToTicket(messageId);

          // Success message including attachment info
          _showSnackBar(
              hasAttachments
                  ? "تم إنشاء التذكرة وإرفاق ${validAttachments.length} ملفات بنجاح"
                  : "تم إنشاء التذكرة بنجاح",
              isSuccess: true);
        } else {
          // Standard success message without attachments
          _showSnackBar("تم إنشاء التذكرة بنجاح", isSuccess: true);
        }

        _clearForm();
      } else {
        _showSnackBar("فشل في إنشاء التذكرة", isError: true);
      }
    } catch (e) {
      print("Error submitting ticket: $e");
      _showSnackBar("خطأ أثناء الاتصال بالشبكة", isError: true);
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  // Modified _sendAttachmentsToTicket with better logging
  Future<void> _sendAttachmentsToTicket(String messageId) async {
    // Filter only successfully uploaded attachments
    final uploadedAttachments = attachments
        .where((a) => a['uploaded'] == true && a['url'] != null)
        .toList();

    print(
        "Sending ${uploadedAttachments.length} attachments to ticket with message_id: $messageId");

    if (uploadedAttachments.isEmpty || messageId.isEmpty) {
      print("No attachments to send or invalid message_id");
      return;
    }

    try {
      var dio = Dio();

      for (var attachment in uploadedAttachments) {
        print(
            "Adding attachment to ticket: ${attachment['name']} (URL: ${attachment['url']})");

        // Prepare the data to send
        Map<String, dynamic> requestData = {
          'support_message_id': messageId,
          'attachment': attachment['url'],
        };

        print("REQUEST DATA to add-media.php: $requestData");

        var attachmentData = FormData.fromMap(requestData);

        var response = await dio.post(
          'https://ha55a.exchange/api/v1/ticket/add-media.php',
          data: attachmentData,
        );

        print("RESPONSE from add-media.php: ${response.data}");
        print("RESPONSE STATUS CODE: ${response.statusCode}");
        print("RESPONSE HEADERS: ${response.headers}");
      }

      print("All attachments have been sent to the ticket");
    } catch (e) {
      print("Error attaching files to ticket: $e");
      if (e is DioException && e.response != null) {
        print("Error response data: ${e.response?.data}");
        print("Error status code: ${e.response?.statusCode}");
      }
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor = isError
        ? const Color(0xFFE53935)
        : (isSuccess ? const Color(0xFF43A047) : const Color(0xFF323232));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error
                  : (isSuccess ? Icons.check_circle : Icons.info),
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _clearForm() {
    subjectController.clear();
    messageController.clear();
    setState(() {
      selectedPriority = null;
      attachments = [];
    });
  }

  Future<void> pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        String? filePath = file.path;
        if (filePath != null) {
          print("Selected file: ${file.name} (path: $filePath)");

          setState(() {
            attachments.add({
              'name': file.name,
              'path': filePath,
              'uploading': true,
              'uploaded': false,
              'url': null,
            });
          });

          try {
            FormData data = FormData.fromMap({
              'image':
                  await MultipartFile.fromFile(filePath, filename: file.name)
            });

            var dio = Dio();
            print("Uploading file ${file.name} to server...");

            var response = await dio.post(
              'https://ha55a.exchange/api/v1/order/upload.php',
              data: data,
            );

            print("Upload response for ${file.name}: ${response.data}");

            if (response.statusCode == 200 &&
                response.data['success'] == true) {
              setState(() {
                int index =
                    attachments.indexWhere((a) => a['path'] == filePath);
                if (index != -1) {
                  attachments[index]['uploading'] = false;
                  attachments[index]['uploaded'] = true;
                  attachments[index]['url'] = response.data['url'];
                  print(
                      "File uploaded successfully. URL: ${response.data['url']}");
                }
              });
            } else {
              setState(() {
                int index =
                    attachments.indexWhere((a) => a['path'] == filePath);
                if (index != -1) {
                  attachments[index]['uploading'] = false;
                  attachments[index]['error'] = true;
                  print("Upload failed with response: ${response.data}");
                }
              });
            }
          } catch (e) {
            setState(() {
              int index = attachments.indexWhere((a) => a['path'] == filePath);
              if (index != -1) {
                attachments[index]['uploading'] = false;
                attachments[index]['error'] = true;
                print("Upload error: $e");
              }
            });
          }
        }
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      attachments.removeAt(index);
    });
  }

  int _getPriorityValue(String priority) {
    switch (priority) {
      case "عالي":
        return 3;
      case "متوسط":
        return 2;
      case "منخفض":
        return 1;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Text(
                  "إنشاء تذكرة جديدة",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "يمكنك طلب المساعدة أو الاستفسار عن أي شيء",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 30.h),

                // Ticket details section
                Text(
                  "تفاصيل التذكرة",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 15.h),

                // Subject & Priority
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: subjectController,
                        label: "الموضوع *",
                        hint: "عنوان التذكرة",
                        icon: Icons.title,
                        focusNode: _subjectFocus,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      flex: 2,
                      child: _buildDropdownField(
                        label: "الأولوية *",
                        hint: "اختر الأولوية",
                        icon: Icons.flag,
                        focusNode: _priorityFocus,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Message
                _buildTextField(
                  controller: messageController,
                  label: "الرسالة *",
                  hint: "اكتب تفاصيل المشكلة أو الاستفسار",
                  icon: Icons.message,
                  maxLines: 6,
                  focusNode: _messageFocus,
                ),
                SizedBox(height: 25.h),

                // Attachments section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "المرفقات",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // File picker button
                    GestureDetector(
                      onTap: pickAndUploadFile,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Showcase(
                              key: _fileKey,
                              description: 'اضغط هنا لإرفاق الملفات والصور',
                              descTextStyle: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              child: const Icon(
                                Icons.attach_file,
                                color: Color(0xFFF5951F),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'إرفاق ملفات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Attachment list
                    if (attachments.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 15.h),
                        child: Column(
                          children: [
                            for (int i = 0; i < attachments.length; i++)
                              _buildAttachmentItem(i),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 40.h),

                // Submit button
                _buildSubmitButton(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
    FocusNode? focusNode,
  }) {
    bool hasFocus = focusNode != null && focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF555555),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFFF5951F).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: const Color(0xFFAAAAAA),
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: hasFocus
                    ? const Color(0xFFF5951F)
                    : const Color(0xFF888888),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasFocus
                      ? const Color(0xFFF5951F)
                      : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFF5951F),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
  }) {
    bool hasFocus = focusNode != null && focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF555555),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFFF5951F).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButtonFormField<String>(
              value: selectedPriority,
              focusNode: focusNode,
              isExpanded: true,
              menuMaxHeight: 200,
              alignment: AlignmentDirectional.centerEnd,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: const Color(0xFFAAAAAA),
                ),
                prefixIcon: Icon(
                  icon,
                  size: 20,
                  color: hasFocus
                      ? const Color(0xFFF5951F)
                      : const Color(0xFF888888),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasFocus
                        ? const Color(0xFFF5951F)
                        : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFF5951F),
                    width: 1.5,
                  ),
                ),
              ),
              items: [
                _buildDropdownMenuItem("عالي", const Color(0xFFE53935)),
                _buildDropdownMenuItem("متوسط", const Color(0xFFFFA000)),
                _buildDropdownMenuItem("منخفض", const Color(0xFF43A047)),
              ],
              onChanged: (value) => setState(() => selectedPriority = value),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF888888)),
              dropdownColor: Colors.white,
              itemHeight: 50,
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildDropdownMenuItem(String text, Color dotColor) {
    return DropdownMenuItem<String>(
      value: text,
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(int index) {
    final attachment = attachments[index];
    final bool isUploading = attachment['uploading'] == true;
    final bool hasError = attachment['error'] == true;
    final bool isUploaded = attachment['uploaded'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFFFF5F5)
            : isUploaded
                ? const Color(
                    0xFFF2F8F2) // Light green background for uploaded files
                : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError
              ? const Color(0xFFFFCDD2)
              : isUploaded
                  ? const Color(0xFFBEE3BE) // Green border for uploaded files
                  : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          // File icon based on extension
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUploaded
                  ? const Color(0xFFE8F5E9) // Light green for uploaded files
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileIcon(attachment['name']),
              size: 20,
              color: isUploaded
                  ? const Color(0xFF4CAF50) // Green icon for uploaded files
                  : const Color(0xFF888888),
            ),
          ),
          const SizedBox(width: 12),

          // File name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment['name'],
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isUploading || hasError || isUploaded)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      hasError
                          ? "فشل الرفع"
                          : isUploading
                              ? "جاري الرفع..."
                              : "تم الرفع بنجاح", // Success message for uploaded files
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        color: hasError
                            ? const Color(0xFFE53935)
                            : isUploaded
                                ? const Color(
                                    0xFF4CAF50) // Green text for uploaded files
                                : const Color(0xFF888888),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Status indicator or delete button
          if (isUploading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF5951F)),
              ),
            )
          else if (isUploaded)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 20,
            )
          else
            IconButton(
              onPressed: () => _removeAttachment(index),
              icon: Icon(
                Icons.close,
                size: 20,
                color: hasError
                    ? const Color(0xFFE53935)
                    : const Color(0xFF888888),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFF5951F), Color(0xFFFF8F00)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5951F).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : submitTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "جاري الإرسال...",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, color: Colors.white),
                  SizedBox(width: 10.w),
                  Text(
                    "إرسال التذكرة",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
