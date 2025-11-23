import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  static ImageService get instance => _instance;

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({
    required ImageSource source,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Save profile image to app directory
  Future<String?> saveProfileImage(File imageFile, String userId) async {
    try {
      // Get the app's document directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory profileImagesDir = Directory('${appDir.path}/profile_images');
      
      // Create the directory if it doesn't exist
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      // Generate a unique filename
      final String fileExtension = path.extension(imageFile.path);
      final String fileName = '${userId}_profile$fileExtension';
      final String filePath = '${profileImagesDir.path}/$fileName';

      // Copy the image to the app directory
      final File savedImage = await imageFile.copy(filePath);
      
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving profile image: $e');
      return null;
    }
  }

  /// Delete profile image
  Future<bool> deleteProfileImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      return false;
    }
  }

  /// Get profile image file
  File? getProfileImageFile(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    final File imageFile = File(imagePath);
    return imageFile.existsSync() ? imageFile : null;
  }

  /// Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Pick and save profile image with user interaction
  Future<String?> pickAndSaveProfileImage(
    BuildContext context, 
    String userId, {
    String? currentImagePath,
  }) async {
    try {
      // Show source selection dialog
      final ImageSource? source = await showImageSourceDialog(context);
      if (source == null) return null;

      // Pick image
      final File? pickedImage = await pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedImage == null) return null;

      // Delete old image if exists
      if (currentImagePath != null && currentImagePath.isNotEmpty) {
        await deleteProfileImage(currentImagePath);
      }

      // Save new image
      final String? savedImagePath = await saveProfileImage(pickedImage, userId);
      
      if (savedImagePath != null) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      return savedImagePath;
    } catch (e) {
      debugPrint('Error in pickAndSaveProfileImage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile image'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}