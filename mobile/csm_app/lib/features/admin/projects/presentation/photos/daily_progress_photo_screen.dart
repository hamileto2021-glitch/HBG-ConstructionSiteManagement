import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/daily_progress_photo.dart';
import '../../data/repositories/daily_progress_photo_repository.dart';



class DailyProgressPhotoScreen extends StatefulWidget {
  const DailyProgressPhotoScreen({
    super.key,
    required this.diaryId,
  });

  final String diaryId;

  @override
  State<DailyProgressPhotoScreen> createState() =>
      _DailyProgressPhotoScreenState();
}

class _DailyProgressPhotoScreenState
    extends State<DailyProgressPhotoScreen> {
  final _repository = DailyProgressPhotoRepository();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;

  List<DailyProgressPhoto> _photos = [];
  final Map<String, Future<Uint8List>> _photoContent = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _loading = true);

    try {
      final result =
      await _repository.getByDiary(widget.diaryId);

      if (!mounted) return;

      setState(() {
        _photos = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  Future<void> _deletePhoto(DailyProgressPhoto photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text(
          'This photo will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _repository.delete(photo.id);
    await _loadPhotos();
  }
  Future<void> _openPhoto(DailyProgressPhoto photo) async {
    late final Uint8List bytes;
    try {
      bytes = await _loadPhotoContent(photo);
    } catch (_) {
      _photoContent.remove(photo.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load this photo.')),
        );
      }
      return;
    }
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Hero(
              tag: photo.id,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image == null) return;
    if (!mounted) return;

    final captionController = TextEditingController();

    final caption = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Photo Caption'),
        content: TextField(
          controller: captionController,
          decoration: const InputDecoration(
            hintText: 'Optional caption',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              captionController.text,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    setState(() => _uploading = true);

    try {
      await _repository.upload(
        diaryId: widget.diaryId,
        image: File(image.path),
        caption: caption,
      );

      await _loadPhotos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo uploaded successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _loadPhotoContent(DailyProgressPhoto photo) {
    return _photoContent.putIfAbsent(
      photo.id,
      () => _repository.getContent(photo.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _showOptions,
        child: _uploading
            ? const CircularProgressIndicator(
          color: Colors.white,
        )
            : const Icon(Icons.add_a_photo),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _photos.isEmpty
          ? const Center(
        child: Text(
          'No progress photos uploaded.',
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];

          return GestureDetector(
            onLongPress: () => _deletePhoto(photo),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openPhoto(photo),
                      child: Hero(
                        tag: photo.id,
                        child: FutureBuilder<Uint8List>(
                          future: _loadPhotoContent(photo),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Icon(
                                Icons.broken_image,
                                size: 48,
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return Image.memory(
                              snapshot.data!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      photo.caption ?? photo.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}