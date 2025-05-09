import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketAttachments extends StatefulWidget {
  final String messageId;

  const TicketAttachments({
    Key? key,
    required this.messageId,
  }) : super(key: key);

  @override
  State<TicketAttachments> createState() => _TicketAttachmentsState();
}

class _TicketAttachmentsState extends State<TicketAttachments> {
  List<Map<String, dynamic>> attachments = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  @override
  void didUpdateWidget(TicketAttachments oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload attachments if the message ID changes
    if (oldWidget.messageId != widget.messageId) {
      _loadAttachments();
    }
  }

  Future<void> _loadAttachments() async {
    if (widget.messageId.isEmpty) {
      setState(() {
        isLoading = false;
        attachments = [];
      });
      print("⚠️ messageId vazio, não será feita requisição para get-files.php");
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      var dio = Dio();
      final Map<String, dynamic> requestParams = {
        'support_message_id': widget.messageId,
      };

      print("📤 ENVIANDO REQUISIÇÃO PARA get-files.php:");
      print("📤 URL: https://ha55a.exchange/api/v1/ticket/get-files.php");
      print("📤 PARÂMETROS: $requestParams");

      final response = await dio.get(
        'https://ha55a.exchange/api/v1/ticket/get-files.php',
        queryParameters: requestParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      print("📥 RESPOSTA RECEBIDA DE get-files.php:");
      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 HEADERS: ${response.headers}");
      print("📥 DATA: ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rawAttachments = response.data['attachments'] ?? [];
        print("📥 ANEXOS RECEBIDOS: ${rawAttachments.length}");

        setState(() {
          attachments = rawAttachments
              .map((item) => item as Map<String, dynamic>)
              .toList();
          isLoading = false;
        });

        if (attachments.isNotEmpty) {
          print("📥 DETALHES DO PRIMEIRO ANEXO: ${attachments.first}");
        }
      } else {
        print("⚠️ ERRO NA RESPOSTA: ${response.data}");
        setState(() {
          isLoading = false;
          error = "فشل في تحميل المرفقات";
        });
      }
    } catch (e) {
      print("❌ ERRO AO CARREGAR ANEXOS: $e");
      if (e is DioException && e.response != null) {
        print("❌ ERRO RESPONSE DATA: ${e.response?.data}");
        print("❌ ERRO STATUS CODE: ${e.response?.statusCode}");
      }
      setState(() {
        isLoading = false;
        error = "خطأ أثناء تحميل المرفقات";
      });
    }
  }

  String _getFileExtension(String url) {
    if (url.isEmpty) return '';
    return url.split('.').last.toLowerCase();
  }

  IconData _getFileIcon(String url) {
    final extension = _getFileExtension(url);

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

  bool _isImageFile(String url) {
    final extension = _getFileExtension(url);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  void _showAttachment(String url) {
    if (_isImageFile(url)) {
      _showImageDialog(url);
    } else {
      _openUrl(url);
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن فتح الملف: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          error!,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.red,
            fontSize: 12.sp,
          ),
        ),
      );
    }

    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "المرفقات",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF666666),
            ),
          ),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: attachments.map((attachment) {
              final String url = attachment['attachment'] ?? '';
              final String fileName = url.split('/').last;
              final bool isImage = _isImageFile(url);

              return GestureDetector(
                onTap: () => _showAttachment(url),
                child: Container(
                  width: 80.w,
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: SizedBox(
                            height: 50.h,
                            width: 70.w,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  height: 15,
                                  width: 15,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.error,
                                color: Colors.red[300],
                              ),
                            ),
                          ),
                        )
                      else
                        Icon(
                          _getFileIcon(url),
                          size: 36.sp,
                          color: const Color(0xFF888888),
                        ),
                      SizedBox(height: 4.h),
                      Text(
                        fileName.length > 10
                            ? '${fileName.substring(0, 8)}...'
                            : fileName,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.sp,
                          overflow: TextOverflow.ellipsis,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
