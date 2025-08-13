import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'all_ticket.dart';
import 'new_ticket.dart';

class TicketDetailsScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  Future<Map<String, dynamic>>? ticketFuture;
  final TextEditingController messageController = TextEditingController();
  List<dynamic> tickets = [];
  int currentTicketIndex = 0;
  String userFirstName = '';
  bool isSending = false;
  Map<int, List<dynamic>> messageAttachments = {};

  // للتعامل مع الملفات المرفقة في الرد الجديد
  List<File> selectedFiles = [];
  final ImagePicker _imagePicker = ImagePicker();
  final FilePicker _filePicker = FilePicker.platform;

  @override
  void initState() {
    log(widget.ticketId.toString());
    super.initState();
    loadUserName();
    ticketFuture = fetchTicketDetails();
    _testReplyAPI();
  }

  Future<void> loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);
      setState(() {
        userFirstName = userData['firstname'] ?? '';
      });
    }
  }

  Future<void> closeTicket(int ticketId) async {
    try {
      setState(() {
        isSending = true;
      });

      var dio = Dio();
      var response = await dio.get(
        'https://ha55a.exchange/api/v1/ticket/change-status.php?ticket_id=$ticketId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const TicketsScreen(initialTabIndex: 0)),
          (route) => false,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('حدث خطأ أثناء إغلاق التذكرة'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء إغلاق التذكرة'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> fetchTicketDetails() async {
    try {
      var dio = Dio();
      var response = await dio.get(
        'https://ha55a.exchange/api/v1/ticket/get-ticket.php?ticket_id=${widget.ticketId}',
      );

      if (response.statusCode == 200 && response.data['ticket'] != null) {
        Map<String, dynamic> ticket =
            Map<String, dynamic>.from(response.data['ticket']);

        // ترتيب الرسائل حسب ID (تصاعدياً)
        if (ticket['messages'] != null &&
            ticket['messages'] is List &&
            ticket['messages'].isNotEmpty) {
          List<dynamic> messages = List<dynamic>.from(ticket['messages']);

          // ترتيب الرسائل تصاعدياً حسب ID
          messages.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

          ticket['messages'] = messages;

          // نسجل طريقة الترتيب للمتابعة
          log('Sorted ${messages.length} messages by ID in ascending order');

          // نحضر المرفقات لكل رسالة
          for (var message in ticket['messages']) {
            if (message != null && message['id'] != null) {
              fetchMessageAttachments(message['id']);
            }
          }
        }

        return ticket;
      } else {
        return {};
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء تحميل التذكرة'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return {};
    }
  }

  Future<void> fetchMessageAttachments(int messageId) async {
    try {
      var data = FormData.fromMap({
        'support_message_id': messageId.toString(),
      });

      var dio = Dio();
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/ticket/get-files.php',
        options: Options(
          method: 'POST',
        ),
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            // تصفية المرفقات وعرض فقط التي تبدأ روابطها بـ http أو https
            var attachments = response.data['attachments'] ?? [];
            List<dynamic> filteredAttachments = [];

            if (attachments is List) {
              for (int i = 0; i < attachments.length; i++) {
                if (attachments[i] is Map &&
                    attachments[i]['attachment'] != null) {
                  String attachment = attachments[i]['attachment'];

                  // إضافة فقط المرفقات التي تبدأ بـ http أو https
                  if (attachment.startsWith('http')) {
                    filteredAttachments.add(attachments[i]);
                    log('Valid attachment URL: $attachment');
                  } else {
                    log('Ignoring invalid attachment URL: $attachment');
                  }
                }
              }
            }

            messageAttachments[messageId] = filteredAttachments;
            log('Fetched ${filteredAttachments.length} valid attachments for message $messageId');
          });
        }
      } else {
        log('Failed to fetch attachments for message $messageId: ${response.statusMessage}');
      }
    } catch (e) {
      log('Error fetching attachments for message $messageId: $e');
    }
  }

  Future<void> _testReplyAPI() async {
    try {
      log('Testing ticket reply API endpoint...');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');
      if (userJson == null) {
        log('No user data found for API test');
        return;
      }

      Map<String, dynamic> userData = jsonDecode(userJson);
      String userId = userData['id']?.toString() ?? "";

      log('Testing endpoint with ticket ID: ${widget.ticketId}, User ID: $userId');

      var dio = Dio();
      dio.interceptors.add(
          LogInterceptor(responseBody: true, requestBody: true, request: true));

      var checkResponse = await dio.get(
        'https://ha55a.exchange/api/v1/ticket/add.php',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      log('API check response: ${checkResponse.statusCode}');
      log('API check body: ${checkResponse.data}');

      log('Checking API documentation...');
      log('Required fields for ticket reply:');
      log('- ticket_id: Integer - ID of the ticket');
      log('- message: String - Message content');
      log('- user_id: Integer - ID of the user sending the message');
    } catch (e) {
      log('Error testing API: $e');
      if (e is DioException) {
        log('DioException type: ${e.type}');
        log('DioException message: ${e.message}');
        if (e.response != null) {
          log('Response status: ${e.response!.statusCode}');
          log('Response data: ${e.response!.data}');
        }
      }
    }
  }

  Future<void> sendMessage() async {
    // Verificar que hay texto - no permitir envío de solo archivos
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء كتابة رسالة قبل الإرسال'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        isSending = true;
      });

      log('Sending message to ticket: ${widget.ticketId}');
      log('Message content: ${messageController.text.trim()}');
      log('Images count: ${selectedFiles.length}');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');
      String userId = "";

      if (userJson != null) {
        Map<String, dynamic> userData = jsonDecode(userJson);
        userId = userData['id']?.toString() ?? "";
        log('User ID for request: $userId');
      } else {
        log('Warning: No user data found in SharedPreferences');
      }

      // 1. Primero enviar el mensaje para obtener message_id
      const String addMessageApiUrl =
          'https://ha55a.exchange/api/v1/ticket/add.php';
      log('Using API URL: $addMessageApiUrl');

      var messageFormData = FormData.fromMap({
        'ticket_id': widget.ticketId.toString(),
        'message': messageController.text.trim(),
        'user_id': userId,
      });

      var dio = Dio();
      dio.interceptors.add(
          LogInterceptor(responseBody: true, requestBody: true, request: true));

      // Envía el mensaje primero sin archivos adjuntos
      var response = await dio.post(
        addMessageApiUrl,
        data: messageFormData,
        options: Options(headers: {
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/json',
        }),
      );

      log('API Response Status: ${response.statusCode}');
      log('API Response Body: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        String messageId = response.data['message_id']?.toString() ?? '';
        log('Message sent successfully, got message_id: $messageId');

        // 2. Si hay imágenes seleccionadas y tenemos message_id, procesarlas
        if (selectedFiles.isNotEmpty && messageId.isNotEmpty) {
          List<Map<String, String>> successfulUploads = [];

          // Registrar el número de imágenes a cargar
          log('Starting upload of ${selectedFiles.length} images');

          for (int i = 0; i < selectedFiles.length; i++) {
            File file = selectedFiles[i];

            try {
              String fileName = path.basename(file.path);

              log('Preparing to upload image: $fileName');

              // Crear FormData para la imagen
              var uploadFormData = FormData.fromMap({
                'image': await MultipartFile.fromFile(
                  file.path,
                  filename: fileName,
                ),
              });

              log('FormData created with field name: image');
              log('Image path: ${file.path}');
              log('Image filename: $fileName');

              // Subir la imagen
              var uploadResponse = await dio.post(
                'https://ha55a.exchange/api/v1/order/upload.php',
                data: uploadFormData,
                options: Options(headers: {
                  'Content-Type': 'multipart/form-data',
                  'Accept': 'application/json',
                }),
              );

              log('Upload response status code: ${uploadResponse.statusCode}');
              log('Upload response data: ${uploadResponse.data}');
              log('Upload response headers: ${uploadResponse.headers}');

              if (uploadResponse.statusCode == 200 &&
                  uploadResponse.data['success'] == true) {
                String fileUrl = uploadResponse.data['url'] ?? '';

                // التأكد من أن الرابط يبدأ بـ http أو https
                if (fileUrl.isNotEmpty && !fileUrl.startsWith('http')) {
                  fileUrl = 'https://${fileUrl.replaceAll(RegExp(r'^/+'), '')}';
                  log('URL modified to ensure it starts with https: $fileUrl');
                }

                if (fileUrl.isNotEmpty) {
                  // Imprimir claramente la URL de la imagen subida
                  log('🖼️ IMAGEN SUBIDA - URL: $fileUrl');

                  // Ahora adjuntar la imagen al mensaje usando add-media.php
                  var attachFormData = FormData.fromMap({
                    'support_message_id': messageId,
                    'attachment': fileUrl,
                  });

                  var attachResponse = await dio.post(
                    'https://ha55a.exchange/api/v1/ticket/add-media.php',
                    data: attachFormData,
                    options: Options(headers: {
                      'Content-Type': 'multipart/form-data',
                      'Accept': 'application/json',
                    }),
                  );

                  log('Attach response for image $i: ${attachResponse.data}');

                  if (attachResponse.statusCode == 200 &&
                      attachResponse.data['success'] == true) {
                    successfulUploads.add({'name': fileName, 'url': fileUrl});
                    log('Successfully attached image: $fileName');
                  } else {
                    log('Failed to attach image $fileName: ${attachResponse.data['message'] ?? "Unknown error"}');
                  }
                }
              } else {
                log('Failed to upload image $fileName: ${uploadResponse.data['message'] ?? "Unknown error"}');
              }
            } catch (uploadError) {
              log('Error uploading image ${i + 1}: $uploadError');
            }
          }

          // Al final del proceso, imprimir un resumen de todas las imágenes subidas
          if (successfulUploads.isNotEmpty) {
            log('📋 RESUMEN DE IMÁGENES SUBIDAS:');
            for (int i = 0; i < successfulUploads.length; i++) {
              log('   ✅ Imagen ${i + 1}: ${successfulUploads[i]['name']} - URL: ${successfulUploads[i]['url']}');
            }
          }

          // Mostrar mensaje de éxito con imágenes adjuntas
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successfulUploads.isEmpty
                    ? 'تم إرسال الرسالة بنجاح'
                    : 'تم إرسال الرسالة وإرفاق ${successfulUploads.length} صور بنجاح'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        } else {
          // Mensaje de éxito sin imágenes adjuntas
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم إرسال الرسالة بنجاح'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        }

        // Limpiar estado después de enviar
        setState(() {
          selectedFiles.clear();
          messageController.clear();
          ticketFuture = fetchTicketDetails(); // Actualizar los mensajes
        });
      } else {
        // Mensaje de error si falla el envío
        log('API returned success=false. Error message: ${response.data['message'] ?? "No error message provided"}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'حدث خطأ أثناء إرسال الرسالة: ${response.data['message'] ?? ""}'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      log('Exception occurred when sending message: $e');
      if (e is DioException) {
        log('DioException details: ${e.response?.data ?? "No response data"}');
        log('DioException status code: ${e.response?.statusCode ?? "No status code"}');
        log('DioException type: ${e.type}');
        log('DioException message: ${e.message}');
        if (e.response != null) {
          log('Response headers: ${e.response!.headers}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال الرسالة: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  // دالة لاختيار الصور من المعرض
  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          selectedFiles.add(File(pickedImage.path));
        });
        log('تم اختيار الصورة: ${pickedImage.path}');

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إضافة الصورة بنجاح'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      log('خطأ في اختيار الصورة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ أثناء اختيار الصورة'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  // Get status color
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.blue.shade700;
      case 'closed':
        return Colors.grey.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'answered':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Get status text
  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return 'مفتوحة';
      case 'closed':
        return 'مغلقة';
      case 'pending':
        return 'قيد الانتظار';
      case 'answered':
        return 'تم الرد';
      default:
        return status ?? 'غير محدد';
    }
  }

  // للحصول على أيقونة الملف
  IconData _getFileIcon(String fileName) {
    String ext = path.extension(fileName).replaceAll('.', '').toLowerCase();

    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            "تفاصيل التذكرة",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: ticketFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/lottie/loading.json',
                      height: 120.h,
                      frameRate: FrameRate.max,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'جاري تحميل التذكرة...',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/images/empty.json',
                      height: 150.h,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "لا توجد تفاصيل للتذكرة",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "قد تكون التذكرة غير موجودة أو محذوفة",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('العودة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5951F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            var ticket = snapshot.data!;
            List<dynamic> messages = ticket['messages'] ?? [];
            final status = ticket['status']?.toString() ?? 'open';

            return CustomScrollView(
              slivers: [
                // Ticket Info Card
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with ticket number and status
                              Row(
                                children: [
                                  // Ticket number
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5951F)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${ticket['id'] ?? ''}',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFF5951F),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Status indicator
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8.w,
                                          height: 8.w,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          _getStatusText(status),
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              // Subject
                              Text(
                                ticket['subject'] ?? 'بدون عنوان',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Date
                              if (ticket['created_at'] != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 12.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        ticket['created_at'] ?? 'غير معروف',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // Action buttons
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          child: Row(
                            children: [
                              _actionButton(
                                "تذاكري",
                                Icons.list_alt_rounded,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const TicketsScreen(
                                                initialTabIndex: 0)),
                                  );
                                },
                              ),
                              SizedBox(width: 8.w),
                              if (ticket['status'].toString().toLowerCase() !=
                                  "closed")
                                _actionButton(
                                  "إغلاق التذكرة",
                                  Icons.close,
                                  () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return _buildCloseTicketDialog(
                                            ticket['id']);
                                      },
                                    );
                                  },
                                  color: Colors.redAccent,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Messages header
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 18.sp,
                              color: Colors.grey.shade700,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "المحادثة",
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5951F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${messages.length}",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF5951F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                ),

                // Messages list
                messages.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48.sp,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                "لا توجد رسائل",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            var message = messages[index];
                            bool isClient = message['sender'] == "client";
                            // تحديد أحدث رسالة استناداً إلى أكبر ID وليس الترتيب في القائمة
                            int maxId = 0;
                            for (var msg in messages) {
                              if (msg['id'] > maxId) {
                                maxId = msg['id'];
                              }
                            }
                            bool isLatest = message['id'] ==
                                maxId; // الرسالة الأحدث هي ذات ID الأكبر

                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 16.w),
                              child: TicketMessageCard(
                                name: isClient ? userFirstName : "الدعم الفني",
                                role: isClient ? "عميل" : "موظف الدعم",
                                message: message['message'],
                                date: message['created_at'],
                                isClient: isClient,
                                isLatest: isLatest,
                                messageId: message['id'],
                                attachments:
                                    messageAttachments[message['id']] ?? [],
                              ),
                            );
                          },
                          childCount: messages.length,
                        ),
                      ),

                // Reply section (solo se muestra si el ticket no está cerrado)
                if (ticket['status'].toString().toLowerCase() != "closed")
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(16.w),
                      margin: EdgeInsets.only(top: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 16.sp,
                                color: Colors.grey.shade700,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "إضافة رد",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                " *",
                                style: TextStyle(
                                    fontSize: 16.sp, color: Colors.red),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          TextField(
                            controller: messageController,
                            maxLines: 3,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              hintText: "اكتب رسالتك هنا...",
                              hintStyle: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: EdgeInsets.all(12.w),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: const Color(0xFFF5951F),
                                  width: 1.w,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.w,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // عرض الملفات المحددة
                          if (selectedFiles.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.w),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.attachment,
                                          size: 16.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          "الصور المرفقة (${selectedFiles.length})",
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        selectedFiles.length > 2 ? 120.h : 70.h,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.w),
                                      itemCount: selectedFiles.length,
                                      itemBuilder: (context, index) {
                                        File file = selectedFiles[index];
                                        String fileName =
                                            path.basename(file.path);
                                        bool isImage = [
                                          '.jpg',
                                          '.jpeg',
                                          '.png',
                                          '.gif',
                                          '.webp'
                                        ].contains(path
                                            .extension(file.path)
                                            .toLowerCase());

                                        return Container(
                                          width: 120.w,
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 4.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  if (isImage)
                                                    Expanded(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: Image.file(
                                                          file,
                                                          fit: BoxFit.cover,
                                                          width:
                                                              double.infinity,
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    Expanded(
                                                      child: Icon(
                                                        _getFileIcon(fileName),
                                                        size: 36.sp,
                                                        color: Colors
                                                            .orange.shade700,
                                                      ),
                                                    ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 6.w,
                                                            vertical: 4.h),
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade50,
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(8),
                                                        bottomRight:
                                                            Radius.circular(8),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      fileName.length > 15
                                                          ? '${fileName.substring(
                                                                  0, 12)}...'
                                                          : fileName,
                                                      style: TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 10.sp,
                                                        color: Colors
                                                            .grey.shade800,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // حذف الملف
                                              Positioned(
                                                top: 4.h,
                                                left: 4.w,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _removeFile(index),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.all(4.w),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.5),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 14.sp,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // أزرار الإرسال وإرفاق الملفات
                          Row(
                            children: [
                              // زر إرفاق صورة
                              Container(
                                height: 45.h,
                                margin: EdgeInsets.only(left: 8.w),
                                child: ElevatedButton(
                                  onPressed: isSending ? null : _pickImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.photo,
                                        size: 20.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "إضافة صورة",
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // زر الإرسال
                              Expanded(
                                child: SizedBox(
                                  height: 45.h,
                                  child: ElevatedButton(
                                    onPressed: isSending ? null : sendMessage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF5951F),
                                      disabledBackgroundColor:
                                          Colors.grey.shade300,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isSending
                                        ? SizedBox(
                                            height: 20.h,
                                            width: 20.h,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.w,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.send,
                                                size: 18.sp,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                "إرسال",
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onPressed,
      {Color color = const Color(0xFFF5951F)}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16.sp,
        color: Colors.white,
      ),
      label: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 10.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildCloseTicketDialog(int ticketId) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              "تأكيد الإغلاق",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        content: Text(
          "هل أنت متأكد أنك تريد إغلاق هذه التذكرة؟",
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.pop(context);
                          closeTicket(ticketId);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    elevation: 0,
                  ),
                  child: isSending
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Text(
                          'إغلاق التذكرة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة لحذف ملف من القائمة
  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }
}

class TicketMessageCard extends StatelessWidget {
  final String name;
  final String role;
  final String message;
  final String date;
  final bool isClient;
  final bool isLatest;
  final int messageId;
  final List<dynamic> attachments;

  const TicketMessageCard({
    super.key,
    required this.name,
    required this.role,
    required this.message,
    required this.date,
    required this.messageId,
    this.isClient = false,
    this.isLatest = false,
    this.attachments = const [],
  });

  // دالة للحصول على امتداد الملف
  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  // دالة للحصول على أيقونة الملف
  IconData _getFileIcon(String fileName) {
    String ext = _getFileExtension(fileName).toLowerCase();

    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isClient
        ? const Color(0xFFF5F5F5)
        : const Color(0xFFF5951F).withOpacity(0.05);

    final borderColor = isClient
        ? Colors.grey.shade300
        : const Color(0xFFF5951F).withOpacity(0.3);

    final textColor = isClient ? Colors.grey.shade800 : Colors.grey.shade900;

    final nameColor = isClient ? Colors.grey.shade800 : const Color(0xFFF5951F);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isLatest ? 1.5 : 1,
        ),
        boxShadow: isLatest
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isLatest
                  ? const Color(0xFFF5951F).withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12.r),
                topLeft: Radius.circular(12.r),
              ),
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: isClient
                        ? Colors.blueGrey.withOpacity(0.2)
                        : const Color(0xFFF5951F).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isClient ? Icons.person : Icons.support_agent,
                      size: 18.sp,
                      color:
                          isClient ? Colors.blueGrey : const Color(0xFFF5951F),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Name and role
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: nameColor,
                      ),
                    ),
                    Text(
                      role,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Date
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        date,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Latest indicator
                if (isLatest) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5951F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "أحدث رد",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF5951F),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Message content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: textColor,
                height: 1.5,
              ),
            ),
          ),

          // Attachments section
          if (attachments.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16.sp,
                        color: Colors.grey.shade700,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        "المرفقات (${attachments.length})",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: attachments.map<Widget>((attachment) {
                      return _buildAttachmentItem(context, attachment);
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(BuildContext context, dynamic attachment) {
    final String fileName = attachment['attachment'] ?? "file";
    final String fileExtension = _getFileExtension(fileName);
    final bool isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .contains(fileExtension.toLowerCase());

    // استخدام الرابط مباشرة بدون إضافة قاعدة URL
    String fileUrl = fileName;

    // التأكد من أن الرابط يبدأ بـ http أو https
    if (!fileUrl.startsWith('http')) {
      if (fileUrl.contains('ha55a.exchange')) {
        fileUrl = 'https://${fileUrl.replaceAll(RegExp(r'^/+'), '')}';
      } else {
        fileUrl = 'https://ha55a.exchange/api/v1/order/uploads/$fileName';
      }
    }

    return InkWell(
      onTap: () {
        _handleAttachmentTap(context, fileUrl, fileName, isImage);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File icon
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isImage ? Colors.blue.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(
                  isImage ? Icons.image : Icons.insert_drive_file,
                  size: 18.sp,
                  color:
                      isImage ? Colors.blue.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // File name
            Container(
              constraints: BoxConstraints(maxWidth: 120.w),
              child: Text(
                // عرض اسم الملف بدون الرابط الكامل
                fileName.contains('/') ? fileName.split('/').last : fileName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.sp,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.w),
            // عرض أيقونة المعاينة بدلاً من التحميل
            Icon(
              Icons.visibility,
              size: 14.sp,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _handleAttachmentTap(
      BuildContext context, String fileUrl, String fileName, bool isImage) {
    // للصور: عرض الصورة في عارض الصور التفاعلي
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isImage)
                  // عارض الصور محسن
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.95,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.network(
                        fileUrl,
                        fit: BoxFit.contain,
                        headers: const {
                          'Accept':
                              'image/jpeg,image/png,image/gif,image/webp,image/*',
                          'Cache-Control': 'max-age=3600',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'جاري تحميل الصورة...',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          log('Error loading image: $error');
                          log('Image URL: $fileUrl');

                          return Container(
                            color: Colors.grey.shade900,
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 48.sp,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'تعذر تحميل الصورة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  fileName,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white70,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // زر إعادة المحاولة
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _handleAttachmentTap(
                                        context, fileUrl, fileName, isImage);
                                  },
                                  icon: Icon(Icons.refresh, size: 18.sp),
                                  label: Text(
                                    'إعادة المحاولة',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  // عرض معلومات الملف للملفات الأخرى
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // أيقونة نوع الملف
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _getFileIcon(fileName),
                              size: 40.sp,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // اسم الملف
                        Text(
                          fileName,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        // نوع الملف
                        Text(
                          'نوع الملف: ${_getFileExtension(fileName).toUpperCase()}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // رابط الملف
                        InkWell(
                          onTap: () {
                            // هنا يمكن فتح الملف في متصفح خارجي
                            // لأسباب أمنية، لا يمكن عرض بعض أنواع الملفات مباشرة
                            // launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.h, horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 18.sp,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'رابط الملف',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // زر الإغلاق
                Positioned(
                  top: 24.h,
                  right: 24.w,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                // زر المعاينة في متصفح خارجي (للملفات غير الصور فقط)
                if (!isImage)
                  Positioned(
                    bottom: 24.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // فتح الملف في متصفح خارجي
                        // يمكن استخدام url_launcher هنا
                        // launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('جاري فتح الملف: $fileName'),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.visibility,
                        size: 18.sp,
                      ),
                      label: Text(
                        'معاينة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5951F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
